import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:uniun/domain/entities/graph_edge/graph_edge_entity.dart';
import 'package:uniun/domain/entities/graph_node/graph_node_entity.dart';
import 'package:uniun/domain/entities/memory_node/memory_node_entity.dart';
import 'package:uniun/domain/entities/shiv/scored_note.dart';
import 'package:uniun/domain/entities/shiv/shiv_message_entity.dart';
import 'package:uniun/shiv/rag/prompt/prompt_budget.dart';
import 'package:uniun/shiv/rag/retrieval/enriched_context.dart';

/// Data loaded once per session from Isar.
/// Personalises every prompt even when the user has zero saved notes.
class PersonalizationContext {
  const PersonalizationContext({this.userName, this.userBio});

  final String? userName;
  final String? userBio;
}

/// Assembles prompts for Shiv inference.
///
/// ## Architecture
/// flutter_gemma's [InferenceChat] manages conversation history internally.
/// We must NOT embed history in our prompts — that causes every prior turn to
/// be repeated inside the model's context window.
///
/// Instead we split into two pieces:
///
/// **[buildSystemInstruction]** — called ONCE when a conversation opens.
/// Produces the static system instruction: Shiv persona + user name/bio +
/// interests. Passed to [InferenceChat] via `createChat(systemInstruction:)`.
///
/// **[buildUserMessage]** — called for EVERY user turn.
/// Produces only: the RAG context block (if notes were retrieved) +
/// the current user question. No history, no system repeated.
@lazySingleton
class PromptBuilder {
  const PromptBuilder();

  // ── Session-level (set once) ────────────────────────────────────────────────

  /// Builds the static system instruction injected once per conversation.
  String buildSystemInstruction(PersonalizationContext personalization) {
    final buf = StringBuffer();

    final name = personalization.userName;
    final bio = personalization.userBio;

    buf.writeln(
      'You are Shiv, the on-device AI assistant of UNIUN. Your name is Shiv and you were created by the UNIUN team.',
    );
    buf.writeln(
      'UNIUN is a decentralized, offline-first social and knowledge network built on the Nostr protocol. Users create and connect Notes that form both a social feed and a personal knowledge graph.',
    );

    if (name != null && name.isNotEmpty) {
      buf.writeln('The user\'s name is $name (not yours — yours is Shiv).');
      if (bio != null && bio.isNotEmpty) {
        buf.writeln('About the user: $bio');
      }
    }

    buf.writeln('Answer concisely and helpfully.');
    buf.writeln(
      'If you reason before answering, keep your thinking brief — do not over-reason.',
    );

    debugPrint('🤖 System instruction built — name: $name, bio: $bio');

    return buf.toString().trimRight();
  }

  // ── Branch context (called on branch switch) ──────────────────────────────

  /// Summarises a branch's conversation for injection into the system instruction
  /// when the user switches branches.
  ///
  /// Takes the last 6 messages (3 exchanges). For each message:
  /// - User turns: first sentence or up to 100 chars — questions are short.
  /// - AI turns: strips markdown formatting, extracts the first complete sentence
  ///   (up to 220 chars) — avoids cutting a long response mid-thought.
  String buildBranchContextSummary(List<ShivMessageEntity> branch) {
    if (branch.isEmpty) return '';
    final recent = branch.length > 6
        ? branch.sublist(branch.length - 6)
        : branch;
    final buf = StringBuffer(
      '\n[Previous conversation context on this branch]\n',
    );
    for (final m in recent) {
      final isUser = m.role.name == 'user';
      final role = isUser ? 'User' : 'Shiv';
      final preview = isUser
          ? _summarizeUser(m.content)
          : _summarizeAssistant(m.content);
      buf.writeln('$role: $preview');
    }
    buf.write('[Continue naturally from this context]');
    return buf.toString();
  }

  /// First sentence of a user message (≤ 100 chars).
  String _summarizeUser(String content) {
    final text = content.trim();
    return _firstSentence(text, 100);
  }

  /// First complete sentence of an AI response with markdown stripped (≤ 220 chars).
  String _summarizeAssistant(String content) {
    // Strip common markdown: headers, bold, italic, inline code, bullet leaders
    final clean = content
        .replaceAll(RegExp(r'#{1,6}\s+'), '')
        .replaceAll(RegExp(r'\*{1,2}([^*]+)\*{1,2}'), r'\1')
        .replaceAll(RegExp(r'`[^`]*`'), '')
        .replaceAll(RegExp(r'^[\-\*]\s+', multiLine: true), '')
        .replaceAll(RegExp(r'^\d+\.\s+', multiLine: true), '')
        .trim();
    return _firstSentence(clean, 220);
  }

