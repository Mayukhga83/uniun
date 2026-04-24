import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uniun/core/enum/note_type.dart';

part 'note_entity.freezed.dart';
part 'note_entity.g.dart';

@freezed
abstract class NoteEntity with _$NoteEntity {
  const factory NoteEntity({
    required String id,
    required String sig,
    required String authorPubkey,
    required String content,
    String? subject,
    required NoteType type,
    required List<String> eTagRefs,
    required List<String> pTagRefs,
    required List<String> tTags,
    required DateTime created,
    required bool isSeen,

    /// NIP-10 "root" marker — null means this IS a top-level note.
    String? rootEventId,

    /// NIP-10 "reply" marker — the direct parent note this replies to.
    String? replyToEventId,
    /// Denormalised reply count from NoteModel — updated by Gateway and saveNote.
    @Default(0) int cachedReplyCount,
  }) = _NoteEntity;

  factory NoteEntity.fromJson(Map<String, dynamic> json) =>
      _$NoteEntityFromJson(json);
}
