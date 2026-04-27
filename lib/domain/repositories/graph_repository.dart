import 'package:dartz/dartz.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/domain/entities/graph_edge/graph_edge_entity.dart';
import 'package:uniun/domain/entities/graph_node/graph_node_entity.dart';

abstract class GraphRepository {
  /// Idempotent upsert by normalised [GraphNodeEntity.key].
  Future<Either<Failure, Unit>> upsertNode(GraphNodeEntity node);

  /// Append-only: asserting the same edge again from a different note creates
  /// a new row (edge weight = row count). Edges are scoped by sourceNoteId so
  /// cleanup on unsave removes only that note's assertions.
  Future<Either<Failure, Unit>> upsertEdge(GraphEdgeEntity edge);

  /// 1-hop neighbours: edges whose sourceKey is in [keys] OR whose targetKey
  /// is in [keys]. Returns up to [limit] unique edges.
  Future<Either<Failure, List<GraphEdgeEntity>>> getNeighbours(
    List<String> keys, {
    int maxHops = 1,
    int limit = 8,
  });

  /// All edges asserted by a given source note. Used for cleanup.
  Future<Either<Failure, List<GraphEdgeEntity>>> getEdgesForNote(String noteId);

  /// Fetch nodes by their normalised keys.
  Future<Either<Failure, List<GraphNodeEntity>>> getNodesByKeys(
    List<String> keys,
  );

  /// Removes all edges asserted by this note. Nodes are kept (they may still
  /// be referenced by other notes).
  Future<Either<Failure, Unit>> deleteForNote(String noteId);
}
