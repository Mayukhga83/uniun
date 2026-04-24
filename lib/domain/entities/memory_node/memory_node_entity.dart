import 'package:freezed_annotation/freezed_annotation.dart';

part 'memory_node_entity.freezed.dart';

@freezed
abstract class MemoryNodeEntity with _$MemoryNodeEntity {
  const factory MemoryNodeEntity({
    required String noteId,
    required String summary,
    required List<String> keyPoints,
    required List<String> concepts,
    required List<String> linkedNoteIds,
    required DateTime updatedAt,
  }) = _MemoryNodeEntity;
}
