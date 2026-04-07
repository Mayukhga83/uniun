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

  /// The branchId the user is currently viewing.
  /// Updated when user switches branches via the graph view.
  late String activeBranchId;

  @Index()
  late DateTime createdAt;

  late DateTime updatedAt;
}

extension ShivConversationModelExtension on ShivConversationModel {
  ShivConversationEntity toDomain() => ShivConversationEntity(
        conversationId: conversationId,
        title: title,
        activeBranchId: activeBranchId,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
