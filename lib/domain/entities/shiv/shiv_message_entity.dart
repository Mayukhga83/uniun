import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uniun/core/enum/message_role.dart';

part 'shiv_message_entity.freezed.dart';

@freezed
abstract class ShivMessageEntity with _$ShivMessageEntity {
  const factory ShivMessageEntity({
    required String messageId,
    required String conversationId,
    String? parentId,
    required String branchId,
    required MessageRole role,
    required String content,
    required DateTime createdAt,
  }) = _ShivMessageEntity;
}
