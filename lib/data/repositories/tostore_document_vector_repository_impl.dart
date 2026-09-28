import 'dart:math' as math;

import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:tostore/tostore.dart';
import 'package:uniun/data/datasources/tostore_module.dart';
import 'package:uniun/data/models/documents/document_chunk_model.dart';
import 'package:uniun/domain/entities/shiv/scored_chunk.dart';
import 'package:uniun/domain/repositories/document_vector_repository.dart';

/// PDF chunk vectors in their own ToStore, with text resolved from Isar.
///
/// Mirrors `TostoreVectorRepositoryImpl` (notes) but against
/// [documentChunkEmbeddingsTableName] in the `documentTostore` instance.
@LazySingleton(as: DocumentVectorRepository)
class TostoreDocumentVectorRepositoryImpl implements DocumentVectorRepository {
  TostoreDocumentVectorRepositoryImpl(
    @Named('documentTostore') this._tostore,
    this._isar,
  );

  final ToStore _tostore;
  final Isar _isar;

  /// How many raw hits to pull per requested result, to absorb orphaned
  /// vectors whose Isar row is gone.
  static const int _orphanOverfetch = 4;

  /// Ceiling on the over-fetch, so a large topK cannot turn into a huge scan.
  static const int _maxFetch = 40;

  @override
  Future<void> upsert(String chunkId, List<double> vector) async {
    if (vector.isEmpty) return;
    await _tostore.upsert(documentChunkEmbeddingsTableName, {
      embeddingsIdField: chunkId,
      embeddingsVectorField: vector,
    });
    // Flush so the id → PK index is written before any search.
    await _tostore.flush();
  }

  @override
  Future<List<ScoredChunk>> search(
    List<double> queryVector, {
    int topK = 3,
    double minScore = 0.3,
  }) async {
    if (queryVector.isEmpty) return const [];

    // Over-fetch: vectors of purged chunks stay in the store (see
    // DocumentVectorRepository — ToStore cannot delete without destroying the
    // index), so some hits resolve to nothing. Asking for more than we need
    // keeps those orphans from starving the result set.
    final hits = await _tostore.vectorSearch(
      documentChunkEmbeddingsTableName,
      fieldName: embeddingsVectorField,
      queryVector: VectorData.fromList(queryVector),
      topK: math.min(topK * _orphanOverfetch, _maxFetch),
    );

    final results = <ScoredChunk>[];
    for (final h in hits) {
      if (results.length == topK) break;
      if (h.score < minScore) continue;
      final ref = parseChunkId(h.primaryKey);
      if (ref == null) continue;
      final row = await _isar.documentChunkModels
          .where()
          .sha256OrdinalEqualTo(ref.sha256, ref.ordinal)
          .findFirst();
      // The chunk row can vanish between the vector search and this lookup (a
      // purge racing a query); skip rather than return a hit with no text.
      if (row == null) continue;
      results.add(ScoredChunk(
        chunkId: h.primaryKey,
        sha256: row.sha256,
        label: row.label,
        score: h.score,
        content: row.text,
      ));
    }
    return results;
  }
}
