import 'package:injectable/injectable.dart';
import 'package:uniun/data/datasources/pdf/pdf_text_source.dart';
import 'package:uniun/features/shiv/rag/extraction/chunk.dart';
import 'package:uniun/features/shiv/rag/extraction/text_quality_gate.dart';

/// Why a document cannot be searched.
enum NotSearchableReason {
  /// PDFium could not open it at all — corrupt, truncated, encrypted, or not a
  /// PDF.
  unreadable,

  /// Opened fine, but holds no usable text: a scan, or a broken font encoding
  /// that extracts as mojibake.
  noTextLayer,
}

sealed class ExtractionResult {
  const ExtractionResult();
}

/// Text was extracted, passed the quality gate, and chunked.
final class Extracted extends ExtractionResult {
  const Extracted({required this.chunks, required this.pageCount});

  final List<Chunk> chunks;
  final int pageCount;
}

/// The document is kept but cannot be searched. An expected outcome for a scan —
/// not a failure, and never surfaced to the user as an error.
final class NotSearchable extends ExtractionResult {
  const NotSearchable(this.reason, {this.pageCount = 0});

  final NotSearchableReason reason;
  final int pageCount;
}

/// PDF file → page-labelled chunks, or the reason it cannot be searched.
///
/// Never throws: every failure is a [NotSearchable]. Indexing runs off the chat
/// path, and a document that cannot be read must not be able to break it.
@lazySingleton
class PdfExtractionService {
  PdfExtractionService(this._source);

  final PdfTextSource _source;

  Future<ExtractionResult> extract(String path) async {
    final List<String>? pages;
    try {
      pages = await _source.pagesText(path);
    } catch (_) {
      return const NotSearchable(NotSearchableReason.unreadable);
    }
    if (pages == null) {
      return const NotSearchable(NotSearchableReason.unreadable);
    }

    if (!looksLikeProse(pages.join('\n'))) {
      return NotSearchable(
        NotSearchableReason.noTextLayer,
        pageCount: pages.length,
      );
    }
    final chunks = chunkPages(pages);
    if (chunks.isEmpty) {
      return NotSearchable(
        NotSearchableReason.noTextLayer,
        pageCount: pages.length,
      );
    }
    return Extracted(chunks: chunks, pageCount: pages.length);
  }
}
