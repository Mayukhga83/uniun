import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/data/models/documents/document_chunk_model.dart';
import 'package:uniun/data/models/documents/document_index_model.dart';
import 'package:uniun/data/models/media/media_cache_model.dart';
import 'package:uniun/domain/usecases/vector_usecases.dart';
import 'package:uniun/features/shiv/rag/extraction/pdf_extraction_service.dart';
import 'package:uniun/features/shiv/rag/indexing/pdf_indexer.dart';

import '../../../../_helpers/fake_pdf_text_source.dart';
import '../../../../_helpers/isar_seeds.dart';
import '../../../../_helpers/isar_test_harness.dart';

class _MockEmbedAndStore extends Mock implements EmbedAndStoreChunkUseCase {}

/// Covers: reconcile indexing, non-PDF skipping, not-searchable recording,
/// embedder-failure retry, orphan purge, idempotency, coalescing, start().
void main() {
  const prose = 'The quarterly leave policy has been revised. ';
  const pdf = 'application/pdf';

  late Isar isar;
  late FakePdfTextSource source;
  late _MockEmbedAndStore embedAndStore;
  late PdfIndexer indexer;

  /// chunkId -> text, as handed to the use case.
  final stored = <String, String>{};

  setUpAll(() => registerFallbackValue(('', '')));

  setUp(() async {
    isar = await openTestIsar();
    source = FakePdfTextSource();
    stored.clear();
    embedAndStore = _MockEmbedAndStore();
    when(() => embedAndStore.call(any())).thenAnswer((i) async {
      final (id, text) = i.positionalArguments.first as (String, String);
      stored[id] = text;
      return true;
    });
    indexer = PdfIndexer(isar, PdfExtractionService(source), embedAndStore);
  });

  tearDown(() async {
    await indexer.dispose();
    await isar.close(deleteFromDisk: true);
  });

  Future<void> seedPdf(String sha,
      {String mime = pdf, List<String>? pages}) async {
    source.pages['/p/$sha.pdf'] = pages ?? [prose * 6];
    await isar.writeTxn(() => isar.mediaCacheModels
        .put(mediaCacheRow(sha, localPath: '/p/$sha.pdf', mime: mime)));
  }

  Future<DocumentIndexModel?> indexRow(String sha) =>
      isar.documentIndexModels.filter().sha256EqualTo(sha).findFirst();

  Future<List<DocumentChunkModel>> chunkRows(String sha) =>
      isar.documentChunkModels.where().sha256EqualToAnyOrdinal(sha).findAll();

  group('indexing', () {
    test('a new PDF is chunked, embedded and marked indexed', () async {
      await seedPdf('a', pages: [prose * 6, prose * 6]);

      await indexer.reconcile();

      final chunks = await chunkRows('a');
      final row = await indexRow('a');
      expect(row?.status, DocumentIndexStatus.indexed);
      expect(row?.pageCount, 2);
      expect(row?.chunkCount, chunks.length);
      expect(chunks.map((c) => c.label).toSet(), {'1', '2'});
      expect(stored.keys.toSet(), {for (final c in chunks) 'a:${c.ordinal}'});
      verify(() => embedAndStore.call(any())).called(chunks.length);
    });

    test('a non-PDF cache row is ignored', () async {
      await seedPdf('img', mime: 'image/jpeg');

      await indexer.reconcile();

      expect(await indexRow('img'), isNull);
      verifyNever(() => embedAndStore.call(any()));
    });

    test('the PDF mime match ignores case and parameters', () async {
      await seedPdf('a', mime: 'Application/PDF; charset=binary');

      await indexer.reconcile();

      expect((await indexRow('a'))?.status, DocumentIndexStatus.indexed);
    });

    test('several PDFs are all indexed', () async {
      await seedPdf('a');
      await seedPdf('b');

      await indexer.reconcile();

      expect((await indexRow('a'))?.status, DocumentIndexStatus.indexed);
      expect((await indexRow('b'))?.status, DocumentIndexStatus.indexed);
    });
  });

  group('not searchable', () {
    test('a scan is recorded once and never re-extracted', () async {
      await seedPdf('scan', pages: ['', '']);

      await indexer.reconcile();
      await indexer.reconcile();

      final row = await indexRow('scan');
      expect(row?.status, DocumentIndexStatus.notSearchable);
      expect(row?.chunkCount, 0);
      expect(await chunkRows('scan'), isEmpty);
      expect(source.calls, 1);
      verifyNever(() => embedAndStore.call(any()));
    });

    test('an unreadable file is recorded as not searchable', () async {
      source.pages['/p/bad.pdf'] = null;
      await isar.writeTxn(() => isar.mediaCacheModels
          .put(mediaCacheRow('bad', localPath: '/p/bad.pdf', mime: pdf)));

      await indexer.reconcile();

      expect((await indexRow('bad'))?.status,
          DocumentIndexStatus.notSearchable);
    });
  });

  group('embedder not ready', () {
    test('a failed embed leaves the document unindexed and retries cleanly',
        () async {
      await seedPdf('a', pages: [prose * 6, prose * 6]);
      var calls = 0;
      when(() => embedAndStore.call(any())).thenAnswer((i) async {
        calls++;
        if (calls > 1) return false; // embedder not ready
        final (id, text) = i.positionalArguments.first as (String, String);
        stored[id] = text;
        return true;
      });

      await indexer.reconcile();

      expect(await indexRow('a'), isNull,
          reason: 'not marked done — distinct from notSearchable');

      when(() => embedAndStore.call(any())).thenAnswer((i) async {
        final (id, text) = i.positionalArguments.first as (String, String);
        stored[id] = text;
        return true;
      });
      await indexer.reconcile();

      final chunks = await chunkRows('a');
      expect((await indexRow('a'))?.status, DocumentIndexStatus.indexed);
      expect(chunks.length, (await indexRow('a'))!.chunkCount,
          reason: 'the partial run left no duplicate rows');
      expect(stored.length, chunks.length);
    });
  });

  group('purge', () {
    test('removing the cache row removes chunks and the index row', () async {
      await seedPdf('a');
      await indexer.reconcile();
      expect(await chunkRows('a'), isNotEmpty);

      await isar.writeTxn(() => isar.mediaCacheModels.deleteBySha256('a'));
      await indexer.reconcile();

      expect(await chunkRows('a'), isEmpty);
      expect(await indexRow('a'), isNull);
    });

    test('purging one document leaves another alone', () async {
      await seedPdf('a');
      await seedPdf('b');
      await indexer.reconcile();

      await isar.writeTxn(() => isar.mediaCacheModels.deleteBySha256('a'));
      await indexer.reconcile();

      expect(await chunkRows('a'), isEmpty);
      expect(await chunkRows('b'), isNotEmpty);
      expect((await indexRow('b'))?.status, DocumentIndexStatus.indexed);
    });
  });

  // ── Edge cases ──────────────────────────────────────────────────────────

  group('idempotency and coalescing', () {
    test('a second reconcile does no more work', () async {
      var embeds = 0;
      when(() => embedAndStore.call(any())).thenAnswer((_) async {
        embeds++;
        return true;
      });
      await seedPdf('a');

      await indexer.reconcile();
      final afterFirst = embeds;
      await indexer.reconcile();

      expect(source.calls, 1);
      expect(embeds, afterFirst);
    });

    test('overlapping reconciles extract a document once', () async {
      await seedPdf('a');
      final gate = Completer<void>();
      source.gate = gate.future;

      final first = indexer.reconcile();
      final second = indexer.reconcile();
      gate.complete();
      await Future.wait([first, second]);

      expect(source.calls, 1);
      expect((await indexRow('a'))?.status, DocumentIndexStatus.indexed);
    });

    test('a reconcile with nothing cached is a no-op', () async {
      await indexer.reconcile();

      expect(await isar.documentIndexModels.count(), 0);
      expect(source.calls, 0);
    });
  });

  group('start', () {
    test('indexes a PDF already cached, then one that arrives later', () async {
      Future<void> until(Future<bool> Function() cond) async {
        final deadline = DateTime.now().add(const Duration(seconds: 10));
        while (!await cond()) {
          if (DateTime.now().isAfter(deadline)) {
            fail('timed out waiting for the indexer');
          }
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
      }

      await seedPdf('early');
      indexer.start();
      await until(() async => await indexRow('early') != null);

      await seedPdf('late');
      await until(() async => await indexRow('late') != null);

      expect((await indexRow('late'))?.status, DocumentIndexStatus.indexed);
    });

    test('start twice keeps a single watcher', () async {
      indexer.start();
      indexer.start();
      await indexer.dispose();
    });
  });
}
