import 'package:isar_community/isar.dart';
import 'package:uniun/core/enum/message_role.dart';
import 'package:uniun/domain/entities/shiv/shiv_message_entity.dart';

part 'shiv_message_model.g.dart';

@Collection(ignore: {'copyWith'})
@Name('ShivMessage')
class ShivMessageModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String messageId;

  @Index()
  late String conversationId;

  /// The messageId of the previous message in this branch.
  /// null = this is the first message in the conversation (root).
  String? parentId;

  /// Groups messages that travel together on the same straight-line path.
  /// All messages from root up to a branch point share the same branchId
  /// as the branch they were originally created in.
  @Index()
  late String branchId;

  @Enumerated(EnumType.name)
  late MessageRole role;

  late String content;

  @Index()
  late DateTime createdAt;
}

extension ShivMessageModelExtension on ShivMessageModel {
  ShivMessageEntity toDomain() => ShivMessageEntity(
        messageId: messageId,
        conversationId: conversationId,
        parentId: parentId,
        branchId: branchId,
        role: role,
        content: content,
        createdAt: createdAt,
      );
}
