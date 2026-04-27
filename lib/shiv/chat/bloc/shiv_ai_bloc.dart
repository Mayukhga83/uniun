import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:uniun/core/enum/message_role.dart';
import 'package:uniun/domain/entities/shiv/shiv_conversation_entity.dart';
import 'package:uniun/domain/entities/shiv/shiv_message_entity.dart';
import 'package:uniun/domain/usecases/shiv_usecases.dart';
import 'package:uniun/shiv/rag/pipeline/rag_pipeline.dart';
import 'package:uniun/shiv/services/ai_model_runner.dart';
import 'package:uuid/uuid.dart';

part 'shiv_ai_event.dart';
part 'shiv_ai_state.dart';
part 'shiv_ai_bloc.freezed.dart';

@injectable
class ShivAIBloc extends Bloc<ShivAIEvent, ShivAIState> {
  final GetConversationsUseCase _getConversations;
  final CreateConversationUseCase _createConversation;
  final DeleteConversationUseCase _deleteConversation;
  final GetMessagesUseCase _getMessages;
  final SaveMessageUseCase _saveMessage;
  final UpdateMessageContentUseCase _updateMessageContent;
  final UpdateConversationTitleUseCase _updateConversationTitle;
  final UpdateActiveLeafUseCase _updateActiveLeaf;
  final AIModelRunner _runner;
  final RagPipeline _rag;

  StreamSubscription<String>? _streamSub;

  ShivAIBloc(
    this._getConversations,
    this._createConversation,
    this._deleteConversation,
    this._getMessages,
    this._saveMessage,
    this._updateMessageContent,
    this._updateConversationTitle,
    this._updateActiveLeaf,
    this._runner,
    this._rag,
  ) : super(const ShivAIState()) {
    on<_LoadConversations>(_onLoadConversations, transformer: droppable());
    on<_CreateConversation>(_onCreateConversation, transformer: droppable());
    on<_OpenConversation>(_onOpenConversation, transformer: droppable());
    on<_CloseConversation>(_onCloseConversation);
    on<_DeleteConversation>(_onDeleteConversation, transformer: sequential());
    on<_SendMessage>(_onSendMessage, transformer: sequential());
    on<_StopStreaming>(_onStopStreaming);
    on<_TokenReceived>(_onTokenReceived, transformer: sequential());
    on<_StreamDone>(_onStreamDone);
    on<_StreamError>(_onStreamError);
    on<_SwitchBranch>(_onSwitchBranch, transformer: droppable());
    on<_CreateBranchFrom>(_onCreateBranchFrom, transformer: droppable());
    on<_SelectGraphNode>(_onSelectGraphNode);
  }

  // ── Conversation list ───────────────────────────────────────────────────────

  Future<void> _onLoadConversations(
      _LoadConversations event, Emitter<ShivAIState> emit) async {
    emit(state.copyWith(isRagInitializing: true));
    await _rag.init();
    emit(state.copyWith(isRagInitializing: false));

    final result = await _getConversations.call();
    result.fold(
      (f) => emit(state.copyWith(
          status: ShivChatStatus.error, errorMessage: f.toString())),
      (list) => emit(state.copyWith(
          status: ShivChatStatus.idle, conversations: list, errorMessage: null)),
    );
  }

  Future<void> _onCreateConversation(
      _CreateConversation event, Emitter<ShivAIState> emit) async {
    // Guard: no model loaded yet — ShivPage._checkModel() will redirect.
    if (!_runner.hasActiveModel) return;

    final result = await _createConversation.call('New conversation');
    await result.fold(
      (f) async => emit(state.copyWith(
          status: ShivChatStatus.error, errorMessage: f.toString())),
      (conv) async {
        await _initChatSession();
        emit(state.copyWith(
          status: ShivChatStatus.chatIdle,
          activeConversation: conv,
          conversations: [conv, ...state.conversations],
          messages: [],
          ragContextCount: 0,
          errorMessage: null,
        ));
      },
    );
  }

  Future<void> _onOpenConversation(
      _OpenConversation event, Emitter<ShivAIState> emit) async {
    // Guard: no model loaded yet — ShivPage._checkModel() will redirect.
    if (!_runner.hasActiveModel) return;

    final conv = state.conversations
        .where((c) => c.conversationId == event.conversationId)
        .firstOrNull;
    if (conv == null) return;

    final result = await _getMessages.call(event.conversationId);
    await result.fold(
      (f) async => emit(state.copyWith(
          status: ShivChatStatus.error, errorMessage: f.toString())),
      (msgs) async {
        await _initChatSession();
        emit(state.copyWith(
          status: ShivChatStatus.chatIdle,
          activeConversation: conv,
          messages: msgs,
          allMessages: msgs,
          ragContextCount: 0,
          errorMessage: null,
        ));
      },
    );
  }

