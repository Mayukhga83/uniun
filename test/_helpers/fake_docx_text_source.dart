import 'package:uniun/data/datasources/docx/docx_text_source.dart';

/// Deterministic [DocxTextSource]: returns preset sections per path, counts
/// reads.
class FakeDocxTextSource implements DocxTextSource {
  /// path -> sections. A missing key or a `null` value simulates an unreadable
  /// file.
  final Map<String, List<DocxSection>?> sections = {};
  int calls = 0;

  /// When set, [sectionsText] throws it instead of answering.
  Object? throwOnRead;

  @override
  Future<List<DocxSection>?> sectionsText(String path) async {
    calls++;
    if (throwOnRead != null) throw throwOnRead!;
    return sections[path];
  }
}
