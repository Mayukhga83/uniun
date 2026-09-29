// Device-bound end-to-end test for document RAG with the REAL Gecko embedder.
//
// Why this cannot live under `test/`: the embedder loads through flutter_gemma
// from `assets/models/embedding/gecko_1024_quant.tflite`, a 145 MB Git-LFS
// asset. Headless `flutter test` has no such asset, and CI checks out without
// LFS, so the file there is a ~130-byte pointer. Worse, `EmbeddingService.embed`
// returns `[]` rather than throwing when the model is missing — a CI run would
// go green while embedding nothing. Hence: device only, and each test first
// checks that the model really loaded.
//
// Everything else about the pipeline (real PDFium, the real DOCX reader, real
// chunking, real Isar, real ToStore, purge, idempotency) is proven in CI by
// `test/integration/document_rag_flow_test.dart`. What ONLY this test can
// prove is that genuine Gecko vectors retrieve the *semantically right* chunk
// — and, for a DOCX, that the chunk carries the right heading — and that real
// ML Kit OCR reads text (English and Hindi) out of an image, which never runs
// under `flutter test`.
//
// Run:
//   flutter test integration_test/document_rag_e2e_test.dart -d <device-id>
//
// By default the PDF test indexes a generated two-page PDF whose pages are
// about clearly different subjects. To run it against a real document instead:
//   adb push test/_helpers/fixtures/pdf/nist_sp800-145.pdf /sdcard/Download/
//   flutter test integration_test/document_rag_e2e_test.dart -d <device-id> \
//     --dart-define=PDF_FIXTURE_PATH=/sdcard/Download/nist_sp800-145.pdf

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:archive/archive.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';
import 'package:flutter_gemma_mediapipe/flutter_gemma_mediapipe.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:isar_community/isar.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/core/enum/document_kind.dart';
import 'package:uniun/data/datasources/ocr/ocr_text_source.dart';
import 'package:uniun/data/models/documents/document_chunk_model.dart';
import 'package:uniun/data/models/documents/document_index_model.dart';
import 'package:uniun/data/models/media/media_cache_model.dart';
import 'package:uniun/data/models/saved_note_model.dart';
import 'package:uniun/data/models/notes/media_attachment.dart';
import 'package:uniun/core/enum/note_type.dart';
import 'package:uniun/domain/repositories/document_vector_repository.dart';
import 'package:uniun/features/shiv/rag/embedding/embedding_service.dart';
import 'package:uniun/features/shiv/rag/indexing/document_indexer.dart';

/// Two pages (or sections) on plainly different subjects, so a semantic query
/// can only reach the right one by meaning rather than by luck.
const _cloudPage =
    'Cloud computing is a model for enabling ubiquitous, convenient, on-demand '
    'network access to a shared pool of configurable computing resources such '
    'as networks, servers, storage, applications and services, which can be '
    'rapidly provisioned and released with minimal management effort. The '
    'service models include software as a service, platform as a service and '
    'infrastructure as a service, and the deployment models include private, '
    'community, public and hybrid clouds.';

