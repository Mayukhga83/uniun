import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/data/models/documents/document_chunk_model.dart';
import 'package:uniun/data/models/documents/document_index_model.dart';
import 'package:uniun/data/models/media/media_cache_model.dart';
import 'package:uniun/data/models/notes/media_attachment.dart';
import 'package:uniun/data/models/notes/note_model.dart';
import 'package:uniun/data/models/saved_note_model.dart';
import 'package:uniun/domain/entities/shiv/document_citation.dart';
import 'package:uniun/domain/entities/shiv/scored_chunk.dart';
import 'package:uniun/domain/repositories/document_source_repository.dart';

@Injectable(as: DocumentSourceRepository)
class DocumentSourceRepositoryImpl implements DocumentSourceRepository {
  DocumentSourceRepositoryImpl(this.isar);

  final Isar isar;

  @override
  Future<Either<Failure, List<DocumentCitation>>> resolve(
      List<String> chunkIds) async {
    try {
      // One title lookup per distinct document, not per chunk — several chunks
      // of the same document are the common case.
      final titles = <String, String?>{};
      final out = <DocumentCitation>[];

      for (final id in chunkIds) {
        final ref = parseChunkId(id);
        if (ref == null) continue;

        final chunk = await isar.documentChunkModels
            .where()
            .sha256OrdinalEqualTo(ref.sha256, ref.ordinal)
            .findFirst();
        if (chunk == null) continue;

        final file = await isar.mediaCacheModels
            .filter()
            .sha256EqualTo(ref.sha256)
            .findFirst();
        // No cached file means nothing to open — drop rather than offer a
        // citation that cannot be verified.
        if (file == null) continue;
        // The kind recorded at index time, not the cache mime, which a later
        // download can overwrite. No index row means mid-purge: drop it.
        final kind = (await isar.documentIndexModels.getBySha256(ref.sha256))
            ?.kind;
        if (kind == null) continue;

        out.add(DocumentCitation(
          chunkId: id,
          sha256: ref.sha256,
          kind: kind,
          label: chunk.label,
          snippet: chunk.text,
          localPath: file.localPath,
          title: titles[ref.sha256] ??= await _titleFor(ref.sha256),
        ));
      }
      return Right(out);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  /// The filename a note attached this blob under.
  ///
  /// Scans `attachments` (unindexed), which is acceptable here: it runs once
  /// per distinct document, on sheet open, for a handful of documents.
  Future<String?> _titleFor(String sha) async {
    final note = await isar.noteModels
        .filter()
        .attachmentsElement((a) => a.sha256EqualTo(sha))
        .findFirst();
    final fromNote =
        note?.attachments.where((a) => a.sha256 == sha).firstOrNull?.filename;
    if (fromNote != null && fromNote.isNotEmpty) return fromNote;

    // A saved note keeps its own copy of the imeta, so it can still name the
    // document after the live note has been evicted.
    final saved = await isar.savedNoteModels
        .filter()
        .attachmentsElement((a) => a.sha256EqualTo(sha))
        .findFirst();
    final fromSaved =
        saved?.attachments.where((a) => a.sha256 == sha).firstOrNull?.filename;
    return (fromSaved != null && fromSaved.isNotEmpty) ? fromSaved : null;
  }
}
