import 'package:uniun/domain/entities/shiv/scored_chunk.dart';

/// Vector storage and similarity search over PDF chunks.
///
/// Sibling of `VectorRepository` (notes), deliberately separate so the note
/// retrieval path is untouched by document indexing.
///
/// **There is no delete.** ToStore 3.1.0 destroys a table's entire vector index
/// on any row delete — measured: after deleting 1 of 3 rows, `vectorSearch`
/// returns nothing, and the index does not recover across a close/reopen. So
/// chunk existence is owned by Isar (`DocumentChunkModel`) instead: purging a
/// document deletes its Isar rows, [search] skips any hit it cannot resolve
/// back to a row, and the orphaned vectors are simply never returned.
///
/// **Known limit:** orphans still occupy slots in the raw similarity scan.
/// [search] over-fetches to absorb them, which covers the realistic case (a
/// purged document is rarely more similar to a query than the document that
/// answers it), but enough equally-similar orphans can crowd out a real chunk.
/// The fix is a rebuild — wipe the store and re-embed from the surviving
/// `DocumentChunkModel` rows, whose text is all still there — which is not
/// implemented yet.
abstract class DocumentVectorRepository {
  /// Store or replace the vector for [chunkId] (see `chunkIdOf`).
  ///
  /// Re-indexing a document reuses the same ids, so this replaces in place and
  /// leaves no orphans; orphans arise only when a document is removed or
  /// re-indexes to fewer chunks.
  Future<void> upsert(String chunkId, List<double> vector);

  /// Up to [topK] chunks whose cosine similarity to [queryVector] is at least
  /// [minScore], best first, with their text and page label resolved from Isar.
  Future<List<ScoredChunk>> search(
    List<double> queryVector, {
    int topK = 3,
    double minScore = 0.3,
  });
}