const _gardeningPage =
    'Tomato plants grow best in well drained soil with full sunlight for at '
    'least six hours each day. Water them deeply at the base rather than over '
    'the leaves, mulch to retain moisture, and stake or cage the plants early '
    'so the stems are supported before the fruit becomes heavy. Prune the side '
    'shoots to concentrate growth in the main stem and harvest when the fruit '
    'is firm and fully coloured.';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Isar isar;
  late EmbeddingService embedding;
  late DocumentVectorRepository vectors;
  late DocumentIndexer indexer;

  setUpAll(() async {
    await configureDependencies();
    await FlutterGemma.initialize(
      inferenceEngines: const [LiteRtLmEngine(), MediaPipeEngine()],
      embeddingBackends: const [LiteRtEmbeddingBackend()],
    );
    await pdfrxFlutterInitialize();
    isar = getIt<Isar>();
    embedding = getIt<EmbeddingService>();
    vectors = getIt<DocumentVectorRepository>();
    indexer = getIt<DocumentIndexer>();
  });

  /// The gate: the real model must actually be loaded. Deliberately NOT a
  /// skip — Gecko ships as a bundled asset, so its absence on a correctly
  /// built app is a bug, not a missing precondition like a chat model the user
  /// has to download. Checks non-empty rather than a length: the model emits
  /// 768 where the app declares 1024 (#234), which ToStore tolerates.
  Future<void> expectModelLoaded() async {
    expect(
      await embedding.embed('a probe sentence'),
      isNotEmpty,
      reason: '[] means the bundled embedding model did not load at all',
    );
  }

  /// Registers [path] in the media cache as a downloaded blob would be,
  /// indexes it, and returns its sha.
  Future<String> index(
    String path,
    DocumentKind kind, {
    DocumentIndexStatus expected = DocumentIndexStatus.indexed,
  }) async {
    final sha = 'e2e${kind.name}${DateTime.now().microsecondsSinceEpoch}';
    final size = await File(path).length();
    await isar.writeTxn(
      () => isar.mediaCacheModels.put(
        MediaCacheModel()
          ..sha256 = sha
          ..localPath = path
          ..mime = kind.mime
          ..sizeBytes = size
          ..downloadedAt = DateTime.now(),
      ),
    );
    // Shiv only cites documents on the user's own or saved notes.
    await isar.writeTxn(
      () => isar.savedNoteModels.put(
        SavedNoteModel()
          ..eventId = 'e2e-saved-$sha'
          ..authorPubkey = 'e2e'
          ..sig = ''
          ..content = 'e2e document note'
          ..type = NoteType.text
          ..eTagRefs = const []
          ..pTagRefs = const []
          ..tTags = const []
          ..created = DateTime.now()
          ..savedAt = DateTime.now()
          ..attachments = [
            MediaAttachment()
              ..sha256 = sha
              ..mime = kind.mime,
          ],
      ),
    );
    await indexer.reconcile();
    final row = await isar.documentIndexModels
        .filter()
        .sha256EqualTo(sha)
        .findFirst();
    expect(
      row?.status,
      expected,
      reason: 'the document should have been extracted and embedded',
    );
    return sha;
  }

  Future<List<DocumentChunkModel>> chunksOf(String sha) =>
      isar.documentChunkModels.where().sha256EqualToAnyOrdinal(sha).findAll();

  Future<void> purge(String sha) async {
    await isar.writeTxn(() async {
      await isar.mediaCacheModels.deleteBySha256(sha);
      await isar.savedNoteModels.deleteByEventId('e2e-saved-$sha');
    });
    await indexer.reconcile();
    expect(await chunksOf(sha), isEmpty);
  }

  Future<File> tempFile(String name, List<int> bytes) async {
    final dir = await Directory.systemTemp.createTemp('document_rag_e2e');
    return File('${dir.path}/$name')..writeAsBytesSync(bytes);
  }

  test('a PDF is indexed with the real Gecko embedder and the right page is '
      'retrieved semantically', () async {
    await expectModelLoaded();

    const override = String.fromEnvironment('PDF_FIXTURE_PATH');
    final String path;
    if (override.isNotEmpty) {
      expect(
        File(override).existsSync(),
        isTrue,
        reason:
            'PDF_FIXTURE_PATH was set but no file is there — did the '
            'adb push run?',
      );
      path = override;
    } else {
      path = (await tempFile('two_subjects.pdf', _twoPagePdf())).path;
    }
    final sha = await index(path, DocumentKind.pdf);
    final chunks = await chunksOf(sha);
    expect(chunks, isNotEmpty);

    final query = override.isNotEmpty
        ? 'what is the definition of cloud computing?'
        : 'how should I water and support tomato plants?';
    final expectContains = override.isNotEmpty ? 'cloud computing' : 'tomato';

    final hits = await vectors.search(
      await embedding.embed(query),
      topK: 3,
      minScore: 0.0,
    );

    expect(hits, isNotEmpty, reason: 'the query retrieved no chunk at all');
    expect(
      hits.first.content.toLowerCase(),
      contains(expectContains),
      reason:
          'the closest chunk for "$query" should be the one about '
          '"$expectContains", not ${hits.first.content}',
    );
    expect(hits.first.kind, DocumentKind.pdf);
    expect(
      hits.first.label,
      isNotEmpty,
      reason: 'a citation needs the page it came from',
    );

    // ignore: avoid_print
    print(
      'E2E PDF OK — ${chunks.length} chunk(s), top hit '
      'p.${hits.first.label} score ${hits.first.score.toStringAsFixed(3)}',
    );
    await purge(sha);
  }, timeout: const Timeout(Duration(minutes: 5)));

  test('a DOCX is indexed with the real Gecko embedder and the right section '
      'is retrieved semantically', () async {
    await expectModelLoaded();

    final file = await tempFile('two_subjects.docx', _twoSectionDocx());
    final sha = await index(file.path, DocumentKind.docx);
    final chunks = await chunksOf(sha);
    expect(chunks.map((c) => c.label).toSet(), {
      'Cloud Computing',
      'Growing Tomatoes',
    });

    final hits = await vectors.search(
      await embedding.embed('how should I water and support tomato plants?'),
      topK: 3,
      minScore: 0.0,
    );

    expect(hits, isNotEmpty, reason: 'the query retrieved no chunk at all');
    expect(hits.first.kind, DocumentKind.docx);
    expect(
      hits.first.label,
      'Growing Tomatoes',
      reason:
          'the citation must name the section the answer came from, '
          'not ${hits.first.label}: ${hits.first.content}',
    );

    // ignore: avoid_print
    print(
      'E2E DOCX OK — ${chunks.length} chunk(s), top hit '
      '"${hits.first.label}" score ${hits.first.score.toStringAsFixed(3)}',
    );
    await purge(sha);
  }, timeout: const Timeout(Duration(minutes: 5)));

  group('images (real ML Kit OCR)', () {
    test('OCR reads the words of an English notice', () async {
      final png = await _renderText(
        'OFFICE ORDER\nEarned leave may be carried forward\nup to 15 days.',
      );
      final file = await tempFile('en_notice.png', png);

      final text = (await getIt<OcrTextSource>().imageText(file.path))!;

      // ignore: avoid_print
      print('OCR EN → ${text.replaceAll('\n', ' ⏎ ')}');
      expect(
        text.toLowerCase(),
        allOf(contains('office order'), contains('15 days')),
      );
    });

    test(
      'OCR keeps both languages of a mixed Hindi and English notice',
      () async {
        final png = await _renderText(
          'कार्यालय आदेश\nसभी कर्मचारियों के लिए\nOFFICE ORDER\nLeave rules 2026',
        );
        final file = await tempFile('mixed_notice.png', png);

        final text = (await getIt<OcrTextSource>().imageText(file.path))!;

        // ignore: avoid_print
        print('OCR MIXED → ${text.replaceAll('\n', ' ⏎ ')}');
        expect(text, contains('आदेश'), reason: 'the Hindi line');
        expect(
          text.toUpperCase(),
          contains('OFFICE ORDER'),
          reason:
              'the English line — if this fails, the Devanagari '
              'recogniser drops Latin text and the two passes must be merged',
        );
      },
    );

    test(
      'an image of text is retrieved semantically with real Gecko',
      () async {
        await expectModelLoaded();
        final cloud = await tempFile(
          'cloud.png',
          await _renderText(_wrap(_cloudPage)),
        );
        final garden = await tempFile(
          'garden.png',
          await _renderText(_wrap(_gardeningPage)),
        );
        final cloudSha = await index(cloud.path, DocumentKind.image);
        final gardenSha = await index(garden.path, DocumentKind.image);

        final hits = await vectors.search(
          await embedding.embed(
            'how should I water and support tomato plants?',
          ),
          topK: 3,
          minScore: 0.0,
        );

        expect(hits, isNotEmpty);
        expect(hits.first.kind, DocumentKind.image);
        expect(
          hits.first.sha256,
          gardenSha,
          reason:
              'the tomato question should reach the tomato image, not '
              '${hits.first.content}',
        );
        // ignore: avoid_print
        print(
          'E2E IMAGE OK — top hit score ${hits.first.score.toStringAsFixed(3)}',
        );
        await purge(cloudSha);
        await purge(gardenSha);
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );

    test('a picture with no text is kept but not searchable', () async {
      final blank = await tempFile('sky.png', await _renderBlank());

      final sha = await index(
        blank.path,
        DocumentKind.image,
        expected: DocumentIndexStatus.notSearchable,
      );

      expect(await chunksOf(sha), isEmpty);
      await purge(sha);
    });
  });
}

