import 'package:isar_community/isar.dart';
import 'package:uniun/domain/entities/graph_node/graph_node_entity.dart';

part 'graph_node_model.g.dart';

/// Extracted entity in the AI knowledge graph. Created when
/// [ExtractKnowledgeUseCase] parses a note's LLM-extracted concepts.
@Collection(ignore: {'copyWith'})
@Name('GraphNode')
class GraphNodeModel {
  Id id = Isar.autoIncrement;

  /// Normalised lowercase key (e.g. "isar"). Unique identity for dedup.
  @Index(unique: true)
  late String key;

  /// Display name (e.g. "Isar").
  late String name;

  /// Freeform type label: "Database" | "Tech" | "Concept" | "Person" | ...
  late String type;

  late DateTime createdAt;
  late DateTime updatedAt;
}

extension GraphNodeModelExtension on GraphNodeModel {
  GraphNodeEntity toDomain() => GraphNodeEntity(
        key: key,
        name: name,
        type: type,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
