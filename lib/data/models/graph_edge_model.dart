import 'package:isar_community/isar.dart';
import 'package:uniun/domain/entities/graph_edge/graph_edge_entity.dart';

part 'graph_edge_model.g.dart';

/// Relation between two [GraphNodeModel]s, asserted by a specific source note.
/// Tracked per-note so we can clean up when a note is unsaved.
@Collection(ignore: {'copyWith'})
@Name('GraphEdge')
class GraphEdgeModel {
  Id id = Isar.autoIncrement;

  @Index(composite: [CompositeIndex('relationType')])
  late String sourceKey;

  @Index()
  late String targetKey;

  /// Freeform relation label: "uses" | "depends_on" | "part_of" | ...
  late String relationType;

  /// Event ID of the note that asserted this edge. Lets us delete all
  /// edges for a note when the note is unsaved.
  @Index()
  late String sourceNoteId;

  late DateTime createdAt;
}

extension GraphEdgeModelExtension on GraphEdgeModel {
  GraphEdgeEntity toDomain() => GraphEdgeEntity(
        sourceKey: sourceKey,
        targetKey: targetKey,
        relationType: relationType,
        sourceNoteId: sourceNoteId,
        createdAt: createdAt,
      );
}
