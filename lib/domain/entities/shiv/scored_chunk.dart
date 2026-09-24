/// A PDF chunk paired with its cosine similarity to a query vector.
///
/// Sibling of `ScoredNote`; [content] is what gets injected into the RAG prompt.
class ScoredChunk {
  const ScoredChunk({
    required this.chunkId,
    required this.sha256,
    required this.label,
    required this.score,
    required this.content,
  });

  /// `"<sha256>:<ordinal>"` — see [chunkIdOf].
  final String chunkId;

  /// The document's blob hash, joining to `MediaCacheModel.sha256`.
  final String sha256;

  /// 1-based page number the chunk came from.
  final String label;

  /// Cosine similarity in [0, 1]. Higher = more relevant.
  final double score;

  final String content;
}

/// Stable id of chunk [ordinal] of the document with hash [sha256].
///
/// Used as the vector store's primary key and as the ephemeral id carried to
/// the Sources sheet.
String chunkIdOf(String sha256, int ordinal) => '$sha256:$ordinal';

/// Inverse of [chunkIdOf]; `null` for anything malformed.
///
/// A SHA-256 is hex and never contains a colon, so the last colon is the
/// separator.
({String sha256, int ordinal})? parseChunkId(String id) {
  final i = id.lastIndexOf(':');
  if (i <= 0 || i == id.length - 1) return null;
  final suffix = id.substring(i + 1);
  // Digits only: `int.tryParse` accepts surrounding whitespace and a leading
  // sign, so "sha: 1" would otherwise resolve to a chunk whose real id differs.
  if (!_digits.hasMatch(suffix)) return null;
  final ordinal = int.tryParse(suffix);
  if (ordinal == null) return null;
  return (sha256: id.substring(0, i), ordinal: ordinal);
}

final RegExp _digits = RegExp(r'^\d+$');
