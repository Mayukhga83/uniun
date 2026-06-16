import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/data/datasources/surrounding_read_state_store.dart';
import 'package:uniun/data/models/saved_note_model.dart';
import 'package:uniun/data/models/surrounding_note_model.dart';
import 'package:uniun/domain/entities/surrounding/surrounding_note_entity.dart';
import 'package:uniun/domain/repositories/surrounding_note_repository.dart';

@Injectable(as: SurroundingNoteRepository)
class SurroundingNoteRepositoryImpl extends SurroundingNoteRepository {
  final Isar isar;
  final SurroundingReadStateStore readStore;
  SurroundingNoteRepositoryImpl({required this.isar, required this.readStore});

  SurroundingNoteEntity _wrap(SurroundingNoteModel r) =>
      SurroundingNoteEntity(note: r.toDomain(), receivedAt: r.receivedAt);

  @override
  Future<Either<Failure, List<SurroundingNoteEntity>>> getBefore({
    DateTime? before,
    required int limit,
  }) async {
    try {
      final List<SurroundingNoteModel> rows;
      if (before == null) {
        rows = await isar.surroundingNoteModels
            .where()
            .sortByReceivedAtDesc()
            .limit(limit)
            .findAll();
      } else {
        rows = await isar.surroundingNoteModels
            .filter()
            .receivedAtLessThan(before)
            .sortByReceivedAtDesc()
            .limit(limit)
            .findAll();
      }
      // Query is newest-first; the feed renders oldest→newest.
      return Right(rows.reversed.map(_wrap).toList());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<SurroundingNoteEntity>>> getAfter({
    required DateTime after,
    bool inclusive = false,
    required int limit,
  }) async {
    try {
      final rows = await isar.surroundingNoteModels
          .filter()
          .receivedAtGreaterThan(after, include: inclusive)
          .sortByReceivedAt()
          .limit(limit)
          .findAll(); // oldest→newest
      return Right(rows.map(_wrap).toList());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DateTime?>> oldestUnreadReceivedAt() async {
    try {
      final watermark = readStore.lastReadReceivedAt;
      final row = await isar.surroundingNoteModels
          .filter()
          .receivedAtGreaterThan(watermark)
          .sortByReceivedAt()
          .findFirst();
      return Right(row?.receivedAt);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> markReadUpTo(DateTime receivedAt) async {
    try {
      await readStore.advanceTo(receivedAt);
      return const Right(unit);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Stream<void> watch() => isar.surroundingNoteModels.watchLazy();

  @override
  Future<Either<Failure, Unit>> promoteToSaved(String eventId) async {
    try {
      await isar.writeTxn(() async {
        final row = await isar.surroundingNoteModels
            .where()
            .eventIdEqualTo(eventId)
            .findFirst();
        if (row == null) return;
        final existing = await isar.savedNoteModels
            .where()
            .eventIdEqualTo(eventId)
            .findFirst();
        if (existing != null) return;
        await isar.savedNoteModels.put(SavedNoteModel()
          ..eventId = row.eventId
          ..sig = row.sig
          ..authorPubkey = row.authorPubkey
          ..content = row.content
          ..type = row.type
          ..eTagRefs = row.eTagRefs
          ..rootEventId = row.rootEventId
          ..replyToEventId = row.replyToEventId
          ..pTagRefs = row.pTagRefs
          ..tTags = row.tTags
          ..created = row.created
          ..savedAt = DateTime.now()
          ..quoteEventId = row.quoteEventId);
      });
      return const Right(unit);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }
}
