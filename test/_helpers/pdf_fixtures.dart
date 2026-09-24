import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Absolute path to a committed PDF fixture in `test/_helpers/fixtures/pdf/`.
///
/// Walks up to the package root rather than trusting the process cwd, so the
/// path resolves whatever directory the test runner was invoked from.
String pdfFixture(String name) {
  var dir = Directory.current;
  while (!File('${dir.path}/pubspec.yaml').existsSync()) {
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError('package root not found from ${Directory.current.path}');
    }
    dir = parent;
  }
  return '${dir.path}/test/_helpers/fixtures/pdf/$name';
}

/// Folds PDF text-layer artefacts so assertions survive extractor differences.
///
/// Real documents carry ligatures, soft hyphens, non-breaking spaces and curly
/// quotes, and wrap lines wherever the layout decided to. Asserting on raw
/// extracted text pins all of that, and breaks on the next PDFium version.
String normalizePdfText(String s) => s
    .replaceAll('­', '') // soft hyphen
    .replaceAll('ﬀ', 'ff')
    .replaceAll('ﬁ', 'fi')
    .replaceAll('ﬂ', 'fl')
    .replaceAll('ﬃ', 'ffi')
    .replaceAll('ﬄ', 'ffl')
    .replaceAll(RegExp(r'[‘’]'), "'")
    .replaceAll(RegExp(r'[“”]'), '"')
    .replaceAll(RegExp(r'[‐-―]'), '-')
    .replaceAll(' ', ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim()
    .toLowerCase();

/// Minimal valid PDF 1.4 with one Helvetica text line per page (ASCII only).
///
/// For the cases a real fixture cannot express: an empty string yields a page
/// with no text operators, standing in for a scan. Real-world extraction is
/// proven against the committed fixtures, not this.
Uint8List minimalPdf(List<String> pageTexts) {
  String esc(String s) =>
      s.replaceAll(r'\', r'\\').replaceAll('(', r'\(').replaceAll(')', r'\)');

  final n = pageTexts.length;
  final objs = <String>[
    '<< /Type /Catalog /Pages 2 0 R >>',
    '<< /Type /Pages /Kids [${[
      for (var i = 0; i < n; i++) '${4 + i * 2} 0 R',
    ].join(' ')}] /Count $n >>',
    '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
  ];
  for (var i = 0; i < n; i++) {
    final content = pageTexts[i].isEmpty
        ? ''
        : 'BT /F1 12 Tf 72 720 Td (${esc(pageTexts[i])}) Tj ET';
    objs.add(
      '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] '
      '/Contents ${5 + i * 2} 0 R /Resources << /Font << /F1 3 0 R >> >> >>',
    );
    objs.add('<< /Length ${content.length} >>\nstream\n$content\nendstream');
  }

  final sb = StringBuffer('%PDF-1.4\n');
  final offsets = <int>[];
  for (var i = 0; i < objs.length; i++) {
    offsets.add(sb.length);
    sb.write('${i + 1} 0 obj\n${objs[i]}\nendobj\n');
  }
  final xrefAt = sb.length;
  sb.write('xref\n0 ${objs.length + 1}\n0000000000 65535 f \n');
  for (final o in offsets) {
    sb.write('${o.toString().padLeft(10, '0')} 00000 n \n');
  }
  sb.write(
    'trailer\n<< /Size ${objs.length + 1} /Root 1 0 R >>\n'
    'startxref\n$xrefAt\n%%EOF\n',
  );
  return Uint8List.fromList(latin1.encode(sb.toString()));
}
