import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:tostore/tostore.dart';
import 'package:uniun/data/datasources/llm/embedding_queue.dart';
import 'package:uniun/data/datasources/tostore_module.dart';
import 'package:uniun/data/models/documents/document_chunk_model.dart';
import 'package:uniun/data/models/documents/document_index_model.dart';
import 'package:uniun/data/models/media/media_cache_model.dart';
import 'package:uniun/data/models/notes/note_model.dart';
import 'package:uniun/data/repositories/document_source_repository_impl.dart';
import 'package:uniun/data/repositories/tostore_document_vector_repository_impl.dart';
import 'package:uniun/domain/entities/llm/llm_model_info.dart';
import 'package:uniun/domain/entities/profile/profile_entity.dart';
import 'package:uniun/domain/entities/shiv/scored_chunk.dart';
import 'package:uniun/domain/entities/shiv/scored_note.dart';
import 'package:uniun/domain/repositories/vector_repository.dart';
import 'package:uniun/domain/usecases/saved_note_usecases.dart';
import 'package:uniun/domain/usecases/knowledge_usecases.dart';
import 'package:uniun/domain/usecases/llm_usecases.dart';
import 'package:uniun/domain/usecases/profile_usecases.dart';
import 'package:uniun/domain/usecases/user_usecases.dart';
import 'package:uniun/domain/usecases/vector_usecases.dart';
import 'package:uniun/features/shiv/generation/context/manas_context_loader.dart';
import 'package:uniun/features/shiv/rag/pipeline/rag_pipeline.dart';
import 'package:uniun/features/shiv/rag/prompt/prompt_builder.dart';
import 'package:uniun/features/shiv/rag/retrieval/vector_search_service.dart';
import 'package:uniun/features/shiv/rag/embedding/embedding_service.dart';
import 'package:uniun/features/shiv/rag/extraction/pdf_extraction_service.dart';
import 'package:uniun/data/datasources/pdf/pdf_text_source.dart';
import 'package:uniun/features/shiv/rag/indexing/pdf_indexer.dart';
import 'package:dartz/dartz.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:mocktail/mocktail.dart';

import '../_helpers/fake_path_provider.dart';
import '../_helpers/isar_seeds.dart';
import '../_helpers/isar_test_harness.dart';
import '../_helpers/pdf_fixtures.dart';
import '../_helpers/pdfium_test_lib.dart';

