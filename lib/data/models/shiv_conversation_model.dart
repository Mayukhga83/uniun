import 'package:isar_community/isar.dart';
import 'package:uniun/domain/entities/shiv/shiv_conversation_entity.dart';

part 'shiv_conversation_model.g.dart';

@Collection(ignore: {'copyWith'})
@Name('ShivConversation')
class ShivConversationModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String conversationId;

  late String title;

  /// The messageId of the current leaf node (last message in active branch).
  /// null = conversation has no messages yet.
  /// Traversing up via parentId from this node gives the full branch.
  String? activeLeafMessageId;

  @Index()
  late DateTime createdAt;

  late DateTime updatedAt;
}

extension ShivConversationModelExtension on ShivConversationModel {
  ShivConversationEntity toDomain() => ShivConversationEntity(
        conversationId: conversationId,
        title: title,
        activeLeafMessageId: activeLeafMessageId,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
