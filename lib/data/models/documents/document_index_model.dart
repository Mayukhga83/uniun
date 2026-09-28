import 'package:isar_community/isar.dart';
import 'package:uniun/core/enum/document_kind.dart';

part 'document_index_model.g.dart';

enum DocumentIndexStatus {
  /// Text extracted, chunked, embedded and searchable.
  indexed,

  /// Kept and openable, but holds no usable text — a scan, or a file its
  /// reader cannot open. An expected outcome, not a failure.
  notSearchable,
}

/// One row per document the indexer has finished with, keyed by the blob's SHA-256.
///
/// Without it, "no chunks" cannot distinguish a scan from a document not yet
/// processed, and every scan would be re-extracted on every launch.
///
/// Written LAST in the indexing sequence, so a crash part-way leaves no row and
/// the document is retried rather than recorded as done.
@Collection(ignore: {'copyWith'})
@Name('DocumentIndex')
class DocumentIndexModel {
  Id id = Isar.autoIncrement;

  /// Joins to [MediaCacheModel.sha256].
  @Index(unique: true, replace: true)
  late String sha256;

  @Enumerated(EnumType.name)
  late DocumentIndexStatus status;

  /// Recorded when indexed, not re-derived from `MediaCacheModel.mime` later:
  /// every download or upload of the same blob overwrites that mime with
  /// whatever the sender claimed, and a heading must never render as a page.
  /// Defaults to `pdf`, which is what every row written before DOCX support was.
  @Enumerated(EnumType.name)
  DocumentKind kind = DocumentKind.pdf;

  /// Pages in a PDF; 0 for a DOCX, which has no fixed pagination.
  int pageCount = 0;
  int chunkCount = 0;

  late DateTime indexedAt;
}
