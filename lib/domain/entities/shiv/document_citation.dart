/// A resolved PDF source for the Sources sheet: which document, which page, the
/// passage, and where the file is on this device.
class DocumentCitation {
  const DocumentCitation({
    required this.chunkId,
    required this.sha256,
    required this.label,
    required this.snippet,
    required this.localPath,
    this.title,
  });

  final String chunkId;
  final String sha256;

  /// 1-based page number.
  final String label;

  /// The passage the answer drew on.
  final String snippet;

  /// Absolute path of the cached PDF, handed to the OS viewer.
  final String localPath;

  /// The attaching note's filename, or null once that note has aged out of
  /// retention — the citation is still valid, it just has no nice name.
  final String? title;
}
