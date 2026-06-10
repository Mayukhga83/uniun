import 'package:isar_community/isar.dart';
import 'package:uniun/domain/entities/draft/draft_entity.dart';

part 'draft_model.g.dart';

@Collection(ignore: {'copyWith'})
@Name('Draft')
class DraftModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String draftId; // UUID for draft identity

  late String content;

  String? rootEventId; // null = top-level draft
  String? replyToEventId; // null = top-level draft

  late List<String> eTagRefs; // reference graph edges
  late List<String> pTagRefs; // user mentions
  late List<String> tTags; // topics

  late DateTime createdAt;
  late DateTime updatedAt;

  /// `created_at` of the last NIP-37 Kind 31234 wrap we accepted for this
  /// draft. Used by the inbound handler for last-write-wins reconciliation.
  /// Null on rows created locally that haven't been seen back from the relay.
  DateTime? lastSyncedCreatedAt;

  /// Event id of that same wrap. Seeded into [DraftsSubscription.localIndex]
  /// so NIP-77 negentropy recognises drafts we already hold and the relay
  /// doesn't re-stream them on every reconnect.
  String? lastSyncedEventId;
}

extension DraftModelExtension on DraftModel {
  DraftEntity toDomain() => DraftEntity(
        draftId: draftId,
        content: content,
        rootEventId: rootEventId,
        replyToEventId: replyToEventId,
        eTagRefs: eTagRefs,
        pTagRefs: pTagRefs,
        tTags: tTags,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
