import 'package:dartz/dartz.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/domain/entities/memory_node/memory_node_entity.dart';

abstract class MemoryRepository {
  /// Idempotent upsert keyed by [MemoryNodeEntity.noteId].
  Future<Either<Failure, Unit>> upsert(MemoryNodeEntity memory);

  Future<Either<Failure, MemoryNodeEntity?>> getByNoteId(String noteId);

  Future<Either<Failure, List<MemoryNodeEntity>>> getByNoteIds(
    List<String> noteIds,
  );

  Future<Either<Failure, Unit>> deleteByNoteId(String noteId);
}
