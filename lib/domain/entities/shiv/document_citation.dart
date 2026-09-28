import 'package:uniun/core/enum/document_kind.dart';

/// A resolved document source for the Sources sheet: which document, where in
/// it, the passage, and where the file is on this device.
class DocumentCitation {
  const DocumentCitation({
    required this.chunkId,
    required this.sha256,
    required this.kind,
    required this.label,
    required this.snippet,
    required this.localPath,
    this.title,
  });

  final String chunkId;
  final String sha256;

  final DocumentKind kind;

  /// The page of a PDF, the heading above the passage in a DOCX, or `''`.
  final String label;

  /// The passage the answer drew on.
  final String snippet;

  /// Absolute path of the cached file, handed to the OS viewer.
  final String localPath;

  /// The attaching note's filename, or null once that note has aged out of
  /// retention — the citation is still valid, it just has no nice name.
  final String? title;
}