/// Minimal Word package: one Heading 1 per subject, each followed by its
/// paragraph. Built here rather than committed so the test needs no push step.
List<int> _twoSectionDocx() {
  const w = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main';
  String esc(String s) => const HtmlEscape(HtmlEscapeMode.element).convert(s);
  String p(String text, {String? style}) =>
      '<w:p>'
      '${style == null ? '' : '<w:pPr><w:pStyle w:val="$style"/></w:pPr>'}'
      '<w:r><w:t xml:space="preserve">${esc(text)}</w:t></w:r></w:p>';

  final parts = {
    '[Content_Types].xml':
        '<?xml version="1.0" encoding="UTF-8"?>'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="xml" ContentType="application/xml"/>'
        '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>'
        '</Types>',
    '_rels/.rels':
        '<?xml version="1.0" encoding="UTF-8"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>'
        '</Relationships>',
    'word/styles.xml':
        '<?xml version="1.0" encoding="UTF-8"?>'
        '<w:styles xmlns:w="$w"><w:style w:type="paragraph" w:styleId="Heading1">'
        '<w:name w:val="heading 1"/></w:style></w:styles>',
    'word/document.xml':
        '<?xml version="1.0" encoding="UTF-8"?>'
        '<w:document xmlns:w="$w"><w:body>'
        '${p('Cloud Computing', style: 'Heading1')}${p(_cloudPage)}'
        '${p('Growing Tomatoes', style: 'Heading1')}${p(_gardeningPage)}'
        '</w:body></w:document>',
  };
  final archive = Archive();
  parts.forEach(
    (name, xml) => archive.addFile(ArchiveFile.bytes(name, utf8.encode(xml))),
  );
  return ZipEncoder().encodeBytes(archive);
}

