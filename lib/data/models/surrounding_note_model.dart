import 'package:isar_community/isar.dart';
import 'package:uniun/core/enum/note_type.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';

part 'surrounding_note_model.g.dart';

/// Ephemeral cache of Kind-1 notes received from nearby strangers over the mesh
/// ("Surrounding" feed). Kept OUT of the unified `Note` collection so it never
/// leaks into Vishnu/feed queries and so daily eviction is a single `deleteAll`.
/// Evicting this cache is not a `deleted` field — it does not violate Feed
/// Freedom (same category as the 7-day relay-note retention).
@Collection(ignore: {'copyWith'})
@Name('SurroundingNote')
class SurroundingNoteModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String eventId;

  late String sig;
  late String authorPubkey;
  late String content;

  @Enumerated(EnumType.name)
  late NoteType type;

  late List<String> eTagRefs;
  late List<String> pTagRefs;
  late List<String> tTags;

  String? rootEventId;
  String? replyToEventId;
  String? quoteEventId;

  /// Always 1 in v1 (only public feed notes are broadcast).
  late int kind;

  /// Author's `created_at` — feed ordering (newest first).
  @Index()
  late DateTime created;

  /// When this device received the note — drives daily eviction.
  @Index()
  late DateTime receivedAt;
}

extension SurroundingNoteModelExtension on SurroundingNoteModel {
  NoteEntity toDomain() => NoteEntity(
        id: eventId,
        sig: sig,
        authorPubkey: authorPubkey,
        content: content,
        kind: kind,
        type: type,
        eTagRefs: eTagRefs,
        pTagRefs: pTagRefs,
        tTags: tTags,
        created: created,
        rootEventId: rootEventId,
        replyToEventId: replyToEventId,
        quoteEventId: quoteEventId,
        // sourceLabel is the localized "Nearby" tag — injected at the
        // presentation layer (SurroundingFeedPage), since the data layer has no
        // AppLocalizations. See the repo l10n rule: no hardcoded UI strings.
      );
}
