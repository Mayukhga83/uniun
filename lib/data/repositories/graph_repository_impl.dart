import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/data/models/graph_edge_model.dart';
import 'package:uniun/data/models/graph_node_model.dart';
import 'package:uniun/domain/entities/graph_edge/graph_edge_entity.dart';
import 'package:uniun/domain/entities/graph_node/graph_node_entity.dart';
import 'package:uniun/domain/repositories/graph_repository.dart';

@Injectable(as: GraphRepository)
class GraphRepositoryImpl extends GraphRepository {
  final Isar isar;
  GraphRepositoryImpl({required this.isar});

  @override
  Future<Either<Failure, Unit>> upsertNode(GraphNodeEntity node) async {
    try {
      await isar.writeTxn(() async {
        final existing = await isar.graphNodeModels
            .where()
            .keyEqualTo(node.key)
            .findFirst();
        if (existing != null) {
          existing
            ..name = node.name
            ..type = node.type
            ..updatedAt = node.updatedAt;
          await isar.graphNodeModels.put(existing);
        } else {
          final model = GraphNodeModel()
            ..key = node.key
            ..name = node.name
            ..type = node.type
            ..createdAt = node.createdAt
            ..updatedAt = node.updatedAt;
          await isar.graphNodeModels.put(model);
        }
      });
      return const Right(unit);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> upsertEdge(GraphEdgeEntity edge) async {
    try {
      await isar.writeTxn(() async {
        // Dedup: same (source, target, relation, sourceNote) doesn't duplicate.
        final existing = await isar.graphEdgeModels
            .filter()
            .sourceKeyEqualTo(edge.sourceKey)
            .targetKeyEqualTo(edge.targetKey)
            .relationTypeEqualTo(edge.relationType)
            .sourceNoteIdEqualTo(edge.sourceNoteId)
            .findFirst();
        if (existing != null) return;
        final model = GraphEdgeModel()
          ..sourceKey = edge.sourceKey
          ..targetKey = edge.targetKey
          ..relationType = edge.relationType
          ..sourceNoteId = edge.sourceNoteId
          ..createdAt = edge.createdAt;
        await isar.graphEdgeModels.put(model);
      });
      return const Right(unit);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<GraphEdgeEntity>>> getNeighbours(
    List<String> keys, {
    int maxHops = 1,
    int limit = 8,
  }) async {
    try {
      if (keys.isEmpty) return const Right([]);
      final results = <GraphEdgeModel>{};
      for (final k in keys) {
        if (results.length >= limit) break;
        final outgoing = await isar.graphEdgeModels
            .filter()
            .sourceKeyEqualTo(k)
            .limit(limit)
            .findAll();
        results.addAll(outgoing);
        if (results.length >= limit) break;
        final incoming = await isar.graphEdgeModels
            .filter()
            .targetKeyEqualTo(k)
            .limit(limit)
            .findAll();
        results.addAll(incoming);
      }
      final edges = results.take(limit).map((m) => m.toDomain()).toList();
      return Right(edges);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<GraphEdgeEntity>>> getEdgesForNote(
    String noteId,
  ) async {
    try {
      final rows = await isar.graphEdgeModels
          .filter()
          .sourceNoteIdEqualTo(noteId)
          .findAll();
      return Right(rows.map((m) => m.toDomain()).toList());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<GraphNodeEntity>>> getNodesByKeys(
    List<String> keys,
  ) async {
    try {
      if (keys.isEmpty) return const Right([]);
      final rows = await isar.graphNodeModels
          .filter()
          .anyOf(keys, (q, k) => q.keyEqualTo(k))
          .findAll();
      return Right(rows.map((m) => m.toDomain()).toList());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteForNote(String noteId) async {
    try {
      await isar.writeTxn(() async {
        final rows = await isar.graphEdgeModels
            .filter()
            .sourceNoteIdEqualTo(noteId)
            .findAll();
        for (final r in rows) {
          await isar.graphEdgeModels.delete(r.id);
        }
      });
      return const Right(unit);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }
}
