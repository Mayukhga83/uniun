import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:pdfrx/pdfrx.dart';

final math.Random _rng = math.Random();

Future<void>? _pdfiumReady;

/// PDFium build `pdfium_dart` bundles. Keep in step with `_pdfiumRelease` in
/// that package's `hook/build.dart` — a mismatch only means the tests exercise
/// a different PDFium build than the app ships, not a failure.
const String _pdfiumRelease = 'chromium/7811';

/// Downloads the PDFium native library once and points pdfrx at it.
///
/// `flutter test` does not run Dart native-asset build hooks, so
/// `pdfium_dart`'s bundled `libpdfium` is absent and any `PdfDocument.open*`
/// fails with "Asset not found in native assets file". `pdfium_dart` documents
/// `modulePath` as the supported escape hatch "for custom deployments or
/// tests", and `Pdfrx.pdfiumModulePath` feeds it.
///
/// Mirrors [ensureIsarCore] deliberately: same problem (a native binary a test
/// needs but the runner does not provide), same shape of answer — one download
/// to a stable shared path, a real `HttpClient` (flutter_test's global mock
/// answers 400 to everything), and an atomic rename so parallel isolates and
/// shards are safe at any `--concurrency`.
Future<void> ensurePdfium() => _pdfiumReady ??= () async {
      if (Platform.isWindows || Platform.isMacOS) {
        // Only the linux-x64 artefact is wired up here; CI and the dev box are
        // both Linux. Fail loudly rather than skip — a silently unrun PDF test
        // is the thing this whole tier exists to avoid.
        throw UnsupportedError(
          'ensurePdfium() currently downloads the linux-x64 PDFium build only; '
          'add this platform to test/_helpers/pdfium_test_lib.dart to run here.',
        );
      }

      final dirName = _pdfiumRelease.replaceAll('/', '_');
      final lib = File('${Directory.systemTemp.path}${Platform.pathSeparator}'
          'pdfium_$dirName${Platform.pathSeparator}libpdfium.so');

      if (!lib.existsSync()) {
        await lib.parent.create(recursive: true);
        final url = Uri.parse(
          'https://github.com/bblanchon/pdfium-binaries/releases/download/'
          '${Uri.encodeComponent(_pdfiumRelease)}/pdfium-linux-x64.tgz',
        );

        late final List<int> archiveBytes;
        await HttpOverrides.runWithHttpOverrides(() async {
          final client = HttpClient();
          try {
            final res = await (await client.getUrl(url)).close();
            if (res.statusCode != 200) {
              throw StateError('PDFium download failed: HTTP ${res.statusCode}');
            }
            archiveBytes = await res
                .fold<BytesBuilder>(BytesBuilder(), (b, d) => b..add(d))
                .then((b) => b.takeBytes());
          } finally {
            client.close();
          }
        }, _RealHttpOverrides());

        final entry = TarDecoder()
            .decodeBytes(const GZipDecoder().decodeBytes(archiveBytes))
            .findFile('lib/libpdfium.so');
        if (entry == null) {
          throw StateError('PDFium archive $url has no lib/libpdfium.so');
        }

        final tmp = File(
            '${lib.path}.${_rng.nextInt(1 << 32).toRadixString(16)}.part');
        await tmp.writeAsBytes(entry.content as List<int>);
        try {
          tmp.renameSync(lib.path);
        } on FileSystemException {
          // Lost the rename race to a parallel isolate — its copy is identical.
          if (tmp.existsSync()) tmp.deleteSync();
        }
      }

      Pdfrx.pdfiumModulePath ??= lib.path;
    }();

/// Default [HttpOverrides] — base-class methods create REAL clients,
/// sidestepping flutter_test's global 400-mock inside the zone.
class _RealHttpOverrides extends HttpOverrides {}
