import 'package:dartz/dartz.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/domain/entities/shiv/shiv_conversation_entity.dart';
import 'package:uniun/domain/entities/shiv/shiv_message_entity.dart';

abstract class ShivRepository {
  Future<Either<Failure, List<ShivConversationEntity>>> getConversations();
  Future<Either<Failure, ShivConversationEntity>> createConversation(String title);
  Future<Either<Failure, Unit>> updateConversationTitle(String conversationId, String title);
  /// Updates the active leaf node for branch switching.
  Future<Either<Failure, Unit>> updateActiveLeaf(String conversationId, String messageId);
  Future<Either<Failure, Unit>> deleteConversation(String conversationId);
  Future<Either<Failure, List<ShivMessageEntity>>> getMessages(String conversationId);
  Future<Either<Failure, ShivMessageEntity>> saveMessage(ShivMessageEntity message);
  Future<Either<Failure, Unit>> updateMessageContent(String messageId, String content);
}
