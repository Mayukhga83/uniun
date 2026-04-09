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
  /// Traverse up via parentId to reconstruct the full branch.
  String? parentId;

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
        role: role,
        content: content,
        createdAt: createdAt,
      );
}
