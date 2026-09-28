import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/core/enum/document_kind.dart';
import 'package:uniun/data/models/documents/document_chunk_model.dart';
import 'package:uniun/data/models/documents/document_index_model.dart';
import 'package:uniun/data/models/media/media_cache_model.dart';
import 'package:uniun/data/models/notes/note_model.dart';
import 'package:uniun/data/models/saved_note_model.dart';
import 'package:uniun/data/repositories/document_source_repository_impl.dart';

import '../../_helpers/fixtures.dart';
import '../../_helpers/isar_seeds.dart';
import '../../_helpers/isar_test_harness.dart';

/// Covers: chunk-id resolution to citations with their document kind, title
/// lookup from the attaching note or saved copy, skipping unresolvable or
/// unclassifiable ids, order preservation.
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

  /// The cached file plus the index row the indexer writes for it.
  Future<void> seedFile(String sha,
          {String path = '/p/doc.pdf', DocumentKind kind = DocumentKind.pdf}) =>
      isar.writeTxn(() async {
        await isar.mediaCacheModels
            .put(mediaCacheRow(sha, localPath: path, mime: kind.mime));
        await isar.documentIndexModels.put(DocumentIndexModel()
          ..sha256 = sha
          ..kind = kind
          ..status = DocumentIndexStatus.indexed
          ..indexedAt = tNow);
      });

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
      expect(citation.kind, DocumentKind.pdf);
      expect(citation.label, '4');
      expect(citation.snippet, 'the leave policy');
      expect(citation.localPath, '/p/circular.pdf');
    });

    test('a DOCX chunk resolves with its kind and heading', () async {
      await seedChunk('w', 0, 'annual leave text', label: 'Annual Leave');
      await seedFile('w', path: '/p/policy.docx', kind: DocumentKind.docx);

      final citation = (await repo.resolve(['w:0'])).getOrElse(() => []).single;

      expect(citation.kind, DocumentKind.docx);
      expect(citation.label, 'Annual Leave');
      expect(citation.localPath, '/p/policy.docx');
    });

    test('a chunk with no heading keeps its empty label', () async {
      await seedChunk('w', 0, 'preamble', label: '');
      await seedFile('w', kind: DocumentKind.docx);

      expect((await repo.resolve(['w:0'])).getOrElse(() => []).single.label, '');
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

    test('a document with no index row (mid-purge)', () async {
      await seedChunk('s', 0, 'x');
      await seedFile('s');
      await isar.writeTxn(() => isar.documentIndexModels.deleteBySha256('s'));

      expect(await resolvedIds(['s:0']), isEmpty);
    });

    test('the kind comes from the index, not a since-rewritten cache mime',
        () async {
      await seedChunk('w', 0, 'x', label: 'Scope');
      await seedFile('w', kind: DocumentKind.docx);
      await isar.writeTxn(() async {
        final row = (await isar.mediaCacheModels.getBySha256('w'))!;
        await isar.mediaCacheModels.put(row..mime = 'application/pdf');
      });

      final c = (await repo.resolve(['w:0'])).getOrElse(() => []).single;
      expect(c.kind, DocumentKind.docx,
          reason: 'else "Scope" would render as "Page Scope"');
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
