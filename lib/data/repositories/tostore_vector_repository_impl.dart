import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:tostore/tostore.dart';
import 'package:uniun/data/datasources/tostore_module.dart';
import 'package:uniun/data/models/notes/note_model.dart';
import 'package:uniun/data/models/saved_note_model.dart';
import 'package:uniun/domain/entities/shiv/scored_note.dart';
import 'package:uniun/domain/repositories/vector_repository.dart';

/// Tostore-backed implementation of [VectorRepository].
///
/// Vectors live in a dedicated Tostore table (`note_embeddings`) keyed by
/// Nostr event ID. Note content is still read from Isar
/// ([SavedNoteModel] / [NoteModel]) — Tostore only stores the vector and
/// the event ID.
///
/// ## Two-tier search (required because of Tostore's PQ training threshold)
/// Tostore's NGH index uses Product Quantization and only starts returning
/// results once **at least 100 vectors** have been upserted — the PQ codebook
/// needs that many samples to train centroids. Until then `vectorSearch`
/// returns `const []` regardless of the query.
///
/// So:
/// 1. Try Tostore's NGH `vectorSearch` (fast ANN).
/// 2. While the table is below [_linearScanCutoff] vectors, if NGH came back
///    empty, fall back to a brute-force cosine scan over an in-memory cache.
/// 3. Once the table has ≥ [_linearScanCutoff] vectors, the fallback is
///    disabled — NGH is trained and authoritative, any empty result means
///    "no similar vectors" for real.
///
/// The cache is hydrated from Tostore on first use so it survives app restart.
@LazySingleton(as: VectorRepository)
class TostoreVectorRepositoryImpl implements VectorRepository {
  final ToStore _tostore;
  final Isar _isar;

  /// Tostore's NGH PQ codebook trains at ≥ 100 samples (see
  /// `vector_index_manager.dart: if (samples.length >= 100)` in tostore
  /// 3.1.0). Below this we cannot rely on `vectorSearch` and must linear-scan.
  static const int _linearScanCutoff = 100;

  /// In-memory mirror of every vector upserted in this app session. Rebuilt
  /// lazily from Tostore on the first search after restart.
  final Map<String, List<double>> _cache = {};
  bool _cacheHydrated = false;

  TostoreVectorRepositoryImpl(this._tostore, this._isar);

  @override
  Future<void> upsert(String id, List<double> vector) async {
    if (vector.isEmpty) return;
    _cache[id] = List<double>.unmodifiable(vector);
    await _tostore.upsert(embeddingsTableName, {
      embeddingsIdField: id,
      embeddingsVectorField: vector,
    });
  }

  @override
  Future<void> delete(String id) async {
    _cache.remove(id);
    await _tostore
        .delete(embeddingsTableName)
        .where(embeddingsIdField, '=', id);
  }

  @override
  Future<List<ScoredNote>> search(
    List<double> queryVector, {
    int topK = 5,
    double minScore = 0.3,
  }) async {
    if (queryVector.isEmpty) return const [];

    // ── Tier 1: Tostore NGH vector search ──────────────────────────────────
    final hits = await _tostore.vectorSearch(
      embeddingsTableName,
      fieldName: embeddingsVectorField,
      queryVector: VectorData.fromList(queryVector),
      topK: topK,
    );
    debugPrint('🔍 Tostore.vectorSearch → ${hits.length} raw hit(s)');
    if (hits.isNotEmpty) {
      final results = <ScoredNote>[];
      for (final h in hits) {
        if (h.score < minScore) continue;
        final content = await _lookupContent(h.primaryKey);
        if (content == null) continue;
        results.add(ScoredNote(
          noteId: h.primaryKey,
          score: h.score,
          content: content,
        ));
      }
      debugPrint('🔍 Tostore ANN returning ${results.length} ScoredNote(s)');
      return results;
    }

    // ── Tier 2: linear-scan fallback (only while Tostore's PQ hasn't trained)
    if (!_cacheHydrated) await _hydrateCache();
    if (_cache.length >= _linearScanCutoff) {
      // NGH is trained but still returned 0 — trust it.
      debugPrint(
          '🔍 NGH trained (${_cache.length} ≥ $_linearScanCutoff) — skipping linear fallback');
      return const [];
    }
    if (_cache.isEmpty) {
      debugPrint('🔍 Linear scan: cache empty, no fallback possible');
      return const [];
    }
    return _linearScan(queryVector, topK: topK, minScore: minScore);
  }

  Future<List<ScoredNote>> _linearScan(
    List<double> query, {
    required int topK,
    required double minScore,
  }) async {
    final scored = <(String, double)>[];
    for (final entry in _cache.entries) {
      final s = _cosine(query, entry.value);
      if (s >= minScore) scored.add((entry.key, s));
    }
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    final top = scored.take(topK).toList();
    debugPrint(
        '🔍 Linear scan: ${_cache.length} vector(s), ${top.length} hit(s) ≥ $minScore');

    final out = <ScoredNote>[];
    for (final (id, score) in top) {
      final content = await _lookupContent(id);
      if (content == null) continue;
      out.add(ScoredNote(noteId: id, score: score, content: content));
    }
    return out;
  }

  /// Loads all embeddings from Tostore into [_cache] on first miss. Handles
  /// app restart: NGH index may be cold, but the rows are persisted — read
  /// them back so linear scan works immediately.
  Future<void> _hydrateCache() async {
    _cacheHydrated = true;
    try {
      final rs = await _tostore.query(embeddingsTableName);
      final rows = rs.data;
      var added = 0;
      for (final row in rows) {
        final id = row[embeddingsIdField];
        final rawVec = row[embeddingsVectorField];
        if (id is! String) continue;
        final vec = _toDoubleList(rawVec);
        if (vec == null || vec.isEmpty) continue;
        _cache[id] = List<double>.unmodifiable(vec);
        added++;
      }
      debugPrint('🔁 Cache hydrated from Tostore: $added vector(s)');
    } catch (e) {
      debugPrint('⚠️ Cache hydrate failed: $e');
    }
  }

  /// Tostore may return the vector field as List<double>, List<num>,
  /// VectorData, or (in some builds) a primitive list — accept all shapes.
  List<double>? _toDoubleList(dynamic v) {
    if (v == null) return null;
    if (v is VectorData) return List<double>.from(v.values);
    if (v is List<double>) return v;
    if (v is List) {
      try {
        return v.map((e) => (e as num).toDouble()).toList();
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<String?> _lookupContent(String eventId) async {
    final saved = await _isar.savedNoteModels
        .where()
        .eventIdEqualTo(eventId)
        .findFirst();
    if (saved != null) return saved.content;
    final own = await _isar.noteModels
        .filter()
        .eventIdEqualTo(eventId)
        .findFirst();
    return own?.content;
  }

  static double _cosine(List<double> a, List<double> b) {
    if (a.length != b.length || a.isEmpty) return 0.0;
    double dot = 0, normA = 0, normB = 0;
    for (var i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    if (normA == 0 || normB == 0) return 0.0;
    return dot / (sqrt(normA) * sqrt(normB));
  }
}
