import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/core/usecases/usecase.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/domain/entities/saved_note/saved_note_entity.dart';
import 'package:uniun/domain/repositories/saved_note_repository.dart';
import 'package:uniun/domain/usecases/knowledge_usecases.dart';

// ── SaveNoteUseCase ───────────────────────────────────────────────────────────

@lazySingleton
class SaveNoteUseCase extends UseCase<Either<Failure, SavedNoteEntity>, NoteEntity> {
  final SavedNoteRepository _repository;
  const SaveNoteUseCase(this._repository);

  @override
  Future<Either<Failure, SavedNoteEntity>> call(
    NoteEntity input, {
    bool cached = false,
  }) {
    return _repository.saveNote(input);
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
