import 'package:uniun/domain/entities/graph_edge/graph_edge_entity.dart';
import 'package:uniun/domain/entities/graph_node/graph_node_entity.dart';
import 'package:uniun/domain/entities/memory_node/memory_node_entity.dart';
import 'package:uniun/domain/entities/shiv/scored_chunk.dart';
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
    this.seedChunks = const [],
  });

  /// Top-K vector hits — always the highest-priority block (after the query).
  final List<ScoredNote> seedNotes;

  /// Nodes referenced by [graphEdges]. Lookup for edge labels when rendering.
  final List<GraphNodeEntity> graphNodes;

  /// 1-hop expansion edges — rendered as "source → type → target" lines.
  final List<GraphEdgeEntity> graphEdges;

  /// Wiki summaries for notes related to the seeds (via memory links).
  final List<MemoryNodeEntity> memories;

  /// Top-K PDF chunk hits, rendered as a "Relevant Documents" section. Chunks
  /// are not graph nodes and carry no memory summaries, so they take no part in
  /// graph expansion.
  final List<ScoredChunk> seedChunks;

  bool get isEmpty =>
      seedNotes.isEmpty &&
      seedChunks.isEmpty &&
      graphEdges.isEmpty &&
      memories.isEmpty;

  static const empty = EnrichedContext(
    seedNotes: [],
    graphNodes: [],
    graphEdges: [],
    memories: [],
  );
}
