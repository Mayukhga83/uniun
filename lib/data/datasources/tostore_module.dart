import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:tostore/tostore.dart';

/// Dedicated table for note embeddings. Schema evolves with the embedding
/// model — Gecko 110M → 1024-dim float32.
///
/// Table shape:
///   - id: string primary key = Nostr event ID
///   - embedding: 1024-dim vector (cosine distance)
const String _embeddingsTable = 'note_embeddings';
const String embeddingsTableName = _embeddingsTable;
const String embeddingsIdField = 'id';
const String embeddingsVectorField = 'embedding';
const int embeddingsDimensions = 1024;

const TableSchema _embeddingsSchema = TableSchema(
  name: _embeddingsTable,
  primaryKeyConfig: PrimaryKeyConfig(
    name: embeddingsIdField,
    type: PrimaryKeyType.none,
  ),
  fields: [
    FieldSchema(
      name: embeddingsVectorField,
      type: DataType.vector,
      vectorConfig: VectorFieldConfig(
        dimensions: embeddingsDimensions,
        precision: VectorPrecision.float32,
      ),
    ),
  ],
  indexes: [
    IndexSchema(
      fields: [embeddingsVectorField],
      type: IndexType.vector,
      vectorConfig: VectorIndexConfig(
        indexType: VectorIndexType.ngh,
        distanceMetric: VectorDistanceMetric.cosine,
        maxDegree: 32,
        efSearch: 64,
      ),
    ),
  ],
);

/// Chunk vectors of indexed PDFs, in a SEPARATE [ToStore] instance from the
/// note embeddings.
///
/// Two reasons not to share the note store:
///   * **Recall** — a shared table would let chunk hits consume the top-K of
///     every existing note search, silently lowering note recall for callers
///     that never asked about documents.
///   * **Migration risk** — adding a table to the live store is a schema change
///     against the user's whole note index. A second store in its own directory
///     cannot touch the first.
///
/// Table shape: id = `"<sha256>:<ordinal>"` (see `chunkIdOf`), embedding =
/// 1024-dim, cosine.
const String documentChunkEmbeddingsTableName = 'document_chunk_embeddings';

const TableSchema documentChunkEmbeddingsSchema = TableSchema(
  name: documentChunkEmbeddingsTableName,
  primaryKeyConfig: PrimaryKeyConfig(
    name: embeddingsIdField,
    type: PrimaryKeyType.none,
  ),
  fields: [
    FieldSchema(
      name: embeddingsVectorField,
      type: DataType.vector,
      vectorConfig: VectorFieldConfig(
        dimensions: embeddingsDimensions,
        precision: VectorPrecision.float32,
      ),
    ),
  ],
  indexes: [
    IndexSchema(
      fields: [embeddingsVectorField],
      type: IndexType.vector,
      vectorConfig: VectorIndexConfig(
        indexType: VectorIndexType.ngh,
        distanceMetric: VectorDistanceMetric.cosine,
        maxDegree: 32,
        efSearch: 64,
      ),
    ),
  ],
);

/// Opens a single [ToStore] instance at `<documents>/tostore` and registers
/// it as an app-wide singleton. The embedding schema is set up on first open.
@module
abstract class TostoreModule {
  @singleton
  @preResolve
  Future<ToStore> createTostore() async {
    final docDir = await getApplicationDocumentsDirectory();
    // Path carries the embedding dimension. The model changed (384-dim
    // all-MiniLM → 1024-dim Gecko), and a per-dimension path forces a fresh
    // vector store on any dimension change instead of colliding with old-size
    // vectors; notes re-embed as they flow through EmbedAndStoreNoteUseCase.
    final dbRoot = p.join(docDir.path, 'tostore_${embeddingsDimensions}d');
    return ToStore.open(
      dbPath: dbRoot,
      schemas: [_embeddingsSchema],
    );
  }

  /// The document-chunk vector store, at `<documents>/tostore_docs_<dim>d`.
  /// Named so injection can tell it from the note store above.
  @Named('documentTostore')
  @singleton
  @preResolve
  Future<ToStore> createDocumentTostore() async {
    final docDir = await getApplicationDocumentsDirectory();
    final dbRoot = p.join(docDir.path, 'tostore_docs_${embeddingsDimensions}d');
    return ToStore.open(
      dbPath: dbRoot,
      schemas: [documentChunkEmbeddingsSchema],
    );
  }
}