  Future<void> _onCloseConversation(
      _CloseConversation event, Emitter<ShivAIState> emit) async {
    _streamSub?.cancel();
    await _runner.close();
    emit(state.copyWith(
      status: ShivChatStatus.idle,
      activeConversation: null,
      messages: [],
      streamingContent: null,
      streamingMessageId: null,
      ragContextCount: 0,
    ));
  }

  Future<void> _onDeleteConversation(
      _DeleteConversation event, Emitter<ShivAIState> emit) async {
    await _deleteConversation.call(event.conversationId);
    final updated = state.conversations
        .where((c) => c.conversationId != event.conversationId)
        .toList();
    emit(state.copyWith(conversations: updated));
  }

  // ── Chat / Inference ────────────────────────────────────────────────────────

  Future<void> _onSendMessage(
      _SendMessage event, Emitter<ShivAIState> emit) async {
    final conv = state.activeConversation;
    if (conv == null) return;

    final text = event.text.trim();
    if (text.isEmpty) return;

    // 1 — Save user message.
    final userMsgId = const Uuid().v4();
    final userMsg = ShivMessageEntity(
      messageId: userMsgId,
      conversationId: conv.conversationId,
      parentId: state.messages.lastOrNull?.messageId,
      role: MessageRole.user,
      content: text,
      createdAt: DateTime.now(),
    );
    await _saveMessage.call(userMsg);

    // Auto-title the conversation from the first user message (like ChatGPT).
    final isFirstMessage = state.messages.isEmpty;
    ShivConversationEntity updatedConv = conv;
    if (isFirstMessage) {
      final title = text.length > 40 ? '${text.substring(0, 40)}…' : text;
      await _updateConversationTitle.call((conv.conversationId, title));
      updatedConv = conv.copyWith(title: title);
      final updatedList = state.conversations.map((c) {
        return c.conversationId == conv.conversationId ? updatedConv : c;
      }).toList();
      emit(state.copyWith(
        activeConversation: updatedConv,
        conversations: updatedList,
      ));
    }

    // 2 — Placeholder assistant message.
    final assistantMsgId = const Uuid().v4();
    final placeholderMsg = ShivMessageEntity(
      messageId: assistantMsgId,
      conversationId: updatedConv.conversationId,
      parentId: userMsgId,
      role: MessageRole.assistant,
      content: '',
      createdAt: DateTime.now(),
    );
    await _saveMessage.call(placeholderMsg);

    final newMessages = [...state.messages, userMsg, placeholderMsg];
    emit(state.copyWith(
      status: ShivChatStatus.streaming,
      messages: newMessages,
      allMessages: [...state.allMessages, userMsg, placeholderMsg],
      streamingContent: '',
      streamingMessageId: assistantMsgId,
    ));

    // 3 — RAG: embed query → retrieve notes → build per-turn user message.
    //     No history in here — InferenceChat tracks turns internally.
    final ragMsg = await _rag.buildMessage(userQuestion: text);
    emit(state.copyWith(ragContextCount: ragMsg.contextCount));

    // 4 — Stream inference.
    _streamSub?.cancel();
    _streamSub = _runner.sendAndStream(ragMsg.userMessage).listen(
      (token) => add(ShivAIEvent.tokenReceived(token)),
      onDone: () => add(const ShivAIEvent.streamDone()),
      onError: (Object e) => add(ShivAIEvent.streamError(e.toString())),
      cancelOnError: true,
    );
  }

  /// User tapped stop during streaming. Cancel the native token stream, keep
  /// whatever's already been generated, and persist it as the final assistant
  /// message so the conversation stays coherent on next open.
  Future<void> _onStopStreaming(
      _StopStreaming event, Emitter<ShivAIState> emit) async {
    if (state.status != ShivChatStatus.streaming) return;
    await _streamSub?.cancel();
    _streamSub = null;

    final msgId = state.streamingMessageId;
    final partial = _stripThinking(state.streamingContent ?? '').trim();
    final finalContent = partial.isEmpty ? '(stopped)' : partial;

    if (msgId != null) {
      await _updateMessageContent.call((msgId, finalContent));
      final updatedMessages = state.messages.map((m) {
        if (m.messageId == msgId) return m.copyWith(content: finalContent);
        return m;
      }).toList();
      emit(state.copyWith(
        status: ShivChatStatus.chatIdle,
        messages: updatedMessages,
        streamingContent: null,
        streamingMessageId: null,
      ));
    } else {
      emit(state.copyWith(
        status: ShivChatStatus.chatIdle,
        streamingContent: null,
        streamingMessageId: null,
      ));
    }
  }

