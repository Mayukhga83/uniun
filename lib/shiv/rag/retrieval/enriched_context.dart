import 'package:uniun/domain/entities/graph_edge/graph_edge_entity.dart';
import 'package:uniun/domain/entities/graph_node/graph_node_entity.dart';
import 'package:uniun/domain/entities/memory_node/memory_node_entity.dart';
import 'package:uniun/domain/entities/shiv/scored_note.dart';

/// Bundle of retrieval artefacts assembled by [RagPipeline] for a single
/// user turn. Fed to [PromptBuilder.buildUserMessage] which lays it out
/// inside the token budget.
class EnrichedContext {
  const EnrichedContext({
    required this.seedNotes,
    required this.graphNodes,
    required this.graphEdges,
    required this.memories,
  });

  /// Top-K vector hits — always the highest-priority block (after the query).
  final List<ScoredNote> seedNotes;

  /// Nodes referenced by [graphEdges]. Lookup for edge labels when rendering.
  final List<GraphNodeEntity> graphNodes;

  /// 1-hop expansion edges — rendered as "source → type → target" lines.
  final List<GraphEdgeEntity> graphEdges;

  /// Wiki summaries for notes related to the seeds (via memory links).
  final List<MemoryNodeEntity> memories;

  bool get isEmpty =>
      seedNotes.isEmpty &&
      graphEdges.isEmpty &&
      memories.isEmpty;

  static const empty = EnrichedContext(
    seedNotes: [],
    graphNodes: [],
    graphEdges: [],
    memories: [],
  );
}