/// End-to-end PDF RAG flow against a real PDF, real PDFium, real Isar and a
/// real ToStore: cache row → extract → chunk → embed → store → retrieve →
/// citation. Only the embedder is faked (deterministic vectors) — it needs
/// flutter_gemma, which is device-only; `integration_test/pdf_rag_e2e_test.dart`
/// covers the real one.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Isar isar;
  late ToStore store;
  late Directory tmp;
  late PdfIndexer indexer;
  late TostoreDocumentVectorRepositoryImpl vectors;
  late DocumentSourceRepositoryImpl sources;
  late _StubEmbedding embedding;
  late ResolveDocumentCitationsUseCase resolveCitations;
  late VectorSearchService searchService;
  late _FakeNoteVectors noteVectors;

  const sha = 'nistsha';

  setUpAll(() async {
    registerFallbackValue(<String>[]);
    registerFallbackValue((<String>[], 1));
    final boot = await Directory.systemTemp.createTemp('pdf_rag_flow_boot');
    PathProviderPlatform.instance =
        FakePathProviderPlatform(docs: boot.path, support: boot.path);
    await ensurePdfium();
    await pdfrxFlutterInitialize();
  });

  setUp(() async {
    isar = await openTestIsar();
    tmp = await Directory.systemTemp.createTemp('pdf_rag_flow');
    store = await ToStore.open(
      dbPath: tmp.path,
      schemas: [documentChunkEmbeddingsSchema],
    );
    vectors = TostoreDocumentVectorRepositoryImpl(store, isar);
    sources = DocumentSourceRepositoryImpl(isar);
    embedding = _StubEmbedding();
    // Real use cases and service on top of the real repositories — only the
    // note vector store is doubled, since notes are not what this flow is about.
    noteVectors = _FakeNoteVectors();
    resolveCitations = ResolveDocumentCitationsUseCase(sources);
    searchService = VectorSearchService(
      SearchVectorNotesUseCase(noteVectors),
      SearchDocumentChunksUseCase(vectors),
    );
    indexer = PdfIndexer(
      isar,
      PdfExtractionService(PdfrxTextSource()),
      // Real use case over the real vector repository — only the embedder
      // itself is stubbed.
      EmbedAndStoreChunkUseCase(embedding, vectors, EmbeddingQueue()),
    );

    // The real fixture, registered in the cache exactly as a downloaded or
    // uploaded blob would be.
    await isar.writeTxn(() => isar.mediaCacheModels.put(mediaCacheRow(
          sha,
          localPath: pdfFixture('nist_sp800-145.pdf'),
          mime: 'application/pdf',
        )));
  });

  tearDown(() async {
    await indexer.dispose();
    await store.close();
    await tmp.delete(recursive: true);
    await isar.close(deleteFromDisk: true);
  });

  test('a cached PDF becomes retrievable and citable', () async {
    await indexer.reconcile();

    // Indexed, with the fixture's real page count.
    final row =
        await isar.documentIndexModels.filter().sha256EqualTo(sha).findFirst();
    expect(row?.status, DocumentIndexStatus.indexed);
    expect(row?.pageCount, 7);
    expect(row!.chunkCount, greaterThan(1));

    // A query shaped like the page-6 chunk retrieves that chunk...
    final target = await isar.documentChunkModels
        .where()
        .sha256EqualToAnyOrdinal(sha)
        .findAll()
        .then((all) => all.firstWhere(
            (c) => c.text.toLowerCase().contains('cloud computing is a model')));

    final hits = await vectors.search(embedding.vectorFor(target.text), topK: 3);

    expect(hits, isNotEmpty);
    expect(hits.first.chunkId, chunkIdOf(sha, target.ordinal));
    expect(hits.first.label, target.label,
        reason: 'the citation must carry the page the text came from');

    // ...and that hit resolves into a citation the Sources sheet can render.
    final citations =
        (await sources.resolve([hits.first.chunkId])).getOrElse(() => []);
    expect(citations, hasLength(1));
    expect(citations.single.localPath, endsWith('nist_sp800-145.pdf'));
    expect(citations.single.label, target.label);
  });

  test('the attaching note names the document in its citation', () async {
    await isar.writeTxn(() => isar.noteModels.put(noteRow('n1', attachments: [
          mediaAttachmentRow(
            sha256: sha,
            mime: 'application/pdf',
            filename: 'NIST Cloud Definition.pdf',
          )
        ])));

    await indexer.reconcile();
    final chunk = (await isar.documentChunkModels
            .where()
            .sha256EqualToAnyOrdinal(sha)
            .findAll())
        .first;

    final citations = (await sources.resolve([chunkIdOf(sha, chunk.ordinal)]))
        .getOrElse(() => []);

    expect(citations.single.title, 'NIST Cloud Definition.pdf');
  });

  test('removing the cached blob stops the document being cited', () async {
    await indexer.reconcile();
    final chunk = (await isar.documentChunkModels
            .where()
            .sha256EqualToAnyOrdinal(sha)
            .findAll())
        .first;
    final id = chunkIdOf(sha, chunk.ordinal);
    final query = embedding.vectorFor(chunk.text);
    expect(await vectors.search(query, topK: 3), isNotEmpty);

    await isar.writeTxn(() => isar.mediaCacheModels.deleteBySha256(sha));
    await indexer.reconcile();

    expect(await vectors.search(query, topK: 3), isEmpty,
        reason: 'purged chunks must stop surfacing even though the vector '
            'cannot be deleted from the store');
    expect((await sources.resolve([id])).getOrElse(() => []), isEmpty);
    expect(await isar.documentIndexModels.count(), 0);
  });

  group('through the real retrieval stack', () {
    late RagPipeline pipeline;

    /// Real embedding stub, real search service, real PromptBuilder — the whole
    /// retrieval path above the repositories is production code. Only the
    /// peripheral use cases (identity, memory, graph, active model) are doubled,
    /// since none of them is what this flow is about.
    RagPipeline buildPipeline({ManasContextLoader? loader}) {
      final getActiveUser = _MockGetActiveUser();
      final getOwnProfile = _MockGetOwnProfile();
      final getMemories = _MockGetMemories();
      final getNeighbours = _MockGetNeighbours();
      final getNodesByKeys = _MockGetNodesByKeys();
      final getActiveModel = _MockGetActiveModel();

      when(() => getActiveUser.call())
          .thenAnswer((_) async => const Left(Failure.errorFailure('none')));
      when(() => getOwnProfile.call(any()))
          .thenAnswer((_) async => const Right<Failure, ProfileEntity?>(null));
      when(() => getMemories.call(any()))
          .thenAnswer((_) async => const Right([]));
      when(() => getNeighbours.call(any()))
          .thenAnswer((_) async => const Right([]));
      when(() => getNodesByKeys.call(any()))
          .thenAnswer((_) async => const Right([]));
      when(() => getActiveModel.call())
          .thenAnswer((_) async => const Right<Failure, LlmModelInfo?>(null));

      return RagPipeline(
        embedding,
        searchService,
        const PromptBuilder(),
        getActiveUser,
        getOwnProfile,
        getMemories,
        getNeighbours,
        getNodesByKeys,
        getActiveModel,
        loader ?? _MockManasLoader(),
      );
    }

    setUp(() => pipeline = buildPipeline());

    test('a question reaches the prompt as a cited document passage', () async {
      await indexer.reconcile();
      final target = (await isar.documentChunkModels
              .where()
              .sha256EqualToAnyOrdinal(sha)
              .findAll())
          .firstWhere((c) =>
              c.text.toLowerCase().contains('cloud computing is a model'));

      // The stub embeds by text, so asking with the passage's own words is the
      // deterministic stand-in for a semantically close question.
      final msg = await pipeline.buildMessage(userQuestion: target.text);

      expect(msg.sourceChunkIds, contains(chunkIdOf(sha, target.ordinal)));
      expect(msg.sourceNoteIds, isEmpty);
      expect(msg.contextCount, greaterThan(0));
      expect(msg.userMessage, contains('## Relevant Documents'));
      expect(msg.userMessage, contains('(p.${target.label})'));
    });

    test('the ids it emits resolve into citations the sheet can render',
        () async {
      await indexer.reconcile();
      final target = (await isar.documentChunkModels
              .where()
              .sha256EqualToAnyOrdinal(sha)
              .findAll())
          .first;

      final msg = await pipeline.buildMessage(userQuestion: target.text);
      final citations =
          (await resolveCitations.call(msg.sourceChunkIds)).getOrElse(() => []);

      expect(citations, isNotEmpty);
      expect(citations.first.localPath, endsWith('nist_sp800-145.pdf'));
      expect(citations.first.label, isNotEmpty);
    });

    test('notes and documents both reach one answer', () async {
      await indexer.reconcile();
      final target = (await isar.documentChunkModels
              .where()
              .sha256EqualToAnyOrdinal(sha)
              .findAll())
          .first;
      noteVectors.results = const [
        ScoredNote(noteId: 'n1', score: 0.9, content: 'a note about clouds'),
      ];

      final msg = await pipeline.buildMessage(userQuestion: target.text);

      expect(msg.sourceNoteIds, ['n1']);
      expect(msg.sourceChunkIds, isNotEmpty);
      expect(msg.userMessage, contains('## Relevant Documents'));
      expect(msg.userMessage, contains('a note about clouds'));
    });

    test('a Manas-scoped question never reaches the document store', () async {
      await indexer.reconcile();
      final loader = _MockManasLoader();
      when(() => loader.merge(
            manasIds: any(named: 'manasIds'),
            budget: any(named: 'budget'),
            relevanceQuery: any(named: 'relevanceQuery'),
          )).thenAnswer((_) async => []);
      final scoped = buildPipeline(loader: loader);

      final msg =
          await scoped.buildMessage(userQuestion: 'anything', manasIds: ['m1']);

      expect(msg.sourceChunkIds, isEmpty,
          reason: 'documents have no Manas membership to scope by');
    });

    test('a document purged after indexing is no longer cited', () async {
      await indexer.reconcile();
      final target = (await isar.documentChunkModels
              .where()
              .sha256EqualToAnyOrdinal(sha)
              .findAll())
          .first;
      expect((await pipeline.buildMessage(userQuestion: target.text))
          .sourceChunkIds, isNotEmpty);

      await isar.writeTxn(() => isar.mediaCacheModels.deleteBySha256(sha));
      await indexer.reconcile();

      final after = await pipeline.buildMessage(userQuestion: target.text);
      expect(after.sourceChunkIds, isEmpty);
      expect(after.userMessage, isNot(contains('Relevant Documents')));
    });
  });

  test('re-running the whole flow changes nothing', () async {
    await indexer.reconcile();
    final firstChunks = await isar.documentChunkModels
        .where()
        .sha256EqualToAnyOrdinal(sha)
        .findAll();
    final probe = embedding.vectorFor(firstChunks.first.text);
    final firstHits = await vectors.search(probe, topK: 5);

    await indexer.reconcile();

    final again = await isar.documentChunkModels
        .where()
        .sha256EqualToAnyOrdinal(sha)
        .findAll();
    expect(again.length, firstChunks.length,
        reason: 're-indexing must replace, not duplicate');
    expect((await vectors.search(probe, topK: 5)).map((h) => h.chunkId),
        firstHits.map((h) => h.chunkId));
  });
}


