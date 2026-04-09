import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:uniun/domain/usecases/note_usecases.dart';
import 'package:uniun/domain/usecases/profile_usecases.dart';
import 'package:uniun/domain/usecases/saved_note_usecases.dart';
import 'package:uniun/domain/usecases/user_usecases.dart';
import 'package:uniun/shiv/rag/embedding/embedding_service.dart';
import 'package:uniun/shiv/rag/prompt/prompt_builder.dart';
import 'package:uniun/shiv/rag/retrieval/scored_note.dart';
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
  final GetAllSavedNotesUseCase _getAllSavedNotes;
  final UpdateEmbeddingUseCase _updateEmbedding;
  final UpdateNoteEmbeddingUseCase _updateNoteEmbedding;

  PersonalizationContext? _personalization;

  RagPipeline(
    this._embedding,
    this._vectorSearch,
    this._promptBuilder,
    this._getActiveUser,
    this._getOwnProfile,
    this._getOwnNotes,
    this._getAllSavedNotes,
    this._updateEmbedding,
    this._updateNoteEmbedding,
  );

  // ── Phase 1 ────────────────────────────────────────────────────────────────

  /// Loads the embedding model from disk. Call once when the Shiv tab opens.
  /// Also kick off a background re-embedding pass for any saved notes that
  /// were stored before the embedding model was available.
  Future<void> init() async {
    await _embedding.init();
    unawaited(_reEmbedMissingNotes());
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

  /// Retroactively generates embeddings for any notes that were stored
  /// before the embedding model was downloaded.
  /// Covers: saved (bookmarked) notes + own authored notes.
  Future<void> _reEmbedMissingNotes() async {
    if (!_embedding.isReady) return;

    // 1 — Saved notes
    final savedResult = await _getAllSavedNotes.call();
    await savedResult.fold((_) async {}, (notes) async {
      final missing = notes.where(
        (n) => n.embedding == null || n.embedding!.isEmpty,
      );
      for (final note in missing) {
        final vec = await _embedding.embed(note.content);
        if (vec.isNotEmpty) {
          await _updateEmbedding.call((note.eventId, vec));
          print('📦 Re-embedded saved note: ${note.eventId}');
        }
      }
    });

    // 2 — Own authored notes
    final userResult = await _getActiveUser.call();
    final pubkey = userResult.fold((_) => null, (u) => u.pubkeyHex);
    if (pubkey == null) return;

    final ownResult = await _getOwnNotes.call(pubkey);
    await ownResult.fold((_) async {}, (notes) async {
      final missing = notes.where(
        (n) => n.embedding == null || n.embedding!.isEmpty,
      );
      for (final note in missing) {
        final vec = await _embedding.embed(note.content);
        if (vec.isNotEmpty) {
          await _updateNoteEmbedding.call((note.id, vec));
          print('📦 Re-embedded own note: ${note.id}');
        }
      }
    });
  }

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