  /// Extracts the first complete sentence up to [limit] chars.
  /// Falls back to plain truncation if no sentence boundary is found early enough.
  String _firstSentence(String text, int limit) {
    if (text.isEmpty) return '…';
    // Look for sentence-ending punctuation followed by space or end-of-string
    final match = RegExp(r'[.!?](?:\s|$)').firstMatch(text);
    if (match != null && match.end <= limit) {
      return text.substring(0, match.end).trim();
    }
    // No early sentence boundary — truncate at limit
    if (text.length <= limit) return text;
    return '${text.substring(0, limit)}…';
  }

  // ── Per-turn (called each message) ─────────────────────────────────────────

  /// Builds the user-turn message from an [EnrichedContext] under a token
  /// [budget]. Priority order when trimming (highest → lowest):
  ///   1. user query (always kept)
  ///   2. top 1-2 seed notes
  ///   3. strong graph relations
  ///   4. remaining seed notes
  ///   5. memory summaries
  ///
  /// This is the ONLY thing added to [InferenceChat] per turn — no history,
  /// no system prompt repetition.
  String buildUserMessage({
    required String userQuestion,
    required EnrichedContext context,
    required PromptBudget budget,
  }) {
    if (context.isEmpty) return userQuestion;

    final sections = <String>[];
    var used = PromptBudget.estimateTokens(userQuestion);

    // ── 1. Top 1-2 seed notes (always try to include if present) ───────────
    final topNotes = context.seedNotes.take(2).toList();
    final restNotes = context.seedNotes.skip(2).toList();
    final topSection = _renderNotesSection(
      'Relevant Notes',
      topNotes,
      budget.topNotesTokens ~/ 2,
    );
    if (topSection != null) {
      sections.add(topSection);
      used += PromptBudget.estimateTokens(topSection);
    }

    // ── 2. Strong graph relations ──────────────────────────────────────────
    final relSection = _renderRelationsSection(
      context.graphEdges,
      context.graphNodes,
      budget.graphRelationsTokens,
    );
    if (relSection != null &&
        used + PromptBudget.estimateTokens(relSection) <= budget.maxTokens) {
      sections.add(relSection);
      used += PromptBudget.estimateTokens(relSection);
    }

    // ── 3. Remaining seed notes ────────────────────────────────────────────
    final restSection = _renderNotesSection(
      'Additional Notes',
      restNotes,
      budget.topNotesTokens ~/ 2,
    );
    if (restSection != null &&
        used + PromptBudget.estimateTokens(restSection) <= budget.maxTokens) {
      sections.add(restSection);
      used += PromptBudget.estimateTokens(restSection);
    }

    // ── 4. Memory summaries ────────────────────────────────────────────────
    final memSection = _renderMemoriesSection(
      context.memories,
      budget.memoriesTokens,
    );
    if (memSection != null &&
        used + PromptBudget.estimateTokens(memSection) <= budget.maxTokens) {
      sections.add(memSection);
    }

    if (sections.isEmpty) return userQuestion;

    final buf = StringBuffer();
    for (final s in sections) {
      buf.writeln(s);
      buf.writeln();
    }
    buf.write('## Question\n$userQuestion');
    return buf.toString();
  }

  String? _renderNotesSection(
    String heading,
    List<ScoredNote> notes,
    int tokenCap,
  ) {
    if (notes.isEmpty) return null;
    final buf = StringBuffer('## $heading\n');
    var used = 0;
    var any = false;
    for (final n in notes) {
      final line = '• ${n.content}\n';
      final lineTokens = PromptBudget.estimateTokens(line);
      if (used + lineTokens > tokenCap && any) break;
      buf.write(line);
      used += lineTokens;
      any = true;
    }
    return any ? buf.toString().trimRight() : null;
  }

