import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';

part 'surrounding_note_entity.freezed.dart';

/// A surrounding-feed item: the rendered [note] plus the local [receivedAt]
/// timestamp (when this device received it over the mesh). `receivedAt` drives
/// feed ordering, pagination cursors, and the read watermark — it is mesh
/// transport metadata that does not belong on the shared [NoteEntity].
@freezed
abstract class SurroundingNoteEntity with _$SurroundingNoteEntity {
  const factory SurroundingNoteEntity({
    required NoteEntity note,
    required DateTime receivedAt,
  }) = _SurroundingNoteEntity;
}
