part of 'shiv_ai_bloc.dart';

@freezed
abstract class ShivAIEvent with _$ShivAIEvent {
  /// Load the conversation list on tab open.
  const factory ShivAIEvent.loadConversations() = _LoadConversations;

  /// Create a fresh conversation and open it.
  const factory ShivAIEvent.createConversation() = _CreateConversation;

  /// Open an existing conversation (loads its messages).
  const factory ShivAIEvent.openConversation(String conversationId) =
      _OpenConversation;

  /// Close the active conversation, return to list view.
  const factory ShivAIEvent.closeConversation() = _CloseConversation;

  /// Delete a conversation by id.
  const factory ShivAIEvent.deleteConversation(String conversationId) =
      _DeleteConversation;

  /// User submitted a message — triggers RAG + inference pipeline.
  const factory ShivAIEvent.sendMessage(String text) = _SendMessage;

  /// Internal: BLoC appends each streamed token.
  const factory ShivAIEvent.tokenReceived(String token) = _TokenReceived;

  /// Internal: BLoC signals streaming complete.
  const factory ShivAIEvent.streamDone() = _StreamDone;

  /// Internal: BLoC signals streaming error.
  const factory ShivAIEvent.streamError(String message) = _StreamError;
}
