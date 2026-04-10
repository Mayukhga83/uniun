/// A note paired with its cosine-similarity score against a query vector.
/// May come from [SavedNoteModel] (bookmarked) or [NoteModel] (own authored).
class ScoredNote {
  const ScoredNote({
    required this.noteId,
    required this.score,
    required this.content,
  });

  /// The Nostr event ID of the note.
  final String noteId;

  /// Cosine similarity in [0, 1]. Higher = more relevant.
  final double score;

  /// The text content of the note — injected into the RAG prompt.
  final String content;
}
