import 'package:uniun/domain/entities/ai_model/ai_model_entity.dart';

/// Per-model token budget for per-turn user-message assembly.
///
/// Total budget is split across priority buckets. If the assembled sections
/// overshoot, lower-priority sections are dropped first. Priority order
/// (highest → lowest):
///   1. user query (always kept)
///   2. top 1-2 seed notes
///   3. strong graph relations
///   4. remaining seed notes
///   5. memory summaries
class PromptBudget {
  const PromptBudget({
    required this.maxTokens,
    required this.queryTokens,
    required this.topNotesTokens,
    required this.graphRelationsTokens,
    required this.memoriesTokens,
  });

  final int maxTokens;
  final int queryTokens;
  final int topNotesTokens;
  final int graphRelationsTokens;
  final int memoriesTokens;

  /// Returns the recommended budget for a given model. Falls back to a
  /// conservative 2k budget when no model is active.
  factory PromptBudget.forModel(AIModelId? modelId) {
    final int max;
    switch (modelId) {
      case AIModelId.gemma4E4b:
        max = 8192;
        break;
      case AIModelId.gemma4E2b:
      case AIModelId.deepseekR1:
        max = 4096;
        break;
      case AIModelId.qwen25_05b:
      case null:
        max = 2048;
    }
    // Recommended split from wikiAI.md:
    //   query 5-10%, topNotes 30-40%, graphRelations 15-20%, summaries 10-20%.
    return PromptBudget(
      maxTokens: max,
      queryTokens: (max * 0.10).round(),
      topNotesTokens: (max * 0.35).round(),
      graphRelationsTokens: (max * 0.20).round(),
      memoriesTokens: (max * 0.15).round(),
    );
  }

  /// Rough estimate: English text averages ~4 characters per token for
  /// subword BPE/SentencePiece tokenisers. Good enough for local budgeting —
  /// we don't need token-perfect accuracy, just ranked trimming.
  static int estimateTokens(String text) => (text.length / 4).ceil();
}
