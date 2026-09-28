import 'package:injectable/injectable.dart';
import 'package:uniun/core/enum/document_kind.dart';
import 'package:uniun/data/datasources/docx/docx_text_source.dart';
import 'package:uniun/data/datasources/pdf/pdf_text_source.dart';
import 'package:uniun/features/shiv/rag/extraction/chunk.dart';
import 'package:uniun/features/shiv/rag/extraction/text_quality_gate.dart';

/// Why a document cannot be searched.
enum NotSearchableReason {
  /// The reader could not open it at all — corrupt, truncated, encrypted, or
  /// not the format its mime claimed.
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

/// Document file → labelled chunks, or the reason it cannot be searched.
///
/// Never throws: every failure is a [NotSearchable]. Indexing runs off the chat
/// path, and a document that cannot be read must not be able to break it.
@lazySingleton
class DocumentExtractionService {
  DocumentExtractionService(this._pdf, this._docx);

  final PdfTextSource _pdf;
  final DocxTextSource _docx;

  Future<ExtractionResult> extract(String path, DocumentKind kind) async {
    final String text;
    final List<Chunk> chunks;
    // Only a PDF has pages; a DOCX paginates differently in every viewer, so
    // it reports none and is labelled by heading instead.
    final int pageCount;
    try {
      switch (kind) {
        case DocumentKind.pdf:
          final pages = await _pdf.pagesText(path);
          if (pages == null) return _unreadable;
          text = pages.join('\n');
          chunks = chunkPages(pages);
          pageCount = pages.length;
        case DocumentKind.docx:
          final sections = await _docx.sectionsText(path);
          if (sections == null) return _unreadable;
          text = sections.map((s) => s.text).join('\n');
          chunks = chunkSections(sections);
          pageCount = 0;
      }
    } catch (_) {
      return _unreadable;
    }

    // The prose gate catches scans and broken font encodings, which only a PDF
    // can have. DOCX text is the author's own characters, so a short memo or a
    // table of figures is genuine and only an empty document is refused.
    final garbled = kind == DocumentKind.pdf && !looksLikeProse(text);
    if (garbled || chunks.isEmpty) {
      return NotSearchable(NotSearchableReason.noTextLayer, pageCount: pageCount);
    }
    return Extracted(chunks: chunks, pageCount: pageCount);
  }

  static const _unreadable = NotSearchable(NotSearchableReason.unreadable);
}
