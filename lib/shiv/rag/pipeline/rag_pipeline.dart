import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:uniun/domain/usecases/note_usecases.dart';
import 'package:uniun/domain/usecases/profile_usecases.dart';
import 'package:uniun/domain/usecases/user_usecases.dart';
import 'package:uniun/shiv/rag/embedding/embedding_service.dart';
import 'package:uniun/shiv/rag/prompt/prompt_builder.dart';
import 'package:uniun/domain/entities/shiv/scored_note.dart';
import 'package:uniun/shiv/rag/retrieval/vector_search_service.dart';

/// Result returned by [RagPipeline.buildMessage].
class RagMessage {
  const RagMessage({required this.userMessage, required this.contextCount});

  /// The per-turn message for [AIModelRunner.sendAndStream]:
  /// RAG context (if any) + current user question. No history, no system.
  final String userMessage;

  /// Number of saved notes injected as context. 0 = model not loaded or no match.
  final int contextCount;
}

/// Orchestrates the full RAG pipeline.
///
/// ## Two-phase usage (matches InferenceChat's split):
///
/// **Phase 1 — session open** (once per conversation):
///   ```dart
///   await rag.init();
///   final sysInstruction = await rag.buildSystemInstruction();
///   await runner.initChat(systemInstruction: sysInstruction);
///   ```
///
/// **Phase 2 — each user message**:
///   ```dart
///   final msg = await rag.buildMessage(userQuestion: text);
///   runner.sendAndStream(msg.userMessage);
///   ```
@lazySingleton
class RagPipeline {
  final EmbeddingService _embedding;
  final VectorSearchService _vectorSearch;
  final PromptBuilder _promptBuilder;
  final GetActiveUserUseCase _getActiveUser;
  final GetOwnProfileUseCase _getOwnProfile;
  final GetOwnNotesUseCase _getOwnNotes;

  PersonalizationContext? _personalization;

  RagPipeline(
    this._embedding,
    this._vectorSearch,
    this._promptBuilder,
    this._getActiveUser,
    this._getOwnProfile,
    this._getOwnNotes,
  );

  // ── Phase 1 ────────────────────────────────────────────────────────────────

  /// Loads the embedding model from disk. Call once when the Shiv tab opens.
  Future<void> init() async {
    await _embedding.init();
  }

  /// Returns the static system instruction for this session.
  /// Includes Shiv persona + user name/bio + interests.
  /// Pass to [AIModelRunner.initChat(systemInstruction:)].
  Future<String> buildSystemInstruction() async {
    _personalization ??= await _loadPersonalization();
    return _promptBuilder.buildSystemInstruction(_personalization!);
  }

  // ── Phase 2 ────────────────────────────────────────────────────────────────

  /// Builds the per-turn user message: RAG context (if any) + question.
  /// Do NOT pass conversation history — [InferenceChat] manages it internally.
  Future<RagMessage> buildMessage({required String userQuestion}) async {
    final relevantNotes = await _retrieveContext(userQuestion);
    final userMessage = _promptBuilder.buildUserMessage(
      userQuestion: userQuestion,
      relevantNotes: relevantNotes,
    );
    return RagMessage(
      userMessage: userMessage,
      contextCount: relevantNotes.length,
    );
  }

  /// Clear the personalisation cache (call when profile changes or on logout).
  void clearCache() => _personalization = null;

  // ── Internals ──────────────────────────────────────────────────────────────

  Future<List<ScoredNote>> _retrieveContext(String query) async {
    try {
      final vec = await _embedding.embed(query);
      if (vec.isEmpty) return [];
      return _vectorSearch.search(queryVector: vec);
    } catch (_) {
      return [];
    }
  }

  Future<PersonalizationContext> _loadPersonalization() async {
    String? name;
    String? bio;

    final userResult = await _getActiveUser.call();
    final pubkey = userResult.fold((_) => null, (u) => u.pubkeyHex);

    if (pubkey != null) {
      final profileResult = await _getOwnProfile.call(pubkey);
      profileResult.fold((_) {}, (profile) {
        name = profile?.name;
        bio = profile?.about;
      });
    }

    return PersonalizationContext(userName: name, userBio: bio);
  }
}
