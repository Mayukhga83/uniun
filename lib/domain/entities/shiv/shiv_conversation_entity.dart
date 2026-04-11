import 'package:freezed_annotation/freezed_annotation.dart';

part 'shiv_conversation_entity.freezed.dart';

@freezed
abstract class ShivConversationEntity with _$ShivConversationEntity {
  const factory ShivConversationEntity({
    required String conversationId,
    required String title,
    /// The messageId of the current leaf node (last message in active branch).
    /// null = conversation has no messages yet.
    String? activeLeafMessageId,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ShivConversationEntity;
}
