import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/core/usecases/usecase.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/domain/inputs/note_input.dart';
import 'package:uniun/domain/repositories/event_queue_repository.dart';
import 'package:uniun/domain/repositories/note_repository.dart';

// ── GetFeedUseCase ────────────────────────────────────────────────────────────

@lazySingleton
class GetFeedUseCase
    extends UseCase<Either<Failure, List<NoteEntity>>, GetFeedInput> {
  final NoteRepository repository;
  const GetFeedUseCase(this.repository);

  @override
  Future<Either<Failure, List<NoteEntity>>> call(
    GetFeedInput input, {
    bool cached = false,
  }) {
    return repository.getFeed(limit: input.limit, before: input.before);
  }
}

// ── GetNoteByIdUseCase ────────────────────────────────────────────────────────

@lazySingleton
class GetNoteByIdUseCase extends UseCase<Either<Failure, NoteEntity>, String> {
  final NoteRepository repository;
  const GetNoteByIdUseCase(this.repository);

  @override
  Future<Either<Failure, NoteEntity>> call(
    String eventId, {
    bool cached = false,
  }) {
    return repository.getNoteById(eventId);
  }
}

// ── GetRepliesUseCase ─────────────────────────────────────────────────────────

@lazySingleton
class GetRepliesUseCase
    extends UseCase<Either<Failure, List<NoteEntity>>, String> {
  final NoteRepository repository;
  const GetRepliesUseCase(this.repository);

  @override
  Future<Either<Failure, List<NoteEntity>>> call(
    String eventId, {
    bool cached = false,
  }) {
    return repository.getReplies(eventId);
  }
}

// ── SaveNoteUseCase ───────────────────────────────────────────────────────────

@lazySingleton
class SaveNoteUseCase extends UseCase<Either<Failure, NoteEntity>, NoteEntity> {
  final NoteRepository repository;
  const SaveNoteUseCase(this.repository);

  @override
  Future<Either<Failure, NoteEntity>> call(
    NoteEntity note, {
    bool cached = false,
  }) {
    return repository.saveNote(note);
  }
}

// ── MarkSeenUseCase ───────────────────────────────────────────────────────────

@lazySingleton
class MarkSeenUseCase extends UseCase<Either<Failure, Unit>, String> {
  final NoteRepository repository;
  const MarkSeenUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(String eventId, {bool cached = false}) {
    return repository.markAsSeen(eventId);
  }
}

// ── GetThreadUseCase ──────────────────────────────────────────────────────────

/// Returns the full thread for a given root note event ID.
/// Result: [root note, ...all replies sorted chronologically]
@lazySingleton
class GetThreadUseCase
    extends UseCase<Either<Failure, List<NoteEntity>>, String> {
  final NoteRepository repository;
  const GetThreadUseCase(this.repository);

  @override
  Future<Either<Failure, List<NoteEntity>>> call(
    String rootEventId, {
    bool cached = false,
  }) {
    return repository.getThread(rootEventId);
  }
}

// ── GetReplyCountUseCase ──────────────────────────────────────────────────────

/// Count of direct replies to a note (replyToEventId == eventId).
@lazySingleton
class GetReplyCountUseCase extends UseCase<Either<Failure, int>, String> {
  final NoteRepository _repository;
  const GetReplyCountUseCase(this._repository);

  @override
  Future<Either<Failure, int>> call(String eventId, {bool cached = false}) {
    return _repository.getReplyCount(eventId);
  }
}

// ── GetThreadReplyCountUseCase ────────────────────────────────────────────────

/// Count of all notes in a thread (rootEventId == rootEventId).
@lazySingleton
class GetThreadReplyCountUseCase extends UseCase<Either<Failure, int>, String> {
  final NoteRepository _repository;
  const GetThreadReplyCountUseCase(this._repository);

  @override
  Future<Either<Failure, int>> call(String rootEventId, {bool cached = false}) {
    return _repository.getThreadReplyCount(rootEventId);
  }
}

// ── GetOwnNotesUseCase ────────────────────────────────────────────────────────

/// All notes authored by this user stored locally.
/// Used by the RAG pipeline for baseline personalisation.
@lazySingleton
class GetOwnNotesUseCase
    extends UseCase<Either<Failure, List<NoteEntity>>, String> {
  final NoteRepository _repository;
  const GetOwnNotesUseCase(this._repository);

  @override
  Future<Either<Failure, List<NoteEntity>>> call(
    String pubkeyHex, {
    bool cached = false,
  }) {
    return _repository.getOwnNotes(pubkeyHex);
  }
}

// ── SearchNotesUseCase ────────────────────────────────────────────────────────

/// Case-insensitive substring search over locally stored note content.
/// Used by Brahma's mention picker — returns up to 30 matches newest-first.
@lazySingleton
class SearchNotesUseCase
    extends UseCase<Either<Failure, List<NoteEntity>>, String> {
  final NoteRepository _repository;
  const SearchNotesUseCase(this._repository);

  @override
  Future<Either<Failure, List<NoteEntity>>> call(
    String query, {
    bool cached = false,
  }) {
    return _repository.searchNotes(query);
  }
}

// ── PublishNoteUseCase ────────────────────────────────────────────────────────

/// Publishes a fully signed NoteEntity.
///
/// Input: a [NoteEntity] with id, sig, and all threading fields already set.
///        Signing happens in BrahmaCreateBloc before this is called.
///
/// Steps:
///   1. Save to local Isar via [NoteRepository.saveNote] — note appears in
///      the feed immediately (optimistic local display).
///   2. Enqueue in [EventQueueRepository] — the Gateway isolate's WebSocketService
///      watches EventQueueModel via Isar.watchLazy() and sends immediately.
///      No explicit ping is needed — Isar fires the watcher automatically.
@lazySingleton
class PublishNoteUseCase
    extends UseCase<Either<Failure, NoteEntity>, NoteEntity> {
  final NoteRepository _noteRepository;
  final EventQueueRepository _eventQueueRepository;

  const PublishNoteUseCase(
    this._noteRepository,
    this._eventQueueRepository,
  );

  @override
  Future<Either<Failure, NoteEntity>> call(
    NoteEntity note, {
    bool cached = false,
  }) async {
    // 1. Save locally first so the note appears in feed immediately.
    final saveResult = await _noteRepository.saveNote(note);
    if (saveResult.isLeft()) return saveResult;

    // 2. Enqueue for relay broadcast — Gateway's WebSocketService watches
    //    EventQueueModel via Isar.watchLazy() and fires immediately.
    final enqueueResult = await _eventQueueRepository.enqueueSignedEvent(
      eventId: note.id,
      authorPubkey: note.authorPubkey,
      sig: note.sig,
      kind: 1,
      eTagRefs: note.eTagRefs,
      rootEventId: note.rootEventId,
      replyToEventId: note.replyToEventId,
      pTagRefs: note.pTagRefs,
      tTags: note.tTags,
      content: note.content,
      created: note.created,
    );

    if (enqueueResult.isLeft()) {
      return Left(
        enqueueResult.fold(
          (f) => f,
          (_) => const Failure.errorFailure('enqueue failed'),
        ),
      );
    }

    return saveResult;
  }
}

