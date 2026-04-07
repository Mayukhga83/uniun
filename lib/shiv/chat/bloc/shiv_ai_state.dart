part of 'shiv_ai_bloc.dart';

enum ShivChatStatus {
  /// Conversation list is loading or ready (no chat open).
  idle,

  /// A conversation is open and idle (waiting for user input).
  chatIdle,

  /// AI is generating a response (streaming tokens).
  streaming,

  /// Terminal error (model missing / inference crash).
  error,
}

@freezed
abstract class ShivAIState with _$ShivAIState {
  const factory ShivAIState({
    @Default(ShivChatStatus.idle) ShivChatStatus status,
    @Default([]) List<ShivConversationEntity> conversations,
    ShivConversationEntity? activeConversation,
    @Default([]) List<ShivMessageEntity> messages,

    /// The streaming assistant message being built token-by-token.
    /// Non-null only while [status] == [ShivChatStatus.streaming].
    String? streamingContent,

    /// The messageId of the placeholder assistant message being streamed.
    String? streamingMessageId,

    String? errorMessage,
  }) = _ShivAIState;
}
