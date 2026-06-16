import 'package:dartz/dartz.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/domain/entities/surrounding/surrounding_note_entity.dart';

/// Read side of the ephemeral "Surrounding" feed (notes received from nearby
/// strangers over the mesh). Ordered by `receivedAt` (arrival time on this
/// device), not author time. Writes/eviction happen in the mesh layer.
abstract class SurroundingNoteRepository {
  /// Older page: notes with receivedAt < [before] (newest overall if null),
  /// returned oldest→newest, capped at [limit].
  ///
  /// Note: a note sharing the exact same `receivedAt` millisecond as the page
  /// boundary can be skipped by the strict `<` cursor — an accepted tradeoff at
  /// v1 mesh volumes (wall-clock-ms collisions between peers are rare).
  Future<Either<Failure, List<SurroundingNoteEntity>>> getBefore({
    DateTime? before,
    required int limit,
  });

  /// Newer page: notes with receivedAt > [after] (>= if [inclusive]),
  /// returned oldest→newest, capped at [limit]. Callers paginate with
  /// [inclusive] = true + dedupe so same-millisecond ties are not skipped.
  Future<Either<Failure, List<SurroundingNoteEntity>>> getAfter({
    required DateTime after,
    bool inclusive = false,
    required int limit,
  });

  /// receivedAt of the oldest still-unread note (receivedAt > read watermark);
  /// null when everything is read or the cache is empty.
  Future<Either<Failure, DateTime?>> oldestUnreadReceivedAt();

  /// Advances the read watermark to max(current, [receivedAt]).
  Future<Either<Failure, Unit>> markReadUpTo(DateTime receivedAt);

  /// Fires whenever the surrounding cache changes (new arrivals / eviction).
  Stream<void> watch();

  /// Promotes a surrounding note into the forever-retained saved notes, so it
  /// survives the daily eviction. No-op if already saved or unknown.
  Future<Either<Failure, Unit>> promoteToSaved(String eventId);
}
