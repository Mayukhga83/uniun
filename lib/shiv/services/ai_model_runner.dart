import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:injectable/injectable.dart';

/// Wraps flutter_gemma 0.13.x for token-streaming inference.
///
/// One [InferenceChat] session is kept alive per conversation — created on
/// first use and disposed when [close] is called.
///
/// Usage:
///   final runner = getIt<AIModelRunner>();
///   await runner.initChat();
///   await for (final token in runner.sendAndStream(userMessage)) {
///     // append token
///   }
///   runner.close(); // when conversation ends
@lazySingleton
class AIModelRunner {
  InferenceChat? _chat;

  bool get hasActiveModel => FlutterGemma.hasActiveModel();
  bool get hasChatSession => _chat != null;

  /// Initialize a new chat session for the active model.
  /// Call this when opening a new or existing conversation.
  Future<void> initChat() async {
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
  }

  /// Send [prompt] and stream text tokens back.
  ///
  /// Throws [StateError] if [initChat] was not called first.
  Stream<String> sendAndStream(String prompt) async* {
    final chat = _chat;
    if (chat == null) {
      throw StateError('Call initChat() before sending messages.');
    }

    await chat.addQuery(Message.text(text: prompt));

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
}
