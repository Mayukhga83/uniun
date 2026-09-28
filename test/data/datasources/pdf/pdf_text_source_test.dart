import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:uniun/data/datasources/pdf/pdf_text_source.dart';

import '../../../_helpers/fake_path_provider.dart';
import '../../../_helpers/pdf_fixtures.dart';
import '../../../_helpers/pdfium_test_lib.dart';

/// Covers: PdfrxTextSource over a real 7-page government PDF — page count, page
/// order, per-page text, idempotency — plus blank, non-PDF, truncated and
/// missing files.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Phrases each unique to one page of the fixture, per its PROVENANCE.md.
  const page1Phrase = 'Recommendations of the National Institute';
  const page3Phrase = 'Reports on Computer Systems Technology';
  const page4Phrase = 'Acknowledgements';
  const page5Phrase = 'Federal Information Security Management Act';
  const page6Phrase = 'Cloud computing is a model for enabling ubiquitous';

  const fixturePages = 7;

  late Directory tmp;
  final source = PdfrxTextSource();

  setUpAll(() async {
    tmp = await Directory.systemTemp.createTemp('pdf_text_source_test');
    // pdfrx resolves its cache dir through path_provider, whose platform
    // channel does not exist under `flutter test`.
    PathProviderPlatform.instance =
        FakePathProviderPlatform(docs: tmp.path, support: tmp.path);
    await ensurePdfium();
    await pdfrxFlutterInitialize();
  });

  tearDownAll(() => tmp.delete(recursive: true));

  Future<String> write(String name, List<int> bytes) async {
    final f = File('${tmp.path}/$name');
    await f.writeAsBytes(bytes);
    return f.path;
  }

  bool has(String page, String phrase) =>
      normalizePdfText(page).contains(normalizePdfText(phrase));

  group('a real government PDF', () {
    late List<String> pages;

    setUpAll(() async {
      final read = await source.pagesText(pdfFixture('nist_sp800-145.pdf'));
      expect(read, isNotNull, reason: 'the committed fixture must be readable');
      pages = read!;
    });

    test('yields one string per page', () {
      expect(pages, hasLength(fixturePages));
    });

    test('extracts real prose from the cover page', () {
      expect(has(pages[0], page1Phrase), isTrue);
    });

    test('keeps pages in order and separate — a phrase unique to one page '
        'appears only there', () {
      expect(has(pages[2], page3Phrase), isTrue);
      expect(has(pages[3], page4Phrase), isTrue);
      expect(has(pages[4], page5Phrase), isTrue);
      expect(has(pages[5], page6Phrase), isTrue);

      // The failure this guards: concatenating every page into pages[0].
      for (final phrase in [page3Phrase, page4Phrase, page5Phrase, page6Phrase]) {
        expect(has(pages[0], phrase), isFalse, reason: phrase);
      }
    });

    test('no page comes back empty', () {
      for (var i = 0; i < pages.length; i++) {
        expect(normalizePdfText(pages[i]), isNotEmpty, reason: 'page ${i + 1}');
      }
    });

    test('the extracted text clears the quality gate thresholds', () {
      final joined = pages.join('\n').trim();
      final letters = RegExp(r'\p{L}', unicode: true).allMatches(joined).length;

      expect(joined.length, greaterThanOrEqualTo(200));
      expect(letters / joined.length, greaterThanOrEqualTo(0.15));
    });

    test('reading the same file twice yields the same text', () async {
      final again = await source.pagesText(pdfFixture('nist_sp800-145.pdf'));

      expect(again, pages);
    });
  });

  group('generated PDFs', () {
    test('a page with no text operators yields a blank string, not an error',
        () async {
      final path = await write('blank.pdf', minimalPdf(['']));

      final pages = await source.pagesText(path);

      expect(pages, hasLength(1));
      expect(pages!.single.trim(), isEmpty);
    });

    test('text lands on the page it was written to', () async {
      final path = await write(
        'two.pdf',
        minimalPdf(['Alpha page one', 'Beta page two']),
      );

      final pages = await source.pagesText(path);

      expect(has(pages![0], 'Alpha page one'), isTrue);
      expect(has(pages[1], 'Beta page two'), isTrue);
      expect(has(pages[0], 'Beta page two'), isFalse);
    });
  });

  // ── Edge cases ──────────────────────────────────────────────────────────

  group('unreadable input returns null rather than throwing', () {
    test('a file that is not a PDF', () async {
      final path = await write('fake.pdf', 'not a pdf at all'.codeUnits);

      expect(await source.pagesText(path), isNull);
    });

    test('a missing file', () async {
      expect(await source.pagesText('${tmp.path}/absent.pdf'), isNull);
    });

    test('an empty file', () async {
      final path = await write('empty.pdf', const <int>[]);

      expect(await source.pagesText(path), isNull);
    });

    test('a truncated real PDF', () async {
      final whole = await File(pdfFixture('nist_sp800-145.pdf')).readAsBytes();
      final path = await write('truncated.pdf', whole.sublist(0, 2000));

      expect(await source.pagesText(path), isNull);
    });

    test('a directory path', () async {
      expect(await source.pagesText(tmp.path), isNull);
    });
  });
}
