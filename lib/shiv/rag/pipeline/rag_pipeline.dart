import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:uniun/domain/entities/graph_edge/graph_edge_entity.dart';
import 'package:uniun/domain/entities/graph_node/graph_node_entity.dart';
import 'package:uniun/domain/entities/memory_node/memory_node_entity.dart';
import 'package:uniun/domain/entities/ai_model/ai_model_entity.dart';
import 'package:uniun/domain/entities/shiv/shiv_message_entity.dart';
import 'package:uniun/domain/usecases/ai_model_usecases.dart';
import 'package:uniun/domain/usecases/knowledge_usecases.dart';
import 'package:uniun/domain/usecases/profile_usecases.dart';
import 'package:uniun/domain/usecases/user_usecases.dart';
import 'package:uniun/shiv/rag/embedding/embedding_service.dart';
import 'package:uniun/shiv/rag/prompt/prompt_budget.dart';
import 'package:uniun/shiv/rag/prompt/prompt_builder.dart';
import 'package:uniun/shiv/rag/retrieval/enriched_context.dart';
import 'package:uniun/shiv/rag/retrieval/vector_search_service.dart';

/// Result returned by [RagPipeline.buildMessage].
class RagMessage {
  const RagMessage({required this.userMessage, required this.contextCount});

  /// The per-turn message for [AIModelRunner.sendAndStream]:
  /// RAG context (if any) + current user question. No history, no system.
  final String userMessage;

  /// Number of notes + graph edges + memories injected as context.
  /// 0 = model not loaded or no match.
  final int contextCount;
}

/// Orchestrates the full RAG + GraphRAG pipeline.
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
  final GetMemoriesByNoteIdsUseCase _getMemories;
  final GetGraphNeighboursUseCase _getNeighbours;
  final GetGraphNodesByKeysUseCase _getNodesByKeys;
  final GetActiveAIModelUseCase _getActiveModel;

  PersonalizationContext? _personalization;

  RagPipeline(
    this._embedding,
    this._vectorSearch,
    this._promptBuilder,
    this._getActiveUser,
    this._getOwnProfile,
    this._getMemories,
    this._getNeighbours,
    this._getNodesByKeys,
    this._getActiveModel,
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

  /// Builds the per-turn user message: GraphRAG context (if any) + question.
  /// Steps: vector seed → 1-hop graph expansion → memory retrieval →
  /// budget-aware assembly. Do NOT pass conversation history —
  /// [InferenceChat] manages it internally.
  Future<RagMessage> buildMessage({required String userQuestion}) async {
    final context = await _retrieveContext(userQuestion);
    final budget = PromptBudget.forModel(await _activeModelId());
    final userMessage = _promptBuilder.buildUserMessage(
      userQuestion: userQuestion,
      context: context,
      budget: budget,
    );
    final count =
        context.seedNotes.length + context.graphEdges.length + context.memories.length;
    return RagMessage(userMessage: userMessage, contextCount: count);
  }

  /// Builds a compact summary of [branch] messages for system instruction
  /// injection when the user switches branches. Delegates to [PromptBuilder].
  String buildBranchContextSummary(List<ShivMessageEntity> branch) =>
      _promptBuilder.buildBranchContextSummary(branch);

  /// Clear the personalisation cache (call when profile changes or on logout).
  void clearCache() => _personalization = null;

  // ── Internals ──────────────────────────────────────────────────────────────

  Future<EnrichedContext> _retrieveContext(String query) async {
    try {
      final vec = await _embedding.embed(query);
      if (vec.isEmpty) return EnrichedContext.empty;

      // 1. Vector seed.
      final seedNotes = await _vectorSearch.search(queryVector: vec);
      if (seedNotes.isEmpty) return EnrichedContext.empty;

      // 2. Memory for seeds → collect concept keys.
      final seedIds = seedNotes.map((s) => s.noteId).toList();
      final seedMemoriesResult = await _getMemories.call(seedIds);
      final seedMemories =
          seedMemoriesResult.fold((_) => <MemoryNodeEntity>[], (m) => m);
      final conceptKeys = <String>{
        for (final m in seedMemories) ...m.concepts,
      }.toList();

      // 3. Graph expand.
      final edgesResult = await _getNeighbours.call(conceptKeys);
      final edges =
          edgesResult.fold((_) => <GraphEdgeEntity>[], (e) => e);

      // 4. Nodes for edge labels.
      final involvedKeys = <String>{
        for (final e in edges) ...[e.sourceKey, e.targetKey]
      }.toList();
      final nodesResult = await _getNodesByKeys.call(involvedKeys);
      final nodes =
          nodesResult.fold((_) => <GraphNodeEntity>[], (n) => n);

      // 5. Memories for notes that asserted these edges (beyond the seeds).
      final expandedNoteIds = <String>{
        for (final e in edges) e.sourceNoteId,
      }.where((id) => !seedIds.contains(id)).toList();
      List<MemoryNodeEntity> expandedMemories = const [];
      if (expandedNoteIds.isNotEmpty) {
        final res = await _getMemories.call(expandedNoteIds);
        expandedMemories =
            res.fold((_) => <MemoryNodeEntity>[], (m) => m);
      }

      return EnrichedContext(
        seedNotes: seedNotes,
        graphNodes: nodes,
        graphEdges: edges,
        memories: [...seedMemories, ...expandedMemories],
      );
    } catch (_) {
      return EnrichedContext.empty;
    }
  }

  Future<AIModelId?> _activeModelId() async {
    final result = await _getActiveModel.call();
    return result.fold((_) => null, (m) => m?.modelId);
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

