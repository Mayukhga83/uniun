import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:uniun/core/enum/document_kind.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/core/usecases/usecase.dart';
import 'package:uniun/domain/entities/shiv/document_citation.dart';
import 'package:uniun/domain/repositories/document_source_repository.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/domain/entities/saved_note/saved_note_entity.dart';
import 'package:uniun/domain/repositories/note_resolver_repository.dart';
import 'package:uniun/domain/repositories/saved_note_repository.dart';
import 'package:uniun/domain/usecases/knowledge_usecases.dart';
import 'package:uniun/domain/usecases/media_usecases.dart';

// ── SaveNoteUseCase ───────────────────────────────────────────────────────────

@lazySingleton
class SaveNoteUseCase extends UseCase<Either<Failure, SavedNoteEntity>, NoteEntity> {
  final SavedNoteRepository _repository;
  final DownloadMediaUseCase _download;
  const SaveNoteUseCase(this._repository, this._download);

  @override
  Future<Either<Failure, SavedNoteEntity>> call(
    NoteEntity input, {
    bool cached = false,
  }) async {
    final result = await _repository.saveNote(input);
    // Fire-and-forget: the save is done, and the UI must not wait on a file.
    if (result.isRight()) unawaited(_fetchDocuments(input));
    return result;
  }

  /// Saving is what puts a note's documents in front of Shiv, but a document
  /// the user never opened is not on the device yet — the indexer only reads
  /// cached files. Best-effort: offline, it is fetched when next opened.
  Future<void> _fetchDocuments(NoteEntity note) async {
    for (final a in note.attachments) {
      if (a.localPath != null || a.serverUrls.isEmpty) continue;
      if (DocumentKind.fromMime(a.mime) == null) continue;
      await _download.call(DownloadMediaInput(
        sha256: a.sha256,
        url: a.serverUrls.first,
        mime: a.mime,
      ));
    }
  }
}

// ── UnsaveNoteUseCase ─────────────────────────────────────────────────────────

@lazySingleton
class UnsaveNoteUseCase extends UseCase<Either<Failure, Unit>, String> {
  final SavedNoteRepository _repository;
  final DeleteKnowledgeForNoteUseCase _deleteKnowledge;
  const UnsaveNoteUseCase(this._repository, this._deleteKnowledge);

  @override
  Future<Either<Failure, Unit>> call(String eventId, {bool cached = false}) async {
    final result = await _repository.unsaveNote(eventId);
    // Fire-and-forget knowledge cleanup — graph edges + memory row for this
    // note are removed so the AI knowledge layer doesn't hold orphan entries.
    // Own-authored notes are never unsaved (no UnsaveNoteUseCase path), so
    // their knowledge persists — matches Feed Freedom.
    unawaited(_deleteKnowledge.call(eventId));
    return result;
  }
}

// ── IsSavedNoteUseCase ────────────────────────────────────────────────────────

@lazySingleton
class IsSavedNoteUseCase extends UseCase<Either<Failure, bool>, String> {
  final SavedNoteRepository _repository;
  const IsSavedNoteUseCase(this._repository);

  @override
  Future<Either<Failure, bool>> call(String eventId, {bool cached = false}) {
    return _repository.isSaved(eventId);
  }
}

// ── GetAllSavedNotesUseCase ───────────────────────────────────────────────────

@lazySingleton
class GetAllSavedNotesUseCase
    extends NoParamsUseCase<Either<Failure, List<SavedNoteEntity>>> {
  final SavedNoteRepository _repository;
  const GetAllSavedNotesUseCase(this._repository);

  @override
  Future<Either<Failure, List<SavedNoteEntity>>> call() {
    return _repository.getAll();
  }
}

@lazySingleton
class GetSavedReplyCountUseCase extends UseCase<Either<Failure, int>, String> {
  final SavedNoteRepository _repository;
  const GetSavedReplyCountUseCase(this._repository);

  @override
  Future<Either<Failure, int>> call(String eventId, {bool cached = false}) =>
      _repository.getSavedReplyCount(eventId);
}

// ── GetSavedRepliesUseCase ────────────────────────────────────────────────────

@lazySingleton
class GetSavedRepliesUseCase
    extends UseCase<Either<Failure, List<SavedNoteEntity>>, String> {
  final SavedNoteRepository _repository;
  const GetSavedRepliesUseCase(this._repository);

  @override
  Future<Either<Failure, List<SavedNoteEntity>>> call(
    String parentId, {
    bool cached = false,
  }) =>
      _repository.getSavedReplies(parentId);
}

// ── GetSavedReferencesUseCase ─────────────────────────────────────────────────

@lazySingleton
class GetSavedReferencesUseCase
    extends UseCase<Either<Failure, List<SavedNoteEntity>>, String> {
  final SavedNoteRepository _repository;
  const GetSavedReferencesUseCase(this._repository);

  @override
  Future<Either<Failure, List<SavedNoteEntity>>> call(
    String childId, {
    bool cached = false,
  }) =>
      _repository.getSavedReferences(childId);
}

// ── ResolveNotesByIdsUseCase ──────────────────────────────────────────────────

/// Resolves a list of note event ids into full [NoteEntity]s for display
/// (used by Shiv's "Sources" sheet). Resolution order:
///   1. The unified `Note` collection ([NoteResolverRepository.resolveMany]) —
///      covers own notes (kept forever) and not-yet-evicted regular notes.
///   2. Fallback to [SavedNoteRepository.getAll] for any id missing from (1):
///      saved copies are retained forever even after the `Note` row is evicted.
/// Output preserves the input order (score-desc from the RAG pipeline) and
/// drops ids that resolve nowhere. Degrades to partial/empty, never fails the
/// sheet. The `getAll()` scan runs only when something is missing.
@lazySingleton
class ResolveNotesByIdsUseCase
    extends UseCase<Either<Failure, List<NoteEntity>>, List<String>> {
  final NoteResolverRepository _resolver;
  final SavedNoteRepository _saved;
  const ResolveNotesByIdsUseCase(this._resolver, this._saved);

  @override
  Future<Either<Failure, List<NoteEntity>>> call(
    List<String> ids, {
    bool cached = false,
  }) async {
    if (ids.isEmpty) return const Right([]);

    final resolved = await _resolver.resolveMany(ids);
    final byId = <String, NoteEntity>{};
    resolved.fold((_) {}, (notes) {
      for (final n in notes) {
        byId[n.id] = n;
      }
    });

    final missing = ids.where((id) => !byId.containsKey(id)).toList();
    if (missing.isNotEmpty) {
      final allSaved = await _saved.getAll();
      allSaved.fold((_) {}, (saved) {
        final savedById = {for (final s in saved) s.eventId: s};
        for (final id in missing) {
          final s = savedById[id];
          if (s != null) byId[id] = s.toNoteEntity();
        }
      });
    }

    // Preserve the input (score-desc) order; drop unresolved ids.
    final ordered = [
      for (final id in ids)
        if (byId[id] != null) byId[id]!,
    ];
    return Right(ordered);
  }
}

/// Resolves the chunk ids of a reply into displayable citations.
@lazySingleton
class ResolveDocumentCitationsUseCase
    extends UseCase<Either<Failure, List<DocumentCitation>>, List<String>> {
  const ResolveDocumentCitationsUseCase(this._repository);

  final DocumentSourceRepository _repository;

  @override
  Future<Either<Failure, List<DocumentCitation>>> call(
    List<String> input, {
    bool cached = false,
  }) =>
      _repository.resolve(input);
}
