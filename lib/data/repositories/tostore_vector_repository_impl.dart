import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:tostore/tostore.dart';
import 'package:uniun/data/datasources/tostore_module.dart';
import 'package:uniun/data/models/notes/note_model.dart';
import 'package:uniun/data/models/saved_note_model.dart';
import 'package:uniun/domain/entities/shiv/scored_note.dart';
import 'package:uniun/domain/repositories/vector_repository.dart';

@LazySingleton(as: VectorRepository)
class TostoreVectorRepositoryImpl implements VectorRepository {
  final ToStore _tostore;
  final Isar _isar;

  TostoreVectorRepositoryImpl(this._tostore, this._isar);

  @override
  Future<void> upsert(String id, List<double> vector) async {
    if (vector.isEmpty) return;
    await _tostore.upsert(embeddingsTableName, {
      embeddingsIdField: id,
      embeddingsVectorField: vector,
    });
    // Flush so the nodeId→PK B+Tree index is written before any search.
    await _tostore.flush();
  }

  @override
  Future<void> delete(String id) async {
    await _tostore.delete(embeddingsTableName).where(embeddingsIdField, '=', id);
  }

  @override
  Future<List<ScoredNote>> search(
    List<double> queryVector, {
    int topK = 5,
    double minScore = 0.3,
  }) async {
    if (queryVector.isEmpty) return const [];

    final hits = await _tostore.vectorSearch(
      embeddingsTableName,
      fieldName: embeddingsVectorField,
      queryVector: VectorData.fromList(queryVector),
      topK: topK,
    );
    debugPrint('🔍 Tostore.vectorSearch → ${hits.length} raw hit(s)');

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
}