/// Minimal two-page PDF, one paragraph per page, wrapped so each line fits.
List<int> _twoPagePdf() {
  String esc(String s) =>
      s.replaceAll(r'\', r'\\').replaceAll('(', r'\(').replaceAll(')', r'\)');

  /// One `Tj` per ~90 characters, moved down the page, so PDFium sees real
  /// lines rather than one run off the edge.
  String contentFor(String text) {
    final words = text.split(' ');
    final lines = <String>[];
    var line = '';
    for (final w in words) {
      if ((line + w).length > 90) {
        lines.add(line.trim());
        line = '';
      }
      line = '$line$w ';
    }
    if (line.trim().isNotEmpty) lines.add(line.trim());
    final buf = StringBuffer('BT /F1 11 Tf 54 720 Td 14 TL\n');
    for (final l in lines) {
      buf.write('(${esc(l)}) Tj T*\n');
    }
    buf.write('ET');
    return buf.toString();
  }

  final pages = [contentFor(_cloudPage), contentFor(_gardeningPage)];
  final objs = <String>[
    '<< /Type /Catalog /Pages 2 0 R >>',
    '<< /Type /Pages /Kids [4 0 R 6 0 R] /Count 2 >>',
    '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
  ];
  for (var i = 0; i < pages.length; i++) {
    objs.add(
      '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] '
      '/Contents ${5 + i * 2} 0 R /Resources << /Font << /F1 3 0 R >> >> >>',
    );
    objs.add(
      '<< /Length ${pages[i].length} >>\nstream\n${pages[i]}\nendstream',
    );
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
  return sb.toString().codeUnits;
}

/// Breaks [text] into short lines so a rendered notice stays readable.
String _wrap(String text, {int width = 42}) {
  final lines = <String>[];
  var line = '';
  for (final w in text.split(' ')) {
    if (line.isNotEmpty && line.length + 1 + w.length > width) {
      lines.add(line);
      line = '';
    }
    line = line.isEmpty ? w : '$line $w';
  }
  if (line.isNotEmpty) lines.add(line);
  return lines.join('\n');
}

/// [text] drawn black on white, large enough for OCR, as a PNG — rendered on
/// the device with its own fonts, so Devanagari needs no bundled font.
Future<List<int>> _renderText(String text) async {
  final builder = ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: 36))
    ..pushStyle(ui.TextStyle(color: const ui.Color(0xFF000000)))
    ..addText(text);
  final paragraph = builder.build()
    ..layout(const ui.ParagraphConstraints(width: 1000));
  final height = paragraph.height.ceil() + 80;
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder)
    ..drawRect(
      ui.Rect.fromLTWH(0, 0, 1080, height.toDouble()),
      ui.Paint()..color = const ui.Color(0xFFFFFFFF),
    )
    ..drawParagraph(paragraph, const ui.Offset(40, 40));
  final image = await recorder.endRecording().toImage(1080, height);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  return png!.buffer.asUint8List();
}

/// A plain sky-blue square: a photo with nothing to read.
Future<List<int>> _renderBlank() async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    const ui.Rect.fromLTWH(0, 0, 800, 600),
    ui.Paint()..color = const ui.Color(0xFF87CEEB),
  );
  final image = await recorder.endRecording().toImage(800, 600);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  return png!.buffer.asUint8List();
}
