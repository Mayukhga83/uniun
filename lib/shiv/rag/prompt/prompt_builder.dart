import 'package:injectable/injectable.dart';
import 'package:uniun/shiv/rag/retrieval/scored_note.dart';

/// Data loaded once per session from Isar.
/// Personalises every prompt even when the user has zero saved notes.
class PersonalizationContext {
  const PersonalizationContext({
    this.userName,
    this.userBio,
  });

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

    buf.writeln('You are an AI assistant called Shiv, built into UNIUN. Always identify yourself as Shiv.');

    if (name != null && name.isNotEmpty) {
      buf.writeln('The user\'s name is $name (not yours — yours is Shiv).');
      if (bio != null && bio.isNotEmpty) {
        buf.writeln('About the user: $bio');
      }
    }

    buf.writeln('Answer concisely and helpfully.');

    print('🤖 System instruction built — name: $name, bio: $bio');

    return buf.toString().trimRight();
  }

  // ── Per-turn (called each message) ─────────────────────────────────────────

  /// Builds the user-turn message: optional RAG context block + the question.
  /// This is the ONLY thing added to [InferenceChat] per turn — no history,
  /// no system prompt repetition.
  String buildUserMessage({
    required String userQuestion,
    required List<ScoredNote> relevantNotes,
  }) {
    if (relevantNotes.isEmpty) return userQuestion;

    final buf = StringBuffer();
    buf.writeln('[Relevant notes from your knowledge base:]');
    for (final scored in relevantNotes) {
      buf.writeln('• ${scored.content}');
    }
    buf.writeln('[End of notes]');
    buf.writeln();
    buf.write(userQuestion);
    return buf.toString();
  }
}
