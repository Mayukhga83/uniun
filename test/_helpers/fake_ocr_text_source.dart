import 'package:uniun/data/datasources/ocr/ocr_text_source.dart';

/// Deterministic [OcrTextSource]: returns preset text per path, counts reads.
class FakeOcrTextSource implements OcrTextSource {
  /// path -> text. A missing key or a `null` value simulates an unreadable
  /// image; `''` is an image with no text in it.
  final Map<String, String?> texts = {};
  int calls = 0;

  /// When set, [imageText] throws it instead of answering.
  Object? throwOnRead;

  @override
  Future<String?> imageText(String path) async {
    calls++;
    if (throwOnRead != null) throw throwOnRead!;
    return texts[path];
  }
}
