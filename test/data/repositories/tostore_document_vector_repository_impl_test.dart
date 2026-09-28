import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:tostore/tostore.dart';
import 'package:uniun/core/enum/document_kind.dart';
import 'package:uniun/data/datasources/tostore_module.dart';
import 'package:uniun/data/models/documents/document_chunk_model.dart';
import 'package:uniun/data/models/documents/document_index_model.dart';
import 'package:uniun/data/models/media/media_cache_model.dart';
import 'package:uniun/data/repositories/tostore_document_vector_repository_impl.dart';
import 'package:uniun/domain/entities/shiv/scored_chunk.dart';

import '../../_helpers/fixtures.dart';
import '../../_helpers/isar_seeds.dart';
import '../../_helpers/isar_test_harness.dart';

/// Covers: chunk vector upsert and search over a real ToStore, text, label and
/// kind resolution from Isar, score ordering and filtering, orphan tolerance,
/// persistence across a reopen.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Isar isar;
  late ToStore store;
  late Directory dir;
  late TostoreDocumentVectorRepositoryImpl repo;

  List<double> oneHot(int k) =>
      List<double>.generate(embeddingsDimensions, (i) => i == k ? 1.0 : 0.0);

  /// A chunk row plus its cached file and index row, as the indexer leaves
  /// them.
  Future<void> seedChunk(String sha, int ordinal, String text,
          {String label = '1', DocumentKind kind = DocumentKind.pdf}) =>
      isar.writeTxn(() async {
        if (await isar.mediaCacheModels.getBySha256(sha) == null) {
          await isar.mediaCacheModels.put(mediaCacheRow(sha, mime: kind.mime));
          await isar.documentIndexModels.put(DocumentIndexModel()
            ..sha256 = sha
            ..kind = kind
            ..status = DocumentIndexStatus.indexed
            ..indexedAt = tNow);
        }
        await isar.documentChunkModels.put(DocumentChunkModel()
          ..sha256 = sha
          ..ordinal = ordinal
          ..label = label
          ..text = text);
      });

  setUp(() async {
    isar = await openTestIsar();
    dir = await Directory.systemTemp.createTemp('doc_vectors_test');
    store = await ToStore.open(
      dbPath: dir.path,
      schemas: [documentChunkEmbeddingsSchema],
    );
    repo = TostoreDocumentVectorRepositoryImpl(store, isar);
  });

  tearDown(() async {
    await store.close();
    await dir.delete(recursive: true);
    await isar.close(deleteFromDisk: true);
  });

  group('search', () {
    test('a stored chunk is found by an identical query, with text and page',
        () async {
      await seedChunk('s', 0, 'leave policy text', label: '4');
      await repo.upsert(chunkIdOf('s', 0), oneHot(0));

      final hits = await repo.search(oneHot(0));

      expect(hits, hasLength(1));
      expect(hits.single.chunkId, 's:0');
      expect(hits.single.sha256, 's');
      expect(hits.single.label, '4');
      expect(hits.single.content, 'leave policy text');
      expect(hits.single.score, closeTo(1.0, 0.01));
    });

    test('a DOCX chunk comes back with its kind and heading label', () async {
      await seedChunk('w', 0, 'annual leave text',
          label: 'Annual Leave', kind: DocumentKind.docx);
      await repo.upsert(chunkIdOf('w', 0), oneHot(0));

      final hit = (await repo.search(oneHot(0))).single;

      expect(hit.kind, DocumentKind.docx);
      expect(hit.label, 'Annual Leave');
    });

    test('a PDF chunk comes back as a PDF', () async {
      await seedChunk('s', 0, 'x');
      await repo.upsert(chunkIdOf('s', 0), oneHot(0));

      expect((await repo.search(oneHot(0))).single.kind, DocumentKind.pdf);
    });

    test('a hit whose document is no longer indexed is dropped', () async {
      await seedChunk('s', 0, 'x');
      await repo.upsert(chunkIdOf('s', 0), oneHot(0));
      await isar.writeTxn(() => isar.documentIndexModels.deleteBySha256('s'));

      expect(await repo.search(oneHot(0)), isEmpty);
    });

    test('a re-download that rewrites the cached mime keeps the kind',
        () async {
      await seedChunk('w', 0, 'x', label: 'Scope', kind: DocumentKind.docx);
      await repo.upsert(chunkIdOf('w', 0), oneHot(0));
      await isar.writeTxn(() async {
        final row = (await isar.mediaCacheModels.getBySha256('w'))!;
        await isar.mediaCacheModels.put(row..mime = 'application/octet-stream');
      });

      expect((await repo.search(oneHot(0))).single.kind, DocumentKind.docx,
          reason: 'the kind is what was indexed, not what the last sender '
              'claimed');
    });

    test('several chunks of one document are all returned', () async {
      await seedChunk('s', 0, 'a');
      await seedChunk('s', 1, 'b');
      await repo.upsert(chunkIdOf('s', 0), oneHot(0));
      await repo.upsert(chunkIdOf('s', 1),
          List<double>.generate(embeddingsDimensions, (i) => i < 2 ? 1.0 : 0.0));

      expect(await repo.search(oneHot(0), minScore: 0.0), hasLength(2));
    });

    test('results come back ordered by similarity', () async {
      await seedChunk('s', 0, 'close');
      await seedChunk('s', 1, 'near');
      final near = List<double>.generate(
          embeddingsDimensions, (i) => i == 0 ? 1.0 : (i == 1 ? 0.5 : 0.0));
      await repo.upsert(chunkIdOf('s', 0), oneHot(0));
      await repo.upsert(chunkIdOf('s', 1), near);

      final hits = await repo.search(oneHot(0), topK: 5);

      expect(hits.map((h) => h.chunkId), ['s:0', 's:1']);
    });

    test('hits below minScore are dropped', () async {
      await seedChunk('s', 0, 'unrelated');
      await repo.upsert(chunkIdOf('s', 0), oneHot(0));

      expect(await repo.search(oneHot(7)), isEmpty);
    });

    test('topK caps the number of results', () async {
      for (var i = 0; i < 4; i++) {
        await seedChunk('s', i, 'chunk $i');
        await repo.upsert(chunkIdOf('s', i), oneHot(0));
      }

      expect(await repo.search(oneHot(0), topK: 2), hasLength(2));
    });

    test('a hit whose chunk row is gone is skipped, not an error', () async {
      await repo.upsert(chunkIdOf('ghost', 0), oneHot(0));

      expect(await repo.search(oneHot(0)), isEmpty);
    });
  });

  group('purged chunks', () {
    test('a chunk whose Isar row is deleted stops being returned', () async {
      await seedChunk('s', 0, 'gone soon');
      await repo.upsert(chunkIdOf('s', 0), oneHot(0));
      expect(await repo.search(oneHot(0)), hasLength(1));

      await isar.writeTxn(() =>
          isar.documentChunkModels.where().sha256EqualToAnyOrdinal('s').deleteAll());

      expect(await repo.search(oneHot(0)), isEmpty);
    });

    test('orphans ranking below a real chunk do not hide it', () async {
      // Orphans point elsewhere in the vector space, which is the realistic
      // case: a purged document is not semantically closer to the query than
      // the document that answers it.
      for (var i = 0; i < 12; i++) {
        await repo.upsert(chunkIdOf('orphan', i), oneHot(5));
      }
      await seedChunk('real', 0, 'the surviving chunk');
      await repo.upsert(chunkIdOf('real', 0), oneHot(0));

      final hits = await repo.search(oneHot(0), topK: 3);

      expect(hits.map((h) => h.content), ['the surviving chunk']);
    });

    test('known limit: enough equally-similar orphans can crowd out a real '
        'chunk until the store is rebuilt', () async {
      for (var i = 0; i < 40; i++) {
        await repo.upsert(chunkIdOf('orphan', i), oneHot(0));
      }
      await seedChunk('real', 0, 'the surviving chunk');
      await repo.upsert(chunkIdOf('real', 0), oneHot(0));

      // Documents the current behaviour rather than endorsing it — see
      // DocumentVectorRepository on why vectors cannot be deleted.
      expect(await repo.search(oneHot(0), topK: 3), isEmpty);
      // 41 flushed upserts (~70 ms each) can pass 30 s under full-suite load.
    }, timeout: const Timeout(Duration(minutes: 2)));
  });

  group('persistence', () {
    test('vectors survive closing and reopening the store', () async {
      await seedChunk('s', 0, 'durable');
      await repo.upsert(chunkIdOf('s', 0), oneHot(0));

      await store.close();
      store = await ToStore.open(
        dbPath: dir.path,
        schemas: [documentChunkEmbeddingsSchema],
      );
      repo = TostoreDocumentVectorRepositoryImpl(store, isar);

      final hits = await repo.search(oneHot(0));
      expect(hits.single.content, 'durable');
    });
  });

  // ── Edge cases ──────────────────────────────────────────────────────────

  group('degenerate input', () {
    test('upserting an empty vector is a no-op', () async {
      await repo.upsert('s:0', const []);

      expect(await repo.search(oneHot(0)), isEmpty);
    });

    test('an empty query returns nothing', () async {
      await seedChunk('s', 0, 'x');
      await repo.upsert(chunkIdOf('s', 0), oneHot(0));

      expect(await repo.search(const []), isEmpty);
    });

    test('re-upserting the same id replaces rather than duplicates', () async {
      await seedChunk('s', 0, 'x');
      await repo.upsert(chunkIdOf('s', 0), oneHot(0));
      await repo.upsert(chunkIdOf('s', 0), oneHot(0));

      expect(await repo.search(oneHot(0), topK: 5), hasLength(1));
    });
  });
}
