import 'package:uniun/data/datasources/pdf/pdf_text_source.dart';

/// Deterministic [PdfTextSource]: returns preset pages per path, counts reads.
class FakePdfTextSource implements PdfTextSource {
  /// path -> pages. A missing key or a `null` value simulates an unreadable file.
  final Map<String, List<String>?> pages = {};
  int calls = 0;

  /// When set, [pagesText] throws it instead of answering.
  Object? throwOnRead;

  /// When set, [pagesText] awaits it before answering (for concurrency tests).
  Future<void>? gate;

  @override
  Future<List<String>?> pagesText(String path) async {
    calls++;
    if (gate != null) await gate;
    if (throwOnRead != null) throw throwOnRead!;
    return pages[path];
  }
}
