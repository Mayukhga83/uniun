import 'package:dartz/dartz.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/domain/entities/shiv/document_citation.dart';

abstract class DocumentSourceRepository {
  /// Resolves chunk ids to citations, preserving the order given.
  ///
  /// Ids that no longer resolve — a purged chunk, an uncached file, a malformed
  /// id — are skipped rather than reported: a stale citation is an expected
  /// outcome once retention or a manual delete has run.
  Future<Either<Failure, List<DocumentCitation>>> resolve(List<String> chunkIds);
}
