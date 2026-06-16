import 'package:isar_community/isar.dart';
import 'package:uniun/core/utils/fast_hash.dart';
import 'package:uniun/domain/entities/dm/dm_conversation_entity.dart';

part 'dm_conversation_model.g.dart';

@Collection(ignore: {'copyWith'})
@Name('DmConversation')
class DmConversationModel {
  /// The counterparty pubkey IS the natural key. Isar primary keys must be `int`,
  /// so the id is a deterministic hash of [otherPubkey] — identical on every
  /// device, which lets conversations (and the `conversationId` FK on DM notes)
  /// reconcile across devices without remapping. `replace: true` makes a put
  /// upsert by pubkey.
  Id get id => fastHash(otherPubkey);

  @Index(unique: true, replace: true)
  late String otherPubkey;

  List<String> relays = [];
}

extension DmConversationModelExtension on DmConversationModel {
  DmConversationEntity toDomain() => DmConversationEntity(
    id: id,
    otherPubkey: otherPubkey,
    relays: relays,
  );
}
