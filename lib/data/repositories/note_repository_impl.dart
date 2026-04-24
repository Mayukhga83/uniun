import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/data/models/notes/note_model.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/domain/repositories/note_repository.dart';

@Injectable(as: NoteRepository)
class NoteRepositoryImpl extends NoteRepository {
  final Isar isar;

  NoteRepositoryImpl({required this.isar});

  @override
  Future<Either<Failure, List<NoteEntity>>> getFeed({
    required int limit,
    DateTime? before,
  }) async {
    try {
      // Feed shows every note — top-level posts, replies, and references.
      // Replies and refs are also notes; they belong in the stream.
      final notes = before != null
          ? await isar.noteModels
                .filter()
                .createdLessThan(before)
                .sortByCreatedDesc()
                .limit(limit)
                .findAll()
          : await isar.noteModels
                .where()
                .sortByCreatedDesc()
                .limit(limit)
                .findAll();

      await _backfillReplyCountsIfNeeded(notes);
      return Right(notes.map((n) => n.toDomain()).toList());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  /// One-time lazy migration: for notes created before cachedReplyCount was
  /// added, compute the count from existing Isar records and persist it.
  /// After the first run each note has the correct count and this is a no-op.
  Future<void> _backfillReplyCountsIfNeeded(List<NoteModel> models) async {
    final toUpdate = <NoteModel>[];
    for (final m in models) {
      // Total notes that have m in their eTagRefs.
      final totalEtag = await isar.noteModels
          .filter()
          .eTagRefsElementEqualTo(m.eventId)
          .count();
      // Subtract nested-thread replies: notes where m is the root but
      // replyToEventId points elsewhere (they are NOT direct replies to m).
      final nestedOnly = await isar.noteModels
          .filter()
          .rootEventIdEqualTo(m.eventId)
          .not()
          .replyToEventIdEqualTo(m.eventId)
          .replyToEventIdIsNotNull()
          .count();
      final count = totalEtag - nestedOnly;
      if (count != m.cachedReplyCount) {
        m.cachedReplyCount = count;
        toUpdate.add(m);
      }
    }
    if (toUpdate.isEmpty) return;
    await isar.writeTxn(() async {
      for (final m in toUpdate) {
        await isar.noteModels.put(m);
      }
    });
  }

  @override
  Future<Either<Failure, NoteEntity>> getNoteById(String eventId) async {
    try {
      final note = await isar.noteModels
          .where()
          .eventIdEqualTo(eventId)
          .findFirst();
      if (note == null) {
        return const Left(Failure.errorFailure('Note not found'));
      }
      return Right(note.toDomain());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<NoteEntity>>> getReplies(String eventId) async {
    try {
      // NIP-10 replies: this event is the immediate parent.
      final byReplyTo = await isar.noteModels
          .filter()
          .replyToEventIdEqualTo(eventId)
          .sortByCreated()
          .findAll();

      // Root-only e-tag children (["e", root, "", "root"]) where
      // replyToEventId stays null — must appear in the root's reply list too.
      final rootTagOnly = await isar.noteModels
          .filter()
          .rootEventIdEqualTo(eventId)
          .replyToEventIdIsNull()
          .sortByCreated()
          .findAll();

      // Incoming eTagRef mentions: notes whose eTagRefs list contains this
      // event, but which are not already NIP-10 reply/root children.
      final mentions = await isar.noteModels
          .filter()
          .eTagRefsElementEqualTo(eventId)
          .not()
          .replyToEventIdEqualTo(eventId)
          .not()
          .rootEventIdEqualTo(eventId)
          .sortByCreated()
          .findAll();

      final byEventId = <String, NoteModel>{};
      for (final n in [...byReplyTo, ...rootTagOnly, ...mentions]) {
        if (n.eventId != eventId) byEventId[n.eventId] = n;
      }

      final merged = byEventId.values.toList()
        ..sort((a, b) => a.created.compareTo(b.created));
      return Right(merged.map((n) => n.toDomain()).toList());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<NoteEntity>>> getThread(
    String rootEventId,
  ) async {
    try {
      // Root note
      final root = await isar.noteModels
          .where()
          .eventIdEqualTo(rootEventId)
          .findFirst();

      // All notes in the thread (rootEventId == rootEventId), chronological
      final replies = await isar.noteModels
          .filter()
          .rootEventIdEqualTo(rootEventId)
          .sortByCreated()
          .findAll();

      final all = [if (root != null) root, ...replies];

      return Right(all.map((n) => n.toDomain()).toList());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, NoteEntity>> saveNote(NoteEntity note) async {
    try {
      final existing = await isar.noteModels
          .where()
          .eventIdEqualTo(note.id)
          .findFirst();

      if (existing != null) {
        return Right(existing.toDomain());
      }

      final model = NoteModel(
        eventId: note.id,
        sig: note.sig,
        authorPubkey: note.authorPubkey,
        content: note.content,
        subject: note.subject,
        type: note.type,
        eTagRefs: note.eTagRefs,
        rootEventId: note.rootEventId,
        replyToEventId: note.replyToEventId,
        pTagRefs: note.pTagRefs,
        tTags: note.tTags,
        created: note.created,
        isSeen: note.isSeen,
      );

      await isar.writeTxn(() async {
        await isar.noteModels.put(model);
        // Increment the direct parent and any mention-references.
        // Explicitly exclude the root-tag ref when it differs from the reply
        // target — that avoids double-counting nested thread replies on the
        // thread root (e.g. n4→n3 inside n1's thread must NOT increment n1).
        final toIncrement = <String>{};
        if (note.replyToEventId != null) {
          toIncrement.add(note.replyToEventId!);
        }
        for (final ref in note.eTagRefs) {
          if (ref != note.rootEventId && ref != note.replyToEventId) {
            toIncrement.add(ref); // pure mention / reference
          }
        }
        for (final refId in toIncrement) {
          final ref = await isar.noteModels
              .where()
              .eventIdEqualTo(refId)
              .findFirst();
          if (ref != null) {
            ref.cachedReplyCount++;
            await isar.noteModels.put(ref);
          }
        }
      });

      return Right(model.toDomain());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getReplyCount(String eventId) async {
    try {
      final replyIds = await isar.noteModels
          .filter()
          .replyToEventIdEqualTo(eventId)
          .eventIdProperty()
          .findAll();

      final rootTagOnlyIds = await isar.noteModels
          .filter()
          .rootEventIdEqualTo(eventId)
          .replyToEventIdIsNull()
          .eventIdProperty()
          .findAll();

      final unique = {...replyIds, ...rootTagOnlyIds}..remove(eventId);
      return Right(unique.length);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getThreadReplyCount(String rootEventId) async {
    try {
      final count = await isar.noteModels
          .filter()
          .rootEventIdEqualTo(rootEventId)
          .count();
      return Right(count);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> markAsSeen(String eventId) async {
    try {
      await isar.writeTxn(() async {
        final note = await isar.noteModels
            .where()
            .eventIdEqualTo(eventId)
            .findFirst();
        if (note != null) {
          note.isSeen = true;
          await isar.noteModels.put(note);
        }
      });
      return const Right(unit);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<NoteEntity>>> getOwnNotes(
    String pubkeyHex,
  ) async {
    try {
      final notes = await isar.noteModels
          .filter()
          .authorPubkeyEqualTo(pubkeyHex)
          .sortByCreatedDesc()
          .findAll();
      return Right(notes.map((m) => m.toDomain()).toList());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<NoteEntity>>> searchNotes(String query) async {
    try {
      if (query.trim().isEmpty) return const Right([]);
      final results = await isar.noteModels
          .filter()
          .contentContains(query.trim(), caseSensitive: false)
          .sortByCreatedDesc()
          .limit(30)
          .findAll();
      return Right(results.map((m) => m.toDomain()).toList());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

}
