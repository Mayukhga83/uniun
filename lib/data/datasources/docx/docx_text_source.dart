import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:injectable/injectable.dart';
import 'package:xml/xml.dart';

/// One heading-started stretch of a Word document: [label] is the heading's
/// text, `''` for anything above the first heading.
typedef DocxSection = ({String label, String text});

/// Refuse a `word/document.xml` over this uncompressed. These files arrive
/// from other users over relays, so a zip bomb is a real input — and the parsed
/// DOM costs ~10x the XML (measured), shared with the app's heap because
/// [Isolate.run] stays in its isolate group. 10 MB is a several-hundred-page
/// text document; typical files are well under 1 MB.
const int kMaxDocxXmlBytes = 10 * 1024 * 1024;

/// The same guard for `word/styles.xml`, which is normally tens of KB.
const int kMaxDocxStylesBytes = 2 * 1024 * 1024;

const int _maxLabelChars = 100;
const String _w =
    'http://schemas.openxmlformats.org/wordprocessingml/2006/main';

/// Seam over the DOCX reader, so callers can be tested without real files.
abstract class DocxTextSource {
  /// Sections in reading order, or `null` when the file cannot be read as a
  /// Word document.
  Future<List<DocxSection>?> sectionsText(String path);
}

/// Reads `word/document.xml` straight out of the zip.
///
/// Parsing runs in [Isolate.run]: unlike PDFium's async FFI, XML parsing is
/// synchronous Dart and would stall the UI on a large document.
@LazySingleton(as: DocxTextSource)
class ArchiveDocxTextSource implements DocxTextSource {
  @override
  Future<List<DocxSection>?> sectionsText(String path) async {
    try {
      return await Isolate.run(() => _parse(File(path).readAsBytesSync()));
    } catch (_) {
      return null;
    }
  }
}

List<DocxSection>? _parse(List<int> bytes) {
  final zip = ZipDecoder().decodeBytes(bytes);
  final doc = zip.findFile('word/document.xml');
  // The declared size stops an honest bomb before inflating anything; a header
  // that lies is only caught after inflation, at the cost of the memory spent.
  if (doc == null || doc.size > kMaxDocxXmlBytes) return null;
  final raw = doc.readBytes();
  if (raw == null || raw.length > kMaxDocxXmlBytes) return null;

  final body = XmlDocument.parse(
    utf8.decode(raw),
  ).descendantElements.where((e) => _isW(e, 'body')).firstOrNull;
  if (body == null) return null;

  final headings = _headingStyles(zip.findFile('word/styles.xml'));
  final sections = <DocxSection>[];
  var label = '';
  var buf = StringBuffer();
  // Whether the open section has anything besides headings. A heading with no
  // body of its own ("Chapter 3" straight above "3.1 Scope") folds into the
  // next section instead of becoming a chunk that is only a title.
  var hasBody = false;

  void flush() {
    final text = buf.toString().trim();
    if (text.isNotEmpty) sections.add((label: label, text: text));
    buf = StringBuffer();
    hasBody = false;
  }

  void walk(XmlElement container) {
    for (final el in container.childElements) {
      if (_isW(el, 'p')) {
        final text = _paragraphText(el);
        if (text.trim().isEmpty) continue;
        final heading = _isHeading(el, headings);
        if (heading) {
          if (hasBody) flush();
          label = _cap(_collapse(text));
        }
        buf.write('$text\n\n');
        if (!heading) hasBody = true;
      } else if (_isW(el, 'tbl')) {
        final text = _tableText(el);
        if (text.isEmpty) continue;
        buf.write('$text\n\n');
        hasBody = true;
      } else if (_isW(el, 'sdt') ||
          _isW(el, 'sdtContent') ||
          _isW(el, 'customXml')) {
        // Content controls wrap whole paragraphs; Word templates put section
        // headers in them, so skipping these would drop real text.
        walk(el);
      }
    }
  }

  walk(body);
  flush();
  return sections;
}

bool _isW(XmlElement e, String local) =>
    e.name.local == local && e.name.namespaceUri == _w;

String? _val(XmlElement e) => e.getAttribute('val', namespace: _w);

XmlElement? _child(XmlElement e, String local) =>
    e.childElements.where((c) => _isW(c, local)).firstOrNull;

