import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:tostore/tostore.dart';

/// Dedicated table for note embeddings. Schema evolves with the embedding
/// model — all-MiniLM-L6-v2 → 384-dim float32.
///
/// Table shape:
///   - id: string primary key = Nostr event ID
///   - embedding: 384-dim vector (cosine distance)
const String _embeddingsTable = 'note_embeddings';
const String embeddingsTableName = _embeddingsTable;
const String embeddingsIdField = 'id';
const String embeddingsVectorField = 'embedding';
const int embeddingsDimensions = 384;

const TableSchema _embeddingsSchema = TableSchema(
  name: _embeddingsTable,
  primaryKeyConfig: PrimaryKeyConfig(
    name: embeddingsIdField,
    type: PrimaryKeyType.none,
  ),
  fields: [
    FieldSchema(
      name: embeddingsIdField,
      type: DataType.text,
      unique: true,
    ),
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
    final dbRoot = p.join(docDir.path, 'tostore');
    return ToStore.open(
      dbPath: dbRoot,
      schemas: [_embeddingsSchema],
    );
  }
}
