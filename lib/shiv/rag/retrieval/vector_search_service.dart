import 'dart:math';

import 'package:injectable/injectable.dart';
import 'package:uniun/domain/usecases/note_usecases.dart';
import 'package:uniun/domain/usecases/saved_note_usecases.dart';
import 'package:uniun/domain/usecases/user_usecases.dart';
import 'package:uniun/shiv/rag/retrieval/scored_note.dart';

/// Loads embeddings from both [SavedNoteModel] (bookmarked notes) and
/// [NoteModel] (notes authored by the logged-in user) and returns the
/// top-K most similar notes to a query vector using cosine similarity.
///
/// Suitable for up to ~5 000 notes combined without a native vector index.
@lazySingleton
class VectorSearchService {
  final GetAllSavedNotesUseCase _getAllSavedNotes;
  final GetActiveUserUseCase _getActiveUser;
  final GetOwnNotesUseCase _getOwnNotes;

  VectorSearchService(
    this._getAllSavedNotes,
    this._getActiveUser,
    this._getOwnNotes,
  );

  /// Returns up to [topK] notes whose cosine similarity to [queryVector]
  /// is at or above [minScore], sorted highest-first.
  /// Searches saved notes + own authored notes — deduped by eventId.
  Future<List<ScoredNote>> search({
    required List<double> queryVector,
    int topK = 5,
    double minScore = 0.3,
  }) async {
    if (queryVector.isEmpty) return [];

    final seen = <String>{};
    final candidates = <ScoredNote>[];

    // 1 — Saved notes (bookmarked by user)
    final savedResult = await _getAllSavedNotes.call();
    savedResult.fold((_) {}, (notes) {
      for (final n in notes) {
        if (n.embedding == null || n.embedding!.isEmpty) continue;
        if (!seen.add(n.eventId)) continue;
        final score = _cosineSimilarity(queryVector, n.embedding!);
        if (score >= minScore) {
          candidates.add(ScoredNote(noteId: n.eventId, score: score, content: n.content));
        }
      }
    });

    // 2 — Own authored notes (created by user in Brahma)
    final userResult = await _getActiveUser.call();
    final pubkey = userResult.fold((_) => null, (u) => u.pubkeyHex);
    if (pubkey != null) {
      final ownResult = await _getOwnNotes.call(pubkey);
      ownResult.fold((_) {}, (notes) {
        for (final n in notes) {
          if (n.embedding == null || n.embedding!.isEmpty) continue;
          if (!seen.add(n.id)) continue;
          final score = _cosineSimilarity(queryVector, n.embedding!);
          if (score >= minScore) {
            candidates.add(ScoredNote(noteId: n.id, score: score, content: n.content));
          }
        }
      });
    }

    candidates.sort((a, b) => b.score.compareTo(a.score));
    return candidates.take(topK).toList();
  }

  // ── Cosine similarity (pure Dart, no native deps) ─────────────────────────

  static double _cosineSimilarity(List<double> a, List<double> b) {
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
