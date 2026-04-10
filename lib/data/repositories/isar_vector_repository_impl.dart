import 'dart:math';

import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/data/models/note_model.dart';
import 'package:uniun/data/models/saved_note_model.dart';
import 'package:uniun/domain/entities/shiv/scored_note.dart';
import 'package:uniun/domain/repositories/vector_repository.dart';

/// Isar-backed implementation of [VectorRepository].
///
/// Vectors are stored inline with [SavedNoteModel] and [NoteModel] in Isar.
/// Search loads all embeddings into memory and scores them with brute-force
/// cosine similarity — suitable for up to ~5 000 notes without a native index.
///
/// To switch to a dedicated vector DB (e.g. tostore), replace this class
/// with a new implementation of [VectorRepository] and re-register it in DI.
/// Nothing above this layer changes.
@Injectable(as: VectorRepository)
class IsarVectorRepositoryImpl implements VectorRepository {
  final Isar _isar;

  IsarVectorRepositoryImpl(this._isar);

  // ── Write ──────────────────────────────────────────────────────────────────

  @override
  Future<void> upsert(String id, List<double> vector) async {
    await _isar.writeTxn(() async {
      // Try saved (bookmarked) notes first.
      final saved = await _isar.savedNoteModels
          .where()
          .eventIdEqualTo(id)
          .findFirst();
      if (saved != null) {
        saved.embedding = vector;
        await _isar.savedNoteModels.put(saved);
        return;
      }

      // Fall back to own authored notes.
      final own = await _isar.noteModels
          .filter()
          .eventIdEqualTo(id)
          .findFirst();
      if (own != null) {
        own.embedding = vector;
        await _isar.noteModels.put(own);
      }
    });
  }

  @override
  Future<void> delete(String id) async {
    await _isar.writeTxn(() async {
      final saved = await _isar.savedNoteModels
          .where()
          .eventIdEqualTo(id)
          .findFirst();
      if (saved != null) {
        saved.embedding = null;
        await _isar.savedNoteModels.put(saved);
        return;
      }

      final own = await _isar.noteModels
          .filter()
          .eventIdEqualTo(id)
          .findFirst();
      if (own != null) {
        own.embedding = null;
        await _isar.noteModels.put(own);
      }
    });
  }

  // ── Search ─────────────────────────────────────────────────────────────────

  @override
  Future<List<ScoredNote>> search(
    List<double> queryVector, {
    int topK = 5,
    double minScore = 0.3,
  }) async {
    if (queryVector.isEmpty) return [];

    final seen = <String>{};
    final candidates = <ScoredNote>[];

    // 1 — Saved (bookmarked) notes — query for non-null embeddings.
    final saved = await _isar.savedNoteModels
        .filter()
        .embeddingIsNotEmpty()
        .findAll();
    for (final n in saved) {
      if (!seen.add(n.eventId)) continue;
      final score = _cosine(queryVector, n.embedding!);
      if (score >= minScore) {
        candidates.add(ScoredNote(noteId: n.eventId, score: score, content: n.content));
      }
    }

    // 2 — Own authored notes — query for non-null embeddings.
    final own = await _isar.noteModels
        .filter()
        .embeddingIsNotEmpty()
        .findAll();
    for (final n in own) {
      if (!seen.add(n.eventId)) continue;
      final score = _cosine(queryVector, n.embedding!);
      if (score >= minScore) {
        candidates.add(ScoredNote(noteId: n.eventId, score: score, content: n.content));
      }
    }

    candidates.sort((a, b) => b.score.compareTo(a.score));
    return candidates.take(topK).toList();
  }

  // ── Cosine similarity ──────────────────────────────────────────────────────

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
