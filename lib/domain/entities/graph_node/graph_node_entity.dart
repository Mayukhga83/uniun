import 'package:freezed_annotation/freezed_annotation.dart';

part 'graph_node_entity.freezed.dart';

@freezed
abstract class GraphNodeEntity with _$GraphNodeEntity {
  const factory GraphNodeEntity({
    required String key,
    required String name,
    required String type,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _GraphNodeEntity;
}
