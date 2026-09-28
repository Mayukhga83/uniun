import 'package:isar_community/isar.dart';

part 'document_chunk_model.g.dart';

/// One retrievable piece of an indexed PDF.
///
/// RAG infrastructure, not a Note — it sits beside `MemoryNodeModel`, so the
/// one-Note-collection rule is untouched. The chunk's embedding lives in
/// ToStore under `chunkIdOf(sha256, ordinal)`, never here: Isar holds the text,
/// the vector store holds the vector, joined by that id.
@Collection(ignore: {'copyWith'})
@Name('DocumentChunk')
class DocumentChunkModel {
  Id id = Isar.autoIncrement;

  /// The blob's SHA-256 — joins to [MediaCacheModel.sha256].
  @Index(composite: [CompositeIndex('ordinal')], unique: true, replace: true)
  late String sha256;

  /// Position across the whole document, `0..n-1`.
  late int ordinal;

  /// 1-based page number, carried so a citation to "page 2" can be verified.
  late String label;

  late String text;
}
