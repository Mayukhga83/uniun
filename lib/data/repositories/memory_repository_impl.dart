import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/data/models/memory_node_model.dart';
import 'package:uniun/domain/entities/memory_node/memory_node_entity.dart';
import 'package:uniun/domain/repositories/memory_repository.dart';

@Injectable(as: MemoryRepository)
class MemoryRepositoryImpl extends MemoryRepository {
  final Isar isar;
  MemoryRepositoryImpl({required this.isar});

  @override
  Future<Either<Failure, Unit>> upsert(MemoryNodeEntity memory) async {
    try {
      await isar.writeTxn(() async {
        final existing = await isar.memoryNodeModels
            .where()
            .noteIdEqualTo(memory.noteId)
            .findFirst();
        if (existing != null) {
          existing
            ..summary = memory.summary
            ..keyPoints = List<String>.from(memory.keyPoints)
            ..concepts = List<String>.from(memory.concepts)
            ..linkedNoteIds = List<String>.from(memory.linkedNoteIds)
            ..updatedAt = memory.updatedAt;
          await isar.memoryNodeModels.put(existing);
        } else {
          final model = MemoryNodeModel()
            ..noteId = memory.noteId
            ..summary = memory.summary
            ..keyPoints = List<String>.from(memory.keyPoints)
            ..concepts = List<String>.from(memory.concepts)
            ..linkedNoteIds = List<String>.from(memory.linkedNoteIds)
            ..updatedAt = memory.updatedAt;
          await isar.memoryNodeModels.put(model);
        }
      });
      return const Right(unit);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MemoryNodeEntity?>> getByNoteId(String noteId) async {
    try {
      final row = await isar.memoryNodeModels
          .where()
          .noteIdEqualTo(noteId)
          .findFirst();
      return Right(row?.toDomain());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<MemoryNodeEntity>>> getByNoteIds(
    List<String> noteIds,
  ) async {
    try {
      if (noteIds.isEmpty) return const Right([]);
      final rows = await isar.memoryNodeModels
          .filter()
          .anyOf(noteIds, (q, id) => q.noteIdEqualTo(id))
          .findAll();
      return Right(rows.map((m) => m.toDomain()).toList());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteByNoteId(String noteId) async {
    try {
      await isar.writeTxn(() async {
        final row = await isar.memoryNodeModels
            .where()
            .noteIdEqualTo(noteId)
            .findFirst();
        if (row != null) await isar.memoryNodeModels.delete(row.id);
      });
      return const Right(unit);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }
}
