import 'package:isar_community/isar.dart';
import 'package:uniun/domain/entities/memory_node/memory_node_entity.dart';

part 'memory_node_model.g.dart';

/// Wiki-style structured memory for a single note. One row per note.
/// Built at save time by [ExtractKnowledgeUseCase] via a one-shot Gemma call.
@Collection(ignore: {'copyWith'})
@Name('MemoryNode')
class MemoryNodeModel {
  Id id = Isar.autoIncrement;

  /// Either SavedNoteModel.eventId or NoteModel.eventId (own authored notes).
  @Index(unique: true)
  late String noteId;

  late String summary;
  late List<String> keyPoints;
  late List<String> concepts;
  late List<String> linkedNoteIds;
  late DateTime updatedAt;
}

extension MemoryNodeModelExtension on MemoryNodeModel {
  MemoryNodeEntity toDomain() => MemoryNodeEntity(
        noteId: noteId,
        summary: summary,
        keyPoints: keyPoints,
        concepts: concepts,
        linkedNoteIds: linkedNoteIds,
        updatedAt: updatedAt,
      );
}
