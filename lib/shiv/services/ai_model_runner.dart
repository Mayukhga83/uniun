import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:injectable/injectable.dart';

/// Wraps flutter_gemma 0.13.x for token-streaming inference.
///
/// One [InferenceChat] session is kept alive per conversation.
/// [systemInstruction] is set once at session creation — it contains the
/// Shiv persona + user personalization. Each subsequent call to
/// [sendAndStream] passes ONLY the current user turn (with any RAG context
/// prepended) — flutter_gemma manages conversation history internally so we
/// never duplicate it in our own prompt.
@lazySingleton
class AIModelRunner {
  InferenceChat? _chat;
  String? _pendingSystemInstruction;
  bool _firstMessageSent = false;

  /// Mutex for stateless one-shot inference calls. flutter_gemma's native
  /// MediaPipe session only allows one active invocation at a time — firing
  /// a second extraction while the first is still running throws
  /// `IllegalStateException: Previous invocation still processing`. We
  /// serialize all one-shot calls through a Future chain so concurrent
  /// saves queue up instead of colliding.
  Future<void> _oneShotLock = Future.value();

  bool get hasActiveModel => FlutterGemma.hasActiveModel();
  bool get hasChatSession => _chat != null;

  /// Initialize a new chat session for the active model.
  ///
  /// [systemInstruction] is prepended to the first user message because
  /// flutter_gemma's Qwen template silently drops the systemInstruction
  /// parameter from createChat() — the prompt sent to the model is only
  /// the user turn (confirmed by result length=17 in logs).
  Future<void> initChat({String? systemInstruction}) async {
    if (!FlutterGemma.hasActiveModel()) {
      throw StateError('No AI model is active. Please select a model first.');
    }
    await _chat?.close();
    final model = await FlutterGemma.getActiveModel(maxTokens: 4096);
    _chat = await model.createChat(
      temperature: 0.8,
      topK: 40,
      tokenBuffer: 512,
    );
    _pendingSystemInstruction = systemInstruction;
    _firstMessageSent = false;
  }

  /// Send the current user [message] (question + RAG context if any) and
  /// stream text tokens back.
  ///
  /// On the first turn, the system instruction is prepended directly to the
  /// message so the model actually sees it regardless of chat template support.
  ///
  /// Throws [StateError] if [initChat] was not called first.
  Stream<String> sendAndStream(String message) async* {
    final chat = _chat;
    if (chat == null) {
      throw StateError('Call initChat() before sending messages.');
    }

    String finalMessage = message;
    if (!_firstMessageSent && _pendingSystemInstruction != null) {
      finalMessage = '${_pendingSystemInstruction!}\n\n$message';
      _firstMessageSent = true;
    }

    await chat.addQuery(Message.text(text: finalMessage));

    await for (final response in chat.generateChatResponseAsync()) {
      if (response is TextResponse && response.token.isNotEmpty) {
        yield response.token;
      }
    }
  }

  /// Dispose the current chat session.
  Future<void> close() async {
    await _chat?.close();
    _chat = null;
  }

  /// Stateless one-shot completion. Creates a throwaway chat, sends the
  /// prompt, accumulates the full response, closes the session.
  ///
  /// Used by extraction tasks (entities/relations/summary). Does NOT touch the
  /// user-facing chat session in [_chat]. Returns null when no model is active
  /// so callers can safely fire-and-forget during graceful-degradation paths.
  Future<String?> generateOneShot(String prompt, {int maxTokens = 1024}) async {
    if (!FlutterGemma.hasActiveModel()) {
      debugPrint('⏭️ generateOneShot: no active model');
      return null;
    }
    // Serialise: wait for any in-flight one-shot to finish before starting.
    final previous = _oneShotLock;
    final gate = Completer<void>();
    _oneShotLock = gate.future;
    try {
      await previous;
      return await _doGenerateOneShot(prompt, maxTokens);
    } finally {
      gate.complete();
    }
  }

  Future<String?> _doGenerateOneShot(String prompt, int maxTokens) async {
    InferenceChat? oneShot;
    try {
      debugPrint('🧪 generateOneShot: opening throwaway chat…');
      final model = await FlutterGemma.getActiveModel(maxTokens: maxTokens);
      oneShot = await model.createChat(
        temperature: 0.2,
        topK: 20,
        tokenBuffer: 256,
      );
      await oneShot.addQuery(Message.text(text: prompt));
      final buffer = StringBuffer();
      await for (final response in oneShot.generateChatResponseAsync()) {
        if (response is TextResponse) buffer.write(response.token);
      }
      debugPrint('🧪 generateOneShot: done (${buffer.length} chars)');
      return buffer.toString();
    } catch (e, st) {
      debugPrint('❌ generateOneShot failed: $e\n$st');
      return null;
    } finally {
      await oneShot?.close();
    }
  }
}
