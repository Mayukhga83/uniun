import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/data/models/documents/document_chunk_model.dart';
import 'package:uniun/data/models/documents/document_index_model.dart';

import '../../../_helpers/isar_test_harness.dart';

/// Covers: unique-replace on (sha256, ordinal) and on the index row, delete-by-sha,
/// composite lookup, status round-trip, scale.
void main() {
  late Isar isar;

  setUp(() async => isar = await openTestIsar());
  tearDown(() => isar.close(deleteFromDisk: true));

  DocumentChunkModel chunk(String sha, int ordinal, String text,
          {String label = '1'}) =>
      DocumentChunkModel()
        ..sha256 = sha
        ..ordinal = ordinal
        ..label = label
        ..text = text;

  DocumentIndexModel index(String sha, DocumentIndexStatus status) =>
      DocumentIndexModel()
        ..sha256 = sha
        ..status = status
        ..pageCount = 3
        ..chunkCount = 5
        ..indexedAt = DateTime.utc(2026, 1, 1);

  group('DocumentChunkModel', () {
    test('putting the same (sha256, ordinal) replaces instead of duplicating',
        () async {
      await isar.writeTxn(() => isar.documentChunkModels.put(chunk('s', 0, 'old')));
      await isar.writeTxn(() => isar.documentChunkModels.put(chunk('s', 0, 'new')));

      final all = await isar.documentChunkModels.where().findAll();
      expect(all, hasLength(1));
      expect(all.single.text, 'new');
    });

    test('different ordinals of one sha coexist', () async {
      await isar.writeTxn(() => isar.documentChunkModels
          .putAll([chunk('s', 0, 'a'), chunk('s', 1, 'b')]));

      expect(await isar.documentChunkModels.count(), 2);
    });

    test('the same ordinal under different shas coexist', () async {
      await isar.writeTxn(() => isar.documentChunkModels
          .putAll([chunk('s1', 0, 'a'), chunk('s2', 0, 'b')]));

      expect(await isar.documentChunkModels.count(), 2);
    });

    test("deleting by sha removes only that document's chunks", () async {
      await isar.writeTxn(() => isar.documentChunkModels.putAll(
          [chunk('s1', 0, 'a'), chunk('s1', 1, 'b'), chunk('s2', 0, 'c')]));

      await isar.writeTxn(() => isar.documentChunkModels
          .where()
          .sha256EqualToAnyOrdinal('s1')
          .deleteAll());

      final left = await isar.documentChunkModels.where().findAll();
      expect(left.map((c) => c.sha256), ['s2']);
    });

    test('the composite lookup finds one chunk by (sha256, ordinal)', () async {
      await isar.writeTxn(() => isar.documentChunkModels
          .putAll([chunk('s', 0, 'a'), chunk('s', 1, 'b')]));

      final hit = await isar.documentChunkModels
          .where()
          .sha256OrdinalEqualTo('s', 1)
          .findFirst();

      expect(hit?.text, 'b');
    });

    test('a missing (sha256, ordinal) resolves to null', () async {
      expect(
        await isar.documentChunkModels
            .where()
            .sha256OrdinalEqualTo('nope', 9)
            .findFirst(),
        isNull,
      );
    });

    test('the page label round-trips', () async {
      await isar.writeTxn(
          () => isar.documentChunkModels.put(chunk('s', 0, 'x', label: '7')));

      expect((await isar.documentChunkModels.where().findFirst())?.label, '7');
    });
  });

  group('DocumentIndexModel', () {
    test('is unique per sha256 and round-trips its status', () async {
      await isar.writeTxn(() =>
          isar.documentIndexModels.put(index('s', DocumentIndexStatus.notSearchable)));
      await isar.writeTxn(
          () => isar.documentIndexModels.put(index('s', DocumentIndexStatus.indexed)));

      final all = await isar.documentIndexModels.where().findAll();
      expect(all, hasLength(1));
      expect(all.single.status, DocumentIndexStatus.indexed);
      expect(all.single.pageCount, 3);
      expect(all.single.chunkCount, 5);
    });

    test('deleting by sha removes the row', () async {
      await isar.writeTxn(
          () => isar.documentIndexModels.put(index('s', DocumentIndexStatus.indexed)));

      await isar.writeTxn(() => isar.documentIndexModels.deleteBySha256('s'));

      expect(await isar.documentIndexModels.count(), 0);
    });

    test('both statuses survive a round-trip', () async {
      for (final status in DocumentIndexStatus.values) {
        await isar.writeTxn(() => isar.documentIndexModels.put(index('s', status)));

        expect(
          (await isar.documentIndexModels.filter().sha256EqualTo('s').findFirst())
              ?.status,
          status,
        );
      }
    });
  });

  // ── Edge cases ──────────────────────────────────────────────────────────

  group('scale and content', () {
    test('a 200-chunk document stores and deletes as one unit', () async {
      final rows = [for (var i = 0; i < 200; i++) chunk('big', i, 'chunk $i')];
      await isar.writeTxn(() => isar.documentChunkModels.putAll(rows));

      expect(await isar.documentChunkModels.count(), 200);

      await isar.writeTxn(() => isar.documentChunkModels
          .where()
          .sha256EqualToAnyOrdinal('big')
          .deleteAll());

      expect(await isar.documentChunkModels.count(), 0);
    });

    test('unicode and emoji text round-trips byte-for-byte', () async {
      const text = 'भारत सरकार — policy 😀 مرحبا';
      await isar.writeTxn(
          () => isar.documentChunkModels.put(chunk('s', 0, text)));

      expect((await isar.documentChunkModels.where().findFirst())?.text, text);
    });
  });
}
