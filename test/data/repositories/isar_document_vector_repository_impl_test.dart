import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/core/enum/document_kind.dart';
import 'package:uniun/data/models/documents/document_chunk_model.dart';
import 'package:uniun/data/models/documents/document_index_model.dart';
import 'package:uniun/data/models/media/media_cache_model.dart';
import 'package:uniun/data/repositories/isar_document_vector_repository_impl.dart';
import 'package:uniun/domain/entities/shiv/scored_chunk.dart';

import '../../_helpers/fixtures.dart';
import '../../_helpers/isar_seeds.dart';
import '../../_helpers/isar_test_harness.dart';

/// Covers: chunk vector upsert onto Isar rows and exact search — text, label
/// and kind resolution, score ordering and filtering, every stored chunk being
/// reachable, purging removing vectors, and degenerate input.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const dims = 1024;
  late Isar isar;
  late IsarDocumentVectorRepositoryImpl repo;

  List<double> oneHot(int k) =>
      List<double>.generate(dims, (i) => i == k ? 1.0 : 0.0);

  /// A chunk row plus its cached file and index row, as the indexer leaves
  /// them (the vector comes later, from [repo.upsert]).
  Future<void> seedChunk(
    String sha,
    int ordinal,
    String text, {
    String label = '1',
    DocumentKind kind = DocumentKind.pdf,
  }) => isar.writeTxn(() async {
    if (await isar.mediaCacheModels.getBySha256(sha) == null) {
      await isar.mediaCacheModels.put(mediaCacheRow(sha, mime: kind.mime));
      await isar.documentIndexModels.put(
        DocumentIndexModel()
          ..sha256 = sha
          ..kind = kind
          ..status = DocumentIndexStatus.indexed
          ..indexedAt = tNow,
      );
    }
    await isar.documentChunkModels.put(
      DocumentChunkModel()
        ..sha256 = sha
        ..ordinal = ordinal
        ..label = label
        ..text = text,
    );
  });

  setUp(() async {
    isar = await openTestIsar();
    repo = IsarDocumentVectorRepositoryImpl(isar);
  });

  tearDown(() => isar.close(deleteFromDisk: true));

  group('search', () {
    test(
      'a stored chunk is found by an identical query, with text and page',
      () async {
        await seedChunk('s', 0, 'leave policy text', label: '4');
        await repo.upsert(chunkIdOf('s', 0), oneHot(0));

        final hits = await repo.search(oneHot(0));

        expect(hits, hasLength(1));
        expect(hits.single.chunkId, 's:0');
        expect(hits.single.sha256, 's');
        expect(hits.single.label, '4');
        expect(hits.single.content, 'leave policy text');
        expect(hits.single.score, closeTo(1.0, 0.0001));
      },
    );

    test(
      'every one of many stored chunks finds itself',
      () async {
        // The approximate index this replaced reached 20 of 83 chunks on a phone.
        const n = 200;
        for (var i = 0; i < n; i++) {
          await seedChunk('s', i, 'chunk $i');
          await repo.upsert(chunkIdOf('s', i), oneHot(i));
        }

        var found = 0;
        for (var i = 0; i < n; i++) {
          final hit = (await repo.search(oneHot(i), topK: 1)).single;
          if (hit.chunkId == chunkIdOf('s', i)) found++;
        }

        expect(found, n);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test('a DOCX chunk comes back with its kind and heading label', () async {
      await seedChunk(
        'w',
        0,
        'annual leave text',
        label: 'Annual Leave',
        kind: DocumentKind.docx,
      );
      await repo.upsert(chunkIdOf('w', 0), oneHot(0));

      final hit = (await repo.search(oneHot(0))).single;

      expect(hit.kind, DocumentKind.docx);
      expect(hit.label, 'Annual Leave');
    });

    test('a hit whose document is no longer indexed is dropped', () async {
      await seedChunk('s', 0, 'x');
      await repo.upsert(chunkIdOf('s', 0), oneHot(0));
      await isar.writeTxn(() => isar.documentIndexModels.deleteBySha256('s'));

      expect(await repo.search(oneHot(0)), isEmpty);
    });

    test(
      'a re-download that rewrites the cached mime keeps the kind',
      () async {
        await seedChunk('w', 0, 'x', label: 'Scope', kind: DocumentKind.docx);
        await repo.upsert(chunkIdOf('w', 0), oneHot(0));
        await isar.writeTxn(() async {
          final row = (await isar.mediaCacheModels.getBySha256('w'))!;
          await isar.mediaCacheModels.put(
            row..mime = 'application/octet-stream',
          );
        });

        expect(
          (await repo.search(oneHot(0))).single.kind,
          DocumentKind.docx,
          reason:
              'the kind is what was indexed, not what the last sender '
              'claimed',
        );
      },
    );

    test(
      'results come back ordered by similarity, whatever the storage order',
      () async {
        // Stored worst-first, so a scan in row order would return them reversed.
        await seedChunk('s', 0, 'far');
        await seedChunk('s', 1, 'near');
        await seedChunk('s', 2, 'close');
        final near = List<double>.generate(
          dims,
          (i) => i == 0 ? 1.0 : (i == 1 ? 0.5 : 0.0),
        );
        await repo.upsert(chunkIdOf('s', 0), oneHot(9));
        await repo.upsert(chunkIdOf('s', 1), near);
        await repo.upsert(chunkIdOf('s', 2), oneHot(0));

        final hits = await repo.search(oneHot(0), topK: 5, minScore: 0.0);

        expect(hits.map((h) => h.chunkId), ['s:2', 's:1', 's:0']);
      },
    );

    test('hits below minScore are dropped', () async {
      await seedChunk('s', 0, 'unrelated');
      await repo.upsert(chunkIdOf('s', 0), oneHot(0));

      expect(await repo.search(oneHot(7)), isEmpty);
    });

    test('topK caps the number of results, keeping the best', () async {
      for (var i = 0; i < 6; i++) {
        await seedChunk('s', i, 'chunk $i');
        await repo.upsert(
          chunkIdOf('s', i),
          List<double>.generate(
            dims,
            (k) => k == 0 ? 1.0 : (k == 1 ? i * 0.3 : 0.0),
          ),
        );
      }

      final hits = await repo.search(oneHot(0), topK: 2);

      expect(hits.map((h) => h.chunkId), ['s:0', 's:1']);
    });

    test('a chunk with no vector yet is never returned', () async {
      await seedChunk('s', 0, 'still being embedded');

      expect(await repo.search(oneHot(0), minScore: -1), isEmpty);
    });

    test(
      'chunks across several documents compete on similarity alone',
      () async {
        await seedChunk('a', 0, 'in a');
        await seedChunk('b', 0, 'in b');
        await repo.upsert(chunkIdOf('a', 0), oneHot(3));
        await repo.upsert(chunkIdOf('b', 0), oneHot(4));

        expect((await repo.search(oneHot(4), topK: 1)).single.sha256, 'b');
      },
    );
  });

  group('purged chunks', () {
    test('deleting a document\'s chunk rows removes its vectors too', () async {
      await seedChunk('s', 0, 'gone soon');
      await repo.upsert(chunkIdOf('s', 0), oneHot(0));
      expect(await repo.search(oneHot(0)), hasLength(1));

      await isar.writeTxn(
        () => isar.documentChunkModels
            .where()
            .sha256EqualToAnyOrdinal('s')
            .deleteAll(),
      );

      expect(await repo.search(oneHot(0), minScore: -1), isEmpty);
    });

    test('an upsert for a purged chunk is a no-op, not an error', () async {
      await repo.upsert(chunkIdOf('ghost', 0), oneHot(0));

      expect(await isar.documentChunkModels.count(), 0);
    });
  });

  // ── Edge cases ──────────────────────────────────────────────────────────

  group('degenerate input', () {
    test('upserting an empty vector leaves the row without one', () async {
      await seedChunk('s', 0, 'x');
      await repo.upsert(chunkIdOf('s', 0), const []);

      expect(await repo.search(oneHot(0), minScore: -1), isEmpty);
    });

    test('a malformed chunk id is ignored', () async {
      await seedChunk('s', 0, 'x');
      await repo.upsert('not-a-chunk-id', oneHot(0));

      expect(await repo.search(oneHot(0), minScore: -1), isEmpty);
    });

    test('an empty or all-zero query returns nothing', () async {
      await seedChunk('s', 0, 'x');
      await repo.upsert(chunkIdOf('s', 0), oneHot(0));

      expect(await repo.search(const []), isEmpty);
      expect(await repo.search(List<double>.filled(dims, 0)), isEmpty);
    });

    test('a topK of zero returns nothing', () async {
      await seedChunk('s', 0, 'x');
      await repo.upsert(chunkIdOf('s', 0), oneHot(0));

      expect(await repo.search(oneHot(0), topK: 0), isEmpty);
    });

    test('a stored vector of another dimension is skipped', () async {
      await seedChunk('s', 0, 'old model');
      await repo.upsert(chunkIdOf('s', 0), [1.0, 0.0, 0.0]);
      await seedChunk('s', 1, 'current model');
      await repo.upsert(chunkIdOf('s', 1), oneHot(0));

      final hits = await repo.search(oneHot(0), minScore: -1, topK: 5);

      expect(hits.map((h) => h.chunkId), ['s:1']);
    });

    test('re-upserting the same id replaces rather than duplicates', () async {
      await seedChunk('s', 0, 'x');
      await repo.upsert(chunkIdOf('s', 0), oneHot(0));
      await repo.upsert(chunkIdOf('s', 0), oneHot(5));

      expect(
        await repo.search(oneHot(0), topK: 5),
        isEmpty,
        reason: 'the old vector is gone',
      );
      expect(await repo.search(oneHot(5), topK: 5), hasLength(1));
    });

    test(
      'a library larger than one read batch is searched in full',
      () async {
        const n = 900;
        await isar.writeTxn(() async {
          await isar.mediaCacheModels.put(mediaCacheRow('big'));
          await isar.documentIndexModels.put(
            DocumentIndexModel()
              ..sha256 = 'big'
              ..kind = DocumentKind.pdf
              ..status = DocumentIndexStatus.indexed
              ..indexedAt = tNow,
          );
          for (var i = 0; i < n; i++) {
            await isar.documentChunkModels.put(
              DocumentChunkModel()
                ..sha256 = 'big'
                ..ordinal = i
                ..label = '1'
                ..text = 'chunk $i'
                ..vector = oneHot(i % dims),
            );
          }
        });

        final hit = (await repo.search(oneHot(850), topK: 1)).single;

        expect(hit.chunkId, 'big:850');
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });
}
