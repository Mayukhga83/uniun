import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/core/usecases/usecase.dart';
import 'package:uniun/domain/entities/shiv/scored_note.dart';
import 'package:uniun/domain/repositories/vector_repository.dart';
import 'package:uniun/shiv/rag/embedding/embedding_service.dart';

@lazySingleton
class SearchVectorNotesUseCase
    extends UseCase<Either<Failure, List<ScoredNote>>, List<double>> {
  final VectorRepository _repository;

  SearchVectorNotesUseCase(this._repository);

  @override
  Future<Either<Failure, List<ScoredNote>>> call(List<double> input,
      {bool cached = false}) async {
    try {
      final result = await _repository.search(input);
      return Right(result);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }
}

/// Embeds [content] via [EmbeddingService] and persists the vector via
/// [VectorRepository]. Single use case — callers never touch EmbeddingService.
///
/// Input: (eventId, content) tuple.
/// Fire-and-forget safe — returns void, silently no-ops if model not ready.
@lazySingleton
class EmbedAndStoreNoteUseCase
    extends UseCase<void, (String, String)> {
  final EmbeddingService _embedding;
  final VectorRepository _vector;

  EmbedAndStoreNoteUseCase(this._embedding, this._vector);

  @override
  Future<void> call((String, String) input, {bool cached = false}) async {
    final (eventId, content) = input;
    try {
      final vec = await _embedding.embed(content);
      if (vec.isNotEmpty) {
        await _vector.upsert(eventId, vec);
      }
    } catch (_) {
      // Fire-and-forget — embedding failure must never crash the caller.
    }
  }
}