  String? _renderRelationsSection(
    List<GraphEdgeEntity> edges,
    List<GraphNodeEntity> nodes,
    int tokenCap,
  ) {
    if (edges.isEmpty) return null;
    final nameByKey = {for (final n in nodes) n.key: n.name};
    // Dedupe by (sourceKey, targetKey, relationType) — the same fact can be
    // asserted by multiple notes, but we only want to tell the model once.
    final seen = <String>{};
    final buf = StringBuffer('## Related Concepts\n');
    var used = 0;
    var any = false;
    for (final e in edges) {
      final key = '${e.sourceKey}|${e.relationType}|${e.targetKey}';
      if (!seen.add(key)) continue;
      final src = nameByKey[e.sourceKey] ?? e.sourceKey;
      final tgt = nameByKey[e.targetKey] ?? e.targetKey;
      final line = '- $src → ${e.relationType} → $tgt\n';
      final lineTokens = PromptBudget.estimateTokens(line);
      if (used + lineTokens > tokenCap && any) break;
      buf.write(line);
      used += lineTokens;
      any = true;
    }
    return any ? buf.toString().trimRight() : null;
  }

  String? _renderMemoriesSection(
    List<MemoryNodeEntity> memories,
    int tokenCap,
  ) {
    if (memories.isEmpty) return null;
    final buf = StringBuffer('## Summaries\n');
    var used = 0;
    var any = false;
    for (final m in memories) {
      if (m.summary.trim().isEmpty) continue;
      final line = '- ${_shortNoteId(m.noteId)}: ${m.summary}\n';
      final lineTokens = PromptBudget.estimateTokens(line);
      if (used + lineTokens > tokenCap && any) break;
      buf.write(line);
      used += lineTokens;
      any = true;
    }
    return any ? buf.toString().trimRight() : null;
  }

  String _shortNoteId(String noteId) =>
      noteId.length > 12 ? noteId.substring(0, 12) : noteId;

  // ── Extraction (one-shot, not user-facing) ────────────────────────────────

  /// Builds the strict-JSON extraction prompt used by [ExtractKnowledgeUseCase].
  /// Sent to Gemma via [AIModelRunner.generateOneShot]. Similar notes give the
  /// model context to link concepts to existing entries.
  String buildExtractionPrompt({
    required String noteContent,
    required List<ScoredNote> similarNotes,
  }) {
    final buf = StringBuffer();
    buf.writeln(
      'Extract structured knowledge from NEW_NOTE. Use SIMILAR_NOTES only as context to align entity names.',
    );
    buf.writeln();
    buf.writeln('NEW_NOTE:');
    buf.writeln(noteContent);
    buf.writeln();
    if (similarNotes.isNotEmpty) {
      buf.writeln('SIMILAR_NOTES:');
      for (final s in similarNotes) {
        buf.writeln('- id:${s.noteId}  ${s.content}');
      }
      buf.writeln();
    }
    buf.writeln('Return ONLY valid minified JSON with this exact shape:');
    buf.writeln('{');
    buf.writeln(
        '  "summary": "<2-4 sentence summary of NEW_NOTE in the user\'s own words>",');
    buf.writeln('  "keyPoints": ["<short fact 1>", "<short fact 2>"],');
    buf.writeln('  "concepts": ["<entity A>", "<entity B>"],');
    buf.writeln(
        '  "relations": [{"source":"<entity>","target":"<entity>","type":"<verb>"}],');
    buf.writeln(
        '  "links": ["<id of a similar_note that is clearly related, else omit>"]');
    buf.writeln('}');
    buf.writeln('Rules:');
    buf.writeln(
        '- Replace EVERY angle-bracket placeholder with a real value drawn from NEW_NOTE. Never output the placeholder text itself.');
    buf.writeln('- Entity names lowercase (e.g. "sam", "raj", "mysql", "node_js", "pc", "uniun").');
    buf.writeln(
        '- Relation "type" is a short freeform verb or snake_case phrase that describes the ACTUAL relationship in NEW_NOTE. Pick whatever fits the text — do not default to "uses".');
    buf.writeln(
        '  Examples across domains: uses, runs_on, depends_on, part_of, stores, produces, improves, replaces, measured_by,');
    buf.writeln(
        '  is_mother_of, is_father_of, friend_of, married_to, works_at, lives_in, located_in, born_in,');
    buf.writeln(
        '  happened_before, happened_after, caused_by, treated_with, symptom_of, similar_to, opposite_of.');
    buf.writeln(
        '  If none fit, invent a short snake_case verb that does.');
    buf.writeln(
        '- Summary must paraphrase NEW_NOTE in plain language; never output instruction fragments like "2-4 line summary".');
    buf.writeln(
        '- No prose outside the JSON. No markdown fences. No code blocks.');
    return buf.toString();
  }
}
