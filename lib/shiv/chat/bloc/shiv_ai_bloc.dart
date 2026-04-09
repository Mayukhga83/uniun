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
    this._runner,
    this._rag,
  ) : super(const ShivAIState()) {
    on<_LoadConversations>(_onLoadConversations, transformer: droppable());
    on<_CreateConversation>(_onCreateConversation, transformer: droppable());
    on<_OpenConversation>(_onOpenConversation, transformer: droppable());
    on<_CloseConversation>(_onCloseConversation);
    on<_DeleteConversation>(_onDeleteConversation, transformer: sequential());
    on<_SendMessage>(_onSendMessage, transformer: sequential());
    on<_TokenReceived>(_onTokenReceived, transformer: sequential());
    on<_StreamDone>(_onStreamDone);
    on<_StreamError>(_onStreamError);
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
    final result = await _createConversation.call('New conversation');
    await result.fold(
      (f) async => emit(state.copyWith(
          status: ShivChatStatus.error, errorMessage: f.toString())),
      (conv) async {
        await _initChatSession();
        emit(state.copyWith(
          status: ShivChatStatus.chatIdle,
          activeConversation: conv,
          messages: [],
          ragContextCount: 0,
          errorMessage: null,
        ));
      },
    );
  }

  Future<void> _onOpenConversation(
      _OpenConversation event, Emitter<ShivAIState> emit) async {
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

    // 2 — Placeholder assistant message.
    final assistantMsgId = const Uuid().v4();
    final placeholderMsg = ShivMessageEntity(
      messageId: assistantMsgId,
      conversationId: conv.conversationId,
      parentId: userMsgId,
      role: MessageRole.assistant,
      content: '',
      createdAt: DateTime.now(),
    );
    await _saveMessage.call(placeholderMsg);

    emit(state.copyWith(
      status: ShivChatStatus.streaming,
      messages: [...state.messages, userMsg, placeholderMsg],
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

  void _onTokenReceived(_TokenReceived event, Emitter<ShivAIState> emit) {
    final accumulated = (state.streamingContent ?? '') + event.token;
    emit(state.copyWith(streamingContent: accumulated));
  }

  Future<void> _onStreamDone(
      _StreamDone event, Emitter<ShivAIState> emit) async {
    final msgId = state.streamingMessageId;
    final content = state.streamingContent ?? '';

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

  @override
  Future<void> close() async {
    _streamSub?.cancel();
    await _runner.close();
    return super.close();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Creates a fresh InferenceChat session with the Shiv system instruction.
  /// Called whenever a conversation is opened or created.
  Future<void> _initChatSession() async {
    final systemInstruction = await _rag.buildSystemInstruction();
    await _runner.initChat(systemInstruction: systemInstruction);
  }
}
