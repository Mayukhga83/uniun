import 'dart:math' as math;

import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/core/enum/document_kind.dart';
import 'package:uniun/data/models/documents/document_chunk_model.dart';
import 'package:uniun/data/models/documents/document_index_model.dart';
import 'package:uniun/domain/entities/shiv/scored_chunk.dart';
import 'package:uniun/domain/repositories/document_vector_repository.dart';

/// Document chunk vectors stored on the chunk rows themselves, searched by an
/// exact scan.
///
/// An approximate index (ToStore's graph) cannot reach every stored vector —
/// on a phone only 20 of 83 chunks found themselves — so a stored chunk could
/// never come back for any question. Comparing the query with every vector is
/// exact, and cheap at this scale: a few thousand 1024-dim vectors is a few
/// milliseconds of arithmetic.
@LazySingleton(as: DocumentVectorRepository)
class IsarDocumentVectorRepositoryImpl implements DocumentVectorRepository {
  IsarDocumentVectorRepositoryImpl(this._isar);

  final Isar _isar;

  /// Rows read per step, so a large library is never held in memory whole.
  static const int _batch = 400;

  @override
  Future<void> upsert(String chunkId, List<double> vector) async {
    if (vector.isEmpty) return;
    final ref = parseChunkId(chunkId);
    if (ref == null) return;
    await _isar.writeTxn(() async {
      final row = await _isar.documentChunkModels
          .where()
          .sha256OrdinalEqualTo(ref.sha256, ref.ordinal)
          .findFirst();
      // The chunk was purged while it was being embedded: nothing to attach to.
      if (row == null) return;
      await _isar.documentChunkModels.put(row..vector = vector);
    });
  }

  @override
  Future<List<ScoredChunk>> search(
    List<double> queryVector, {
    int topK = 3,
    double minScore = 0.3,
  }) async {
    if (queryVector.isEmpty || topK <= 0) return const [];
    final queryNorm = _norm(queryVector);
    if (queryNorm == 0) return const [];

    // Best topK so far, best first.
    final best = <({DocumentChunkModel row, double score})>[];
    for (var offset = 0; ; offset += _batch) {
      final rows = await _isar.documentChunkModels
          .where()
          .offset(offset)
          .limit(_batch)
          .findAll();
      if (rows.isEmpty) break;
      for (final row in rows) {
        final v = row.vector;
        if (v == null) continue;
        // A vector of another dimension (the model changed) is not comparable.
        if (v.length != queryVector.length) continue;
        final vNorm = _norm(v);
        if (vNorm == 0) continue;
        final score = _dot(queryVector, v) / (queryNorm * vNorm);
        if (score < minScore) continue;
        if (best.length == topK && score <= best.last.score) continue;
        best.add((row: row, score: score));
        best.sort((a, b) => b.score.compareTo(a.score));
        if (best.length > topK) best.removeLast();
      }
    }

    final results = <ScoredChunk>[];
    // One index lookup per document, not per hit.
    final kinds = <String, DocumentKind?>{};
    for (final hit in best) {
      final row = hit.row;
      final kind = kinds[row.sha256] ??=
          (await _isar.documentIndexModels.getBySha256(row.sha256))?.kind;
      // No index row: the document is mid-index or mid-purge, so its chunks
      // are not yet (or no longer) citable.
      if (kind == null) continue;
      results.add(
        ScoredChunk(
          chunkId: chunkIdOf(row.sha256, row.ordinal),
          sha256: row.sha256,
          kind: kind,
          label: row.label,
          score: hit.score,
          content: row.text,
        ),
      );
    }
    return results;
  }

  static double _norm(List<double> v) => math.sqrt(_dot(v, v));

  static double _dot(List<double> a, List<double> b) {
    var sum = 0.0;
    for (var i = 0; i < a.length; i++) {
      sum += a[i] * b[i];
    }
    return sum;
  }
}