/// `w:t` text, tabs and breaks, in order. Deleted text (`w:delText`) and field
/// codes (`w:instrText`) are different elements and so never match; text
/// boxes are skipped because their `mc:Fallback` copy would repeat them.
String _paragraphText(XmlElement p) {
  final out = StringBuffer();
  void walk(XmlElement e) {
    for (final c in e.childElements) {
      // A text move keeps its old copy in `w:moveFrom` as ordinary `w:t`, so
      // reading it would index the moved text twice.
      if (_isW(c, 'txbxContent') || _isW(c, 'moveFrom')) continue;
      if (_isW(c, 't')) {
        out.write(c.innerText);
      } else if (_isW(c, 'tab')) {
        out.write('\t');
      } else if (_isW(c, 'br') || _isW(c, 'cr')) {
        out.write('\n');
      } else {
        walk(c);
      }
    }
  }

  walk(p);
  return out.toString();
}

String _tableText(XmlElement tbl) => tbl.childElements
    .where((r) => _isW(r, 'tr'))
    .map(
      (row) => row.childElements
          .where((c) => _isW(c, 'tc'))
          .map(
            (cell) =>
                _collapse(_paragraphsIn(cell).map(_paragraphText).join(' ')),
          )
          .join(' | '),
    )
    .where((line) => line.replaceAll('|', '').trim().isNotEmpty)
    .join('\n');

/// Paragraphs under [e] (nested tables included), skipping text boxes for the
/// same reason [_paragraphText] does.
Iterable<XmlElement> _paragraphsIn(XmlElement e) sync* {
  for (final c in e.childElements) {
    if (_isW(c, 'txbxContent')) continue;
    if (_isW(c, 'p')) {
      yield c;
    } else {
      yield* _paragraphsIn(c);
    }
  }
}

bool _isHeading(XmlElement p, Set<String> headingStyles) {
  final pPr = _child(p, 'pPr');
  if (pPr == null) return false;
  if (_isOutline(_child(pPr, 'outlineLvl'))) return true;
  final style = _child(pPr, 'pStyle');
  return style != null && headingStyles.contains(_val(style));
}

/// `outlineLvl` 0–8 is a heading level; 9 means body text.
bool _isOutline(XmlElement? lvl) {
  final n = lvl == null ? null : int.tryParse(_val(lvl) ?? '');
  return n != null && n >= 0 && n <= 8;
}

/// Ids of paragraph styles that are headings, judged by *name* — built-in
/// names stay English in every Word locale while ids do not (German Word:
/// `berschrift1`) — or by an outline level, following `basedOn`.
///
/// An unreadable styles part costs only name-based detection: the body is
/// still worth indexing, and outline levels set on paragraphs still work.
Set<String> _headingStyles(ArchiveFile? file) {
  final XmlDocument styles;
  try {
    if (file == null || file.size > kMaxDocxStylesBytes) return const {};
    final raw = file.readBytes();
    if (raw == null || raw.length > kMaxDocxStylesBytes) return const {};
    styles = XmlDocument.parse(utf8.decode(raw));
  } catch (_) {
    return const {};
  }

  final byId = <String, XmlElement>{};
  for (final s in styles.descendantElements.where((e) => _isW(e, 'style'))) {
    final id = s.getAttribute('styleId', namespace: _w);
    if (id != null) byId[id] = s;
  }

  bool own(XmlElement s) {
    final nameEl = _child(s, 'name');
    final name = (nameEl == null ? null : _val(nameEl))?.toLowerCase() ?? '';
    if (name == 'title' || RegExp(r'^heading [1-9]$').hasMatch(name)) {
      return true;
    }
    final pPr = _child(s, 'pPr');
    return pPr != null && _isOutline(_child(pPr, 'outlineLvl'));
  }

  bool isHeading(String id) {
    var cur = byId[id];
    // Bounded: a malformed file can make `basedOn` loop.
    for (var depth = 0; cur != null && depth < 10; depth++) {
      if (own(cur)) return true;
      final base = _child(cur, 'basedOn');
      cur = base == null ? null : byId[_val(base)];
    }
    return false;
  }

  return {
    for (final id in byId.keys)
      if (isHeading(id)) id,
  };
}

String _collapse(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();

String _cap(String s) {
  if (s.length <= _maxLabelChars) return s;
  var end = _maxLabelChars - 1;
  // Never end on a high surrogate: that would split an emoji in two.
  final last = s.codeUnitAt(end - 1);
  if (last >= 0xD800 && last <= 0xDBFF) end--;
  return '${s.substring(0, end)}…';
}
