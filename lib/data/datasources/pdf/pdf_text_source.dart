import 'package:injectable/injectable.dart';
import 'package:pdfrx/pdfrx.dart';

/// Reads the text layer of a PDF file, one string per page.
///
/// The only place `package:pdfrx` is touched, so the package stays replaceable
/// and every other extraction unit is testable without native PDFium.
///
/// Lives in `datasources/` for the same reason `AIModelRunner` does: it is an
/// adapter over an external package, not feature logic.
abstract class PdfTextSource {
  /// Page texts in page order, or `null` when [path] cannot be opened as a PDF.
  ///
  /// A page with no text layer yields an empty string rather than `null` — a
  /// scanned page is a readable PDF that happens to hold no text, which the
  /// quality gate decides about later. `null` is reserved for "this is not a
  /// PDF we can open at all".
  Future<List<String>?> pagesText(String path);
}

@LazySingleton(as: PdfTextSource)
class PdfrxTextSource implements PdfTextSource {
  @override
  Future<List<String>?> pagesText(String path) async {
    PdfDocument? doc;
    try {
      doc = await PdfDocument.openFile(path);
      final pages = <String>[];
      for (final page in doc.pages) {
        final raw = await page.loadText();
        pages.add(raw?.fullText ?? '');
      }
      return pages;
    } catch (_) {
      // A corrupt, truncated, password-protected or non-PDF file is an expected
      // outcome for user-supplied content, not an error worth propagating.
      return null;
    } finally {
      await doc?.dispose();
    }
  }
}
