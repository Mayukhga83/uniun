import 'package:isar_community/isar.dart';
import 'package:uniun/core/enum/note_type.dart';
import 'package:uniun/domain/entities/saved_note/saved_note_entity.dart';

part 'saved_note_model.g.dart';

@Collection(ignore: {'copyWith'})
@Name('SavedNote')
class SavedNoteModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String eventId;

  late String sig;
  late String authorPubkey;
  late String content;

  @Enumerated(EnumType.name)
  late NoteType type;

  late List<String> eTagRefs;

  @Index()
  String? rootEventId;

  @Index()
  String? replyToEventId;

  late List<String> pTagRefs;
  late List<String> tTags;

  late DateTime created;

  @Index()
  late DateTime savedAt;

  /// 384-dim L2-normalised float vector from all-MiniLM-L6-v2.
  /// Null until [EmbeddingService] processes this note in the background.
  List<double>? embedding;
}

extension SavedNoteModelExtension on SavedNoteModel {
  SavedNoteEntity toDomain() => SavedNoteEntity(
        eventId: eventId,
        sig: sig,
        authorPubkey: authorPubkey,
        content: content,
        type: type,
        eTagRefs: eTagRefs,
        pTagRefs: pTagRefs,
        tTags: tTags,
        created: created,
        savedAt: savedAt,
        embedding: embedding,
      );
}
