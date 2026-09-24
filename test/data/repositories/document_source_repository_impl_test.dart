import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/data/models/documents/document_chunk_model.dart';
import 'package:uniun/data/models/media/media_cache_model.dart';
import 'package:uniun/data/models/notes/note_model.dart';
import 'package:uniun/data/models/saved_note_model.dart';
import 'package:uniun/data/repositories/document_source_repository_impl.dart';

import '../../_helpers/isar_seeds.dart';
import '../../_helpers/isar_test_harness.dart';

/// Covers: chunk-id resolution to citations, title lookup from the attaching
/// note or saved copy, skipping unresolvable ids, order preservation.
void main() {
  late Isar isar;
  late DocumentSourceRepositoryImpl repo;

  setUp(() async {
    isar = await openTestIsar();
    repo = DocumentSourceRepositoryImpl(isar);
  });

  tearDown(() => isar.close(deleteFromDisk: true));

  Future<void> seedChunk(String sha, int ordinal, String text,
          {String label = '1'}) =>
      isar.writeTxn(
        () => isar.documentChunkModels.put(DocumentChunkModel()
          ..sha256 = sha
          ..ordinal = ordinal
          ..label = label
          ..text = text),
      );

  Future<void> seedFile(String sha, {String path = '/p/doc.pdf'}) =>
      isar.writeTxn(() => isar.mediaCacheModels
          .put(mediaCacheRow(sha, localPath: path, mime: 'application/pdf')));

  Future<List<String>> resolvedIds(List<String> ids) async =>
      (await repo.resolve(ids))
          .getOrElse(() => [])
          .map((c) => c.chunkId)
          .toList();

  group('resolution', () {
    test('resolves a chunk to its page, snippet and cached file path',
        () async {
      await seedChunk('s', 0, 'the leave policy', label: '4');
      await seedFile('s', path: '/p/circular.pdf');

      final citation = (await repo.resolve(['s:0'])).getOrElse(() => []).single;

      expect(citation.chunkId, 's:0');
      expect(citation.sha256, 's');
      expect(citation.label, '4');
      expect(citation.snippet, 'the leave policy');
      expect(citation.localPath, '/p/circular.pdf');
    });

    test('order follows the requested ids', () async {
      await seedChunk('a', 0, 'first');
      await seedChunk('b', 0, 'second');
      await seedFile('a', path: '/p/a.pdf');
      await seedFile('b', path: '/p/b.pdf');

      expect(await resolvedIds(['b:0', 'a:0']), ['b:0', 'a:0']);
    });

    test('several chunks of one document all resolve', () async {
      await seedFile('s');
      for (var i = 0; i < 3; i++) {
        await seedChunk('s', i, 'chunk $i', label: '${i + 1}');
      }

      final out = (await repo.resolve(['s:0', 's:1', 's:2'])).getOrElse(() => []);

      expect(out.map((c) => c.label), ['1', '2', '3']);
    });
  });

  group('title', () {
    test('comes from the note that attaches the PDF', () async {
      await seedChunk('s', 0, 'x');
      await seedFile('s');
      await isar.writeTxn(() => isar.noteModels.put(noteRow('n1', attachments: [
            mediaAttachmentRow(
              sha256: 's',
              mime: 'application/pdf',
              filename: 'Leave Circular.pdf',
            )
          ])));

      expect((await repo.resolve(['s:0'])).getOrElse(() => []).single.title,
          'Leave Circular.pdf');
    });

    test('falls back to the saved copy once the live note is gone', () async {
      await seedChunk('s', 0, 'x');
      await seedFile('s');
      await isar.writeTxn(() => isar.savedNoteModels.put(savedNoteRow(
            'n1',
            attachments: [
              mediaAttachmentRow(
                sha256: 's',
                mime: 'application/pdf',
                filename: 'Saved Circular.pdf',
              )
            ],
          )));

      expect((await repo.resolve(['s:0'])).getOrElse(() => []).single.title,
          'Saved Circular.pdf');
    });

    test('is null when no note names the file', () async {
      await seedChunk('s', 0, 'x');
      await seedFile('s');

      expect((await repo.resolve(['s:0'])).getOrElse(() => []).single.title,
          isNull);
    });
  });

  // ── Edge cases ──────────────────────────────────────────────────────────

  group('unresolvable ids are skipped', () {
    test('a chunk row that is gone', () async {
      await seedFile('s');

      expect(await resolvedIds(['s:0']), isEmpty);
    });

    test('a file no longer cached', () async {
      await seedChunk('s', 0, 'x');

      expect(await resolvedIds(['s:0']), isEmpty);
    });

    test('malformed ids', () async {
      expect(await resolvedIds(['garbage', ':1', 's:x', '']), isEmpty);
    });

    test('an empty request resolves to an empty list', () async {
      expect(await resolvedIds(const []), isEmpty);
    });

    test('the resolvable ids survive alongside unresolvable ones', () async {
      await seedChunk('good', 0, 'kept');
      await seedFile('good');

      expect(await resolvedIds(['bad:0', 'good:0', 'garbage']), ['good:0']);
    });
  });
}
