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

    /// The streaming assistant message being built token-by-token, AS
    /// DISPLAYED — sanitized through [LlmTextSanitizer.clean] (GPT-2 byte
    /// runs decoded, UTF-8 mojibake repaired, `<think>` blocks stripped).
    /// The raw token concatenation lives on the bloc; this string is for
    /// rendering only. Non-null only while [status] ==
    /// [ShivChatStatus.streaming].
    String? streamingContent,

    /// The messageId of the placeholder assistant message being streamed.
    String? streamingMessageId,

    String? errorMessage,

    /// How many saved notes were injected as RAG context for the last reply.
    /// 0 = embedding model not loaded or no matching notes found.
    /// Shown as a debug badge in the chat header.
    @Default(0) int ragContextCount,

    /// Event ids of the source notes (vector hits) that seeded the RAG context
    /// for the LAST assistant reply this turn, in score-desc order. Drives the
    /// "Sources" chip + sheet under that reply. NEVER persisted — lives only in
    /// transient state, so loaded/historical conversations have an empty list
    /// and show no chip. Overwritten each turn; cleared on open/close/branch.
    @Default([]) List<String> lastTurnSourceNoteIds,

    /// `"<sha256>:<ordinal>"` ids of the PDF passages that grounded the LAST
    /// assistant reply. Same lifecycle as [lastTurnSourceNoteIds]: transient,
    /// overwritten each turn, cleared on open/close/branch, never persisted.
    @Default([]) List<String> lastTurnSourceChunkIds,

    /// True while the embedding model is loading on first Shiv tab open.
    @Default(false) bool isRagInitializing,

    /// messageId of the node currently selected in the graph panel.
    /// null = no node selected / panel closed.
    String? selectedNodeMessageId,

    /// All messages for the active conversation (flat list, all branches).
    /// Used by the tree view to build the full graph.
    @Default([]) List<ShivMessageEntity> allMessages,
  }) = _ShivAIState;
}
