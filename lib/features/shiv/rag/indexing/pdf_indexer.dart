import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/data/models/documents/document_chunk_model.dart';
import 'package:uniun/data/models/documents/document_index_model.dart';
import 'package:uniun/data/models/media/media_cache_model.dart';
import 'package:uniun/domain/entities/shiv/scored_chunk.dart';
import 'package:uniun/domain/usecases/vector_usecases.dart';
import 'package:uniun/features/shiv/rag/extraction/pdf_extraction_service.dart';

/// Keeps the PDF index in step with the media cache.
///
/// Reconciles two sets by SHA-256 rather than reacting to a "blob arrived"
/// event:
///   * a PDF cache row with no index row → index it;
///   * an index row with no cache row → purge its chunks and index row.
///
/// Reconciling state covers every way a blob reaches `MediaCacheModel` (upload,
/// download cache-hit, fresh download, staged draft — four call sites, all
/// inside a write transaction where embedding work cannot be awaited), retries
/// a crash mid-index because the index row is written last, and cleans up after
/// both deletion paths (`MediaRepository.removeLocal` and `CleanupManager`,
/// which deletes cache rows directly from the Gateway isolate).
///
/// Main isolate only: embedding runs through flutter_gemma, which is not
/// available in the Gateway isolate.
@lazySingleton
class PdfIndexer {
  PdfIndexer(this._isar, this._extraction, this._embedAndStore);

  final Isar _isar;
  final PdfExtractionService _extraction;

  /// Embedding and vector storage both live behind this use case, which also
  /// bounds concurrency — the indexer never touches `EmbeddingService` or the
  /// vector repository itself.
  final EmbedAndStoreChunkUseCase _embedAndStore;

  StreamSubscription<void>? _sub;
  bool _running = false;
  bool _dirty = false;

  /// Begin watching the media cache. Reconciles once immediately.
  void start() {
    if (_sub != null) return;
    _sub = _isar.mediaCacheModels
        .watchLazy(fireImmediately: true)
        .listen((_) => unawaited(reconcile()));
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }

  /// One full pass. Overlapping calls coalesce: a call made while a pass is
  /// running marks it dirty, and the running pass repeats before returning.
  Future<void> reconcile() async {
    if (_running) {
      _dirty = true;
      return;
    }
    _running = true;
    try {
      do {
        _dirty = false;
        await _purgeOrphans();
        await _indexPending();
      } while (_dirty);
    } catch (e) {
      // Indexing runs off the chat path; a failure here must never surface
      // there. The next reconcile retries whatever did not finish.
      debugPrint('📄 PdfIndexer: reconcile failed — $e');
    } finally {
      _running = false;
    }
  }

  Future<void> _purgeOrphans() async {
    final indexed = await _isar.documentIndexModels.where().findAll();
    for (final row in indexed) {
      final cached = await _isar.mediaCacheModels
          .filter()
          .sha256EqualTo(row.sha256)
          .findFirst();
      if (cached == null) await _purge(row.sha256);
    }
  }

  Future<void> _indexPending() async {
    final pdfs = await _isar.mediaCacheModels
        .filter()
        .mimeStartsWith('application/pdf', caseSensitive: false)
        .findAll();
    for (final row in pdfs) {
      final done = await _isar.documentIndexModels
          .filter()
          .sha256EqualTo(row.sha256)
          .findFirst();
      if (done == null) await _index(row.sha256, row.localPath);
    }
  }

  Future<void> _index(String sha, String path) async {
    final result = await _extraction.extract(path);
    switch (result) {
      case NotSearchable(:final pageCount):
        await _writeIndexRow(
            sha, DocumentIndexStatus.notSearchable, pageCount, 0);
      case Extracted(:final chunks, :final pageCount):
        // Clear whatever an interrupted earlier attempt left behind, so a retry
        // cannot leave a half-indexed document with stale chunks.
        await _purgeChunks(sha);
        for (final c in chunks) {
          final stored =
              await _embedAndStore.call((chunkIdOf(sha, c.ordinal), c.text));
          if (!stored) {
            // The embedder is not ready. That is NOT "not searchable" — leave
            // no index row so a later reconcile retries the whole document.
            debugPrint('📄 PdfIndexer: embedder not ready, will retry $sha');
            return;
          }
          await _isar.writeTxn(
            () => _isar.documentChunkModels.put(DocumentChunkModel()
              ..sha256 = sha
              ..ordinal = c.ordinal
              ..label = c.label
              ..text = c.text),
          );
        }
        // Written last: chunks and vectors first, so a crash part-way leaves a
        // retriable state rather than a document recorded as done but empty.
        await _writeIndexRow(
            sha, DocumentIndexStatus.indexed, pageCount, chunks.length);
    }
  }

  Future<void> _writeIndexRow(
    String sha,
    DocumentIndexStatus status,
    int pageCount,
    int chunkCount,
  ) =>
      _isar.writeTxn(
        () => _isar.documentIndexModels.put(DocumentIndexModel()
          ..sha256 = sha
          ..status = status
          ..pageCount = pageCount
          ..chunkCount = chunkCount
          ..indexedAt = DateTime.now()),
      );

  Future<void> _purge(String sha) async {
    await _purgeChunks(sha);
    await _isar.writeTxn(() => _isar.documentIndexModels.deleteBySha256(sha));
  }

  /// Drops a document's chunk rows. The vectors stay — ToStore cannot delete
  /// without destroying the whole index (see [DocumentVectorRepository]) — and
  /// are filtered out at search time because they no longer resolve to a row.
  Future<void> _purgeChunks(String sha) => _isar.writeTxn(
        () => _isar.documentChunkModels
            .where()
            .sha256EqualToAnyOrdinal(sha)
            .deleteAll(),
      );
}
