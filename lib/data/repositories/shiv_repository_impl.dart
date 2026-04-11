import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/data/models/shiv_conversation_model.dart';
import 'package:uniun/data/models/shiv_message_model.dart';
import 'package:uniun/domain/entities/shiv/shiv_conversation_entity.dart';
import 'package:uniun/domain/entities/shiv/shiv_message_entity.dart';
import 'package:uniun/domain/repositories/shiv_repository.dart';
import 'package:uuid/uuid.dart';

@Injectable(as: ShivRepository)
class ShivRepositoryImpl implements ShivRepository {
  final Isar _isar;

  ShivRepositoryImpl(this._isar);

  @override
  Future<Either<Failure, List<ShivConversationEntity>>> getConversations() async {
    try {
      final rows = await _isar.shivConversationModels
          .where()
          .sortByCreatedAtDesc()
          .findAll();
      return Right(rows.map((r) => r.toDomain()).toList());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ShivConversationEntity>> createConversation(
      String title) async {
    try {
      final now = DateTime.now();
      final model = ShivConversationModel()
        ..conversationId = const Uuid().v4()
        ..title = title
        ..activeLeafMessageId = null
        ..createdAt = now
        ..updatedAt = now;

      await _isar.writeTxn(() async {
        await _isar.shivConversationModels.put(model);
      });

      return Right(model.toDomain());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateConversationTitle(
      String conversationId, String title) async {
    try {
      await _isar.writeTxn(() async {
        final row = await _isar.shivConversationModels
            .filter()
            .conversationIdEqualTo(conversationId)
            .findFirst();
        if (row != null) {
          row.title = title;
          row.updatedAt = DateTime.now();
          await _isar.shivConversationModels.put(row);
        }
      });
      return const Right(unit);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateActiveLeaf(
      String conversationId, String messageId) async {
    try {
      await _isar.writeTxn(() async {
        final row = await _isar.shivConversationModels
            .filter()
            .conversationIdEqualTo(conversationId)
            .findFirst();
        if (row != null) {
          row.activeLeafMessageId = messageId;
          row.updatedAt = DateTime.now();
          await _isar.shivConversationModels.put(row);
        }
      });
      return const Right(unit);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteConversation(
      String conversationId) async {
    try {
      await _isar.writeTxn(() async {
        final messages = await _isar.shivMessageModels
            .filter()
            .conversationIdEqualTo(conversationId)
            .findAll();
        await _isar.shivMessageModels.deleteAll(messages.map((m) => m.id).toList());

        final row = await _isar.shivConversationModels
            .filter()
            .conversationIdEqualTo(conversationId)
            .findFirst();
        if (row != null) {
          await _isar.shivConversationModels.delete(row.id);
        }
      });
      return const Right(unit);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ShivMessageEntity>>> getMessages(
      String conversationId) async {
    try {
      final rows = await _isar.shivMessageModels
          .filter()
          .conversationIdEqualTo(conversationId)
          .sortByCreatedAt()
          .findAll();
      return Right(rows.map((r) => r.toDomain()).toList());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ShivMessageEntity>> saveMessage(
      ShivMessageEntity message) async {
    try {
      final model = ShivMessageModel()
        ..messageId = message.messageId
        ..conversationId = message.conversationId
        ..parentId = message.parentId
        ..role = message.role
        ..content = message.content
        ..createdAt = message.createdAt;

      await _isar.writeTxn(() async {
        await _isar.shivMessageModels.put(model);
        // Advance the leaf pointer and touch updatedAt on the conversation
        final conv = await _isar.shivConversationModels
            .filter()
            .conversationIdEqualTo(message.conversationId)
            .findFirst();
        if (conv != null) {
          conv.activeLeafMessageId = message.messageId;
          conv.updatedAt = DateTime.now();
          await _isar.shivConversationModels.put(conv);
        }
      });

      return Right(model.toDomain());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateMessageContent(
      String messageId, String content) async {
    try {
      await _isar.writeTxn(() async {
        final row = await _isar.shivMessageModels
            .filter()
            .messageIdEqualTo(messageId)
            .findFirst();
        if (row != null) {
          row.content = content;
          await _isar.shivMessageModels.put(row);
        }
      });
      return const Right(unit);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }
}
