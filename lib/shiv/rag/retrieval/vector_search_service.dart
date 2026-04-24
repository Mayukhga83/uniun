import 'package:injectable/injectable.dart';
import 'package:uniun/domain/entities/shiv/scored_note.dart';
import 'package:uniun/domain/usecases/vector_usecases.dart';

/// Retrieves the top-K notes most semantically similar to a query vector.
///
/// Delegates to [SearchVectorNotesUseCase] — the underlying storage
/// (currently Tostore) is an implementation detail of [VectorRepository].
@lazySingleton
class VectorSearchService {
  final SearchVectorNotesUseCase _searchUseCase;

  VectorSearchService(this._searchUseCase);

  Future<List<ScoredNote>> search({
    required List<double> queryVector,
    int topK = 5,
    double minScore = 0.3,
  }) async {
    final result = await _searchUseCase((queryVector, topK, minScore));
    return result.fold(
      (failure) => [],
      (notes) => notes,
    );
  }
}