/// Note vector store double — notes are not what this flow exercises, so it
/// returns whatever the test seeds and nothing more.
class _FakeNoteVectors implements VectorRepository {
  List<ScoredNote> results = const [];

  @override
  Future<List<ScoredNote>> search(List<double> queryVector,
          {int topK = 5, double minScore = 0.3}) async =>
      results;

  @override
  Future<void> upsert(String id, List<double> vector) async {}

  @override
  Future<void> delete(String id) async {}
}

class _MockGetActiveUser extends Mock implements GetActiveUserUseCase {}

class _MockGetOwnProfile extends Mock implements GetOwnProfileUseCase {}

class _MockGetMemories extends Mock implements GetMemoriesByNoteIdsUseCase {}

class _MockGetNeighbours extends Mock implements GetGraphNeighboursUseCase {}

class _MockGetNodesByKeys extends Mock implements GetGraphNodesByKeysUseCase {}

class _MockGetActiveModel extends Mock implements GetActiveLlmModelUseCase {}

class _MockManasLoader extends Mock implements ManasContextLoader {}

/// Deterministic stand-in for the on-device embedder.
///
/// Hashes the text into a stable unit vector, so semantically identical text
/// embeds identically and different text lands elsewhere — enough to prove the
/// wiring. Real semantic behaviour is the device test's job.
class _StubEmbedding implements EmbeddingService {
  List<double> vectorFor(String text) {
    final v = List<double>.filled(embeddingsDimensions, 0);
    v[text.hashCode.abs() % embeddingsDimensions] = 1.0;
    return v;
  }

  @override
  Future<List<double>> embed(String text, {bool isDocument = false}) async =>
      vectorFor(text);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