  void _onTokenReceived(_TokenReceived event, Emitter<ShivAIState> emit) {
    final accumulated = (state.streamingContent ?? '') + event.token;
    emit(state.copyWith(streamingContent: accumulated));
  }

  Future<void> _onStreamDone(
      _StreamDone event, Emitter<ShivAIState> emit) async {
    final msgId = state.streamingMessageId;
    // Strip <think>...</think> blocks before persisting — model reasoning is
    // never stored so it cannot leak back into RAG context or branch summaries.
    final content = _stripThinking(state.streamingContent ?? '');

    if (msgId != null) {
      await _updateMessageContent.call((msgId, content));

      final updatedMessages = state.messages.map((m) {
        if (m.messageId == msgId) return m.copyWith(content: content);
        return m;
      }).toList();

      emit(state.copyWith(
        status: ShivChatStatus.chatIdle,
        messages: updatedMessages,
        streamingContent: null,
        streamingMessageId: null,
      ));
    } else {
      emit(state.copyWith(
        status: ShivChatStatus.chatIdle,
        streamingContent: null,
        streamingMessageId: null,
      ));
    }
  }

  void _onStreamError(_StreamError event, Emitter<ShivAIState> emit) {
    emit(state.copyWith(
      status: ShivChatStatus.error,
      errorMessage: event.message,
      streamingContent: null,
      streamingMessageId: null,
    ));
  }

  // ── Branch graph ────────────────────────────────────────────────────────────

  Future<void> _onSwitchBranch(
      _SwitchBranch event, Emitter<ShivAIState> emit) async {
    final conv = state.activeConversation;
    if (conv == null) return;

    final branch = _buildBranch(event.leafMessageId, state.allMessages);
    await _updateActiveLeaf.call((conv.conversationId, event.leafMessageId));

    // Reinit chat with a compact summary of the branch as context so the model
    // knows what was discussed on this path without replaying full history.
    await _initChatSession(branchContext: branch);

    emit(state.copyWith(
      messages: branch,
      activeConversation: conv.copyWith(activeLeafMessageId: event.leafMessageId),
      selectedNodeMessageId: null,
    ));
  }

  Future<void> _onCreateBranchFrom(
      _CreateBranchFrom event, Emitter<ShivAIState> emit) async {
    final conv = state.activeConversation;
    if (conv == null) return;

    final branch = _buildBranch(event.parentMessageId, state.allMessages);
    await _updateActiveLeaf.call((conv.conversationId, event.parentMessageId));

    await _initChatSession(branchContext: branch);

    emit(state.copyWith(
      messages: branch,
      activeConversation: conv.copyWith(activeLeafMessageId: event.parentMessageId),
      selectedNodeMessageId: null,
    ));
  }

  void _onSelectGraphNode(
      _SelectGraphNode event, Emitter<ShivAIState> emit) {
    emit(state.copyWith(selectedNodeMessageId: event.messageId));
  }

  /// Removes <think>...</think> blocks emitted by reasoning models (DeepSeek R1,
  /// Qwen3) before content is persisted to Isar. This keeps model reasoning out
  /// of branch context summaries and any future RAG lookups.
  static String _stripThinking(String content) {
    return content
        .replaceAll(RegExp(r'<think>[\s\S]*?</think>', caseSensitive: false), '')
        .trim();
  }

  /// Walk the parentId chain from [leafId] up to the root.
  /// Returns messages in chronological order (root first).
  List<ShivMessageEntity> _buildBranch(
      String leafId, List<ShivMessageEntity> all) {
    final byId = {for (final m in all) m.messageId: m};
    final branch = <ShivMessageEntity>[];
    String? current = leafId;
    while (current != null) {
      final msg = byId[current];
      if (msg == null) break;
      branch.insert(0, msg);
      current = msg.parentId;
    }
    return branch;
  }

  @override
  Future<void> close() async {
    _streamSub?.cancel();
    await _runner.close();
    return super.close();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Creates a fresh InferenceChat session with the Shiv system instruction.
  /// On branch switch, [branchContext] adds a compact conversation summary so
  /// the model understands what was discussed on the parent path.
  Future<void> _initChatSession({List<ShivMessageEntity>? branchContext}) async {
    final systemInstruction = await _rag.buildSystemInstruction();
    final contextSummary = branchContext != null && branchContext.isNotEmpty
        ? _rag.buildBranchContextSummary(branchContext)
        : '';
    await _runner.initChat(
      systemInstruction: contextSummary.isEmpty
          ? systemInstruction
          : '$systemInstruction$contextSummary',
    );
  }
}
