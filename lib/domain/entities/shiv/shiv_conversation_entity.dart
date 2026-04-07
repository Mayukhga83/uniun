import 'package:freezed_annotation/freezed_annotation.dart';

part 'shiv_conversation_entity.freezed.dart';

@freezed
abstract class ShivConversationEntity with _$ShivConversationEntity {
  const factory ShivConversationEntity({
    required String conversationId,
    required String title,
    required String activeBranchId,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ShivConversationEntity;
}
