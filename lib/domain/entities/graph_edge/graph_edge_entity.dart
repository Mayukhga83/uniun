import 'package:freezed_annotation/freezed_annotation.dart';

part 'graph_edge_entity.freezed.dart';

@freezed
abstract class GraphEdgeEntity with _$GraphEdgeEntity {
  const factory GraphEdgeEntity({
    required String sourceKey,
    required String targetKey,
    required String relationType,
    required String sourceNoteId,
    required DateTime createdAt,
  }) = _GraphEdgeEntity;
}
