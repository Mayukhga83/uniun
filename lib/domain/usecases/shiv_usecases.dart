import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/core/usecases/usecase.dart';
import 'package:uniun/domain/entities/shiv/shiv_conversation_entity.dart';
import 'package:uniun/domain/entities/shiv/shiv_message_entity.dart';
import 'package:uniun/domain/repositories/shiv_repository.dart';

@lazySingleton
class GetConversationsUseCase
    extends NoParamsUseCase<Either<Failure, List<ShivConversationEntity>>> {
  final ShivRepository _repository;
  const GetConversationsUseCase(this._repository);

  @override
  Future<Either<Failure, List<ShivConversationEntity>>> call() {
    return _repository.getConversations();
  }
}

@lazySingleton
class CreateConversationUseCase
    extends UseCase<Either<Failure, ShivConversationEntity>, String> {
  final ShivRepository _repository;
  const CreateConversationUseCase(this._repository);

  @override
  Future<Either<Failure, ShivConversationEntity>> call(String input,
      {bool cached = false}) {
    return _repository.createConversation(input);
  }
}

@lazySingleton
class DeleteConversationUseCase
    extends UseCase<Either<Failure, Unit>, String> {
  final ShivRepository _repository;
  const DeleteConversationUseCase(this._repository);

  @override
  Future<Either<Failure, Unit>> call(String input, {bool cached = false}) {
    return _repository.deleteConversation(input);
  }
}

@lazySingleton
class GetMessagesUseCase
    extends UseCase<Either<Failure, List<ShivMessageEntity>>, String> {
  final ShivRepository _repository;
  const GetMessagesUseCase(this._repository);

  @override
  Future<Either<Failure, List<ShivMessageEntity>>> call(String input,
      {bool cached = false}) {
    return _repository.getMessages(input);
  }
}

@lazySingleton
class SaveMessageUseCase
    extends UseCase<Either<Failure, ShivMessageEntity>, ShivMessageEntity> {
  final ShivRepository _repository;
  const SaveMessageUseCase(this._repository);

  @override
  Future<Either<Failure, ShivMessageEntity>> call(ShivMessageEntity input,
      {bool cached = false}) {
    return _repository.saveMessage(input);
  }
}

@lazySingleton
class UpdateMessageContentUseCase
    extends UseCase<Either<Failure, Unit>, (String messageId, String content)> {
  final ShivRepository _repository;
  const UpdateMessageContentUseCase(this._repository);

  @override
  Future<Either<Failure, Unit>> call((String, String) input,
      {bool cached = false}) {
    return _repository.updateMessageContent(input.$1, input.$2);
  }
}

@lazySingleton
class UpdateActiveBranchUseCase
    extends UseCase<Either<Failure, Unit>,
        (String conversationId, String branchId)> {
  final ShivRepository _repository;
  const UpdateActiveBranchUseCase(this._repository);

  @override
  Future<Either<Failure, Unit>> call((String, String) input,
      {bool cached = false}) {
    return _repository.updateActiveBranch(input.$1, input.$2);
  }
}
