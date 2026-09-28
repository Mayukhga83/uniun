// Device-bound end-to-end test for PDF RAG with the REAL Gecko embedder.
//
// Why this cannot live under `test/`: the embedder loads through flutter_gemma
// from `assets/models/embedding/gecko_1024_quant.tflite`, a 145 MB Git-LFS
// asset. Headless `flutter test` has no such asset, and CI checks out without
// LFS, so the file there is a ~130-byte pointer. Worse, `EmbeddingService.embed`
// returns `[]` rather than throwing when the model is missing — a CI run would
// go green while embedding nothing. Hence: device only, and the first assertion
// below is a hard check that the model really loaded.
//
// Everything else about the pipeline (real PDFium, real chunking, real Isar,
// real ToStore, purge, idempotency) is proven in CI by
// `test/integration/pdf_rag_flow_test.dart`. What ONLY this test can prove is
// that genuine 1024-dim Gecko vectors retrieve the *semantically right* chunk.
//
// Run:
//   flutter test integration_test/pdf_rag_e2e_test.dart -d <device-id>
//
// By default it indexes a generated two-page PDF whose pages are about clearly
// different subjects. To run against a real document instead:
//   adb push test/_helpers/fixtures/pdf/nist_sp800-145.pdf /sdcard/Download/
//   flutter test integration_test/pdf_rag_e2e_test.dart -d <device-id> \
//     --dart-define=PDF_FIXTURE_PATH=/sdcard/Download/nist_sp800-145.pdf

import 'dart:io';

import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';
import 'package:flutter_gemma_mediapipe/flutter_gemma_mediapipe.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:isar_community/isar.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/data/models/documents/document_chunk_model.dart';
import 'package:uniun/data/models/documents/document_index_model.dart';
import 'package:uniun/data/models/media/media_cache_model.dart';
import 'package:uniun/domain/repositories/document_vector_repository.dart';
import 'package:uniun/features/shiv/rag/embedding/embedding_service.dart';
import 'package:uniun/features/shiv/rag/indexing/pdf_indexer.dart';

/// Two pages on plainly different subjects, so a semantic query can only reach
/// the right one by meaning rather than by luck.
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

  test('a PDF is indexed with the real Gecko embedder and the right page is '
      'retrieved semantically', () async {
    await configureDependencies();
    await FlutterGemma.initialize(
      inferenceEngines: const [LiteRtLmEngine(), MediaPipeEngine()],
      embeddingBackends: const [LiteRtEmbeddingBackend()],
    );
    await pdfrxFlutterInitialize();

    final isar = getIt<Isar>();
    final embedding = getIt<EmbeddingService>();
    final vectors = getIt<DocumentVectorRepository>();
    final indexer = getIt<PdfIndexer>();

    // ── The gate: the real model must actually be loaded ──────────────────
    // Deliberately NOT a skip. Gecko ships as a bundled asset, so its absence
    // on a correctly built app is a bug, not a missing precondition — unlike
    // the chat models, which the user has to download.
    final probe = await embedding.embed('a probe sentence');
    expect(
      probe,
      hasLength(EmbeddingService.embeddingDim),
      reason: '[] means the bundled model did not load at all. A different '
          'length means the app-declared dimension is not what the model '
          'emits — measured on device: the model returns 768 while '
          'EmbeddingService.embeddingDim says 1024. ToStore tolerates that '
          'mismatch (verified on host), so it is a correctness/documentation '
          'problem, not by itself the cause of empty search results',
    );

    // ── Index a document ─────────────────────────────────────────────────
    const override = String.fromEnvironment('PDF_FIXTURE_PATH');
    final String path;
    if (override.isNotEmpty) {
      expect(File(override).existsSync(), isTrue,
          reason: 'PDF_FIXTURE_PATH was set but no file is there — did the '
              'adb push run?');
      path = override;
    } else {
      final dir = await Directory.systemTemp.createTemp('pdf_rag_e2e');
      final f = File('${dir.path}/two_subjects.pdf');
      await f.writeAsBytes(_twoPagePdf());
      path = f.path;
    }

    final sha = 'e2e${DateTime.now().microsecondsSinceEpoch}';
    final size = await File(path).length();
    await isar.writeTxn(() => isar.mediaCacheModels.put(MediaCacheModel()
      ..sha256 = sha
      ..localPath = path
      ..mime = 'application/pdf'
      ..sizeBytes = size
      ..downloadedAt = DateTime.now()));

    await indexer.reconcile();

    final row =
        await isar.documentIndexModels.filter().sha256EqualTo(sha).findFirst();
    expect(row?.status, DocumentIndexStatus.indexed,
        reason: 'the document should have been extracted and embedded');

    final chunks = await isar.documentChunkModels
        .where()
        .sha256EqualToAnyOrdinal(sha)
        .findAll();
    expect(chunks, isNotEmpty);

    // ── The point of this tier: real semantic retrieval ───────────────────
    final query = override.isNotEmpty
        ? 'what is the definition of cloud computing?'
        : 'how should I water and support tomato plants?';
    final expectContains =
        override.isNotEmpty ? 'cloud computing' : 'tomato';

    final queryVector = await embedding.embed(query);
    expect(queryVector, hasLength(EmbeddingService.embeddingDim));

    final hits = await vectors.search(queryVector, topK: 3, minScore: 0.0);

    expect(hits, isNotEmpty, reason: 'the query retrieved no chunk at all');
    expect(
      hits.first.content.toLowerCase(),
      contains(expectContains),
      reason: 'the closest chunk for "$query" should be the one about '
          '"$expectContains", not ${hits.first.content}',
    );
    expect(hits.first.label, isNotEmpty,
        reason: 'a citation needs the page it came from');

    // ignore: avoid_print
    print('E2E OK — ${chunks.length} chunk(s), top hit p.${hits.first.label} '
        'score ${hits.first.score.toStringAsFixed(3)}');

    // ── Clean up after ourselves ──────────────────────────────────────────
    await isar.writeTxn(() => isar.mediaCacheModels.deleteBySha256(sha));
    await indexer.reconcile();
    expect(
      await isar.documentChunkModels
          .where()
          .sha256EqualToAnyOrdinal(sha)
          .count(),
      0,
    );
  }, timeout: const Timeout(Duration(minutes: 5)));
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
    objs.add('<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] '
        '/Contents ${5 + i * 2} 0 R /Resources << /Font << /F1 3 0 R >> >> >>');
    objs.add('<< /Length ${pages[i].length} >>\nstream\n${pages[i]}\nendstream');
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
  sb.write('trailer\n<< /Size ${objs.length + 1} /Root 1 0 R >>\n'
      'startxref\n$xrefAt\n%%EOF\n');
  return sb.toString().codeUnits;
}
