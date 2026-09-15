/// Application-wide constants.
///
/// Use these instead of hardcoding the same literal in multiple places.
class AppConstants {
  AppConstants._();

  /// The application name — also used as a fallback seed for generated avatars.
  static const String kAppName = 'uniun';

  /// Human-readable brand name shown in UI.
  static const String kBrandName = 'UNIUN';

  /// App version string shown in settings / privacy policy.
  static const String kAppVersion = 'UNIUN v1.0.0-beta';

  /// Privacy contact email.
  static const String kPrivacyEmail = 'info@uniun.in';

  /// The UNIUN backend relay — the default system relay every device connects
  /// to and the one auto-selected when publishing. Use this constant instead
  /// of hardcoding the URL anywhere.
  static const String kUniunBackend = 'wss://dev.uniun.in:8080';

  /// HTTP base for our backend's Blossom (NIP-B7) endpoints. Same host as
  /// [kUniunBackend], HTTPS instead of WSS. The Go relay wires
  /// `blossom.New(relay, RelayURL)` against this URL — `PUT /upload`,
  /// `GET /<sha256>`, `HEAD /<sha256>`, etc. live here.
  static const String kUniunBlossom = 'https://dev.uniun.in:8080';

  /// How Shiv is named to the model: the role label in conversation context
  /// and the answer cue every chat prompt ends with. Shared so the prompt and
  /// [LlmTextSanitizer] (which strips the label back off if a model echoes it)
  /// cannot drift apart.
  static const String kShivLabel = 'Shiv';

  /// Image compression target (Android / iOS / macOS / web). Photos over
  /// this are shrunk via `ImageCompressor` before upload. Not a hard reject.
  static const int kMaxUploadBytes = 3 * 1024 * 1024;

  /// Image cap on Windows. `flutter_image_compress` has no Windows backend,
  /// so the picker passes bytes through up to this ceiling.
  static const int kMaxUploadBytesWindows = 10 * 1024 * 1024;

  /// Hard cap for non-image binaries (video, PDF, docs, archives). Leaves
  /// headroom under the relay's 100 MB nginx limit for HTTP overhead + the
  /// Kind 24242 auth envelope.
  static const int kMaxBinaryUploadBytes = 50 * 1024 * 1024;
}
