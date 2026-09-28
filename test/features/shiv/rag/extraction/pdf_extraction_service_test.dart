import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/features/shiv/rag/extraction/pdf_extraction_service.dart';

import '../../../../_helpers/fake_pdf_text_source.dart';

/// Covers: PdfExtractionService composing source, gate and chunker; both
/// not-searchable reasons; page counts; no exception leak.
void main() {
  const prose = 'The quarterly leave policy has been revised. ';
  late FakePdfTextSource source;
  late PdfExtractionService service;

  setUp(() {
    source = FakePdfTextSource();
    service = PdfExtractionService(source);
  });

  group('readable prose', () {
    test('becomes labelled chunks with the page count', () async {
      source.pages['/a.pdf'] = [prose * 6, 'Second page. ${prose * 6}'];

      final result = await service.extract('/a.pdf');

      expect(result, isA<Extracted>());
      final extracted = result as Extracted;
      expect(extracted.pageCount, 2);
      expect(extracted.chunks.map((c) => c.label).toSet(), {'1', '2'});
      expect(extracted.chunks.map((c) => c.ordinal),
          List.generate(extracted.chunks.length, (i) => i));
    });

    test('reads the file exactly once', () async {
      source.pages['/a.pdf'] = [prose * 6];

      await service.extract('/a.pdf');

      expect(source.calls, 1);
    });
  });

  group('not searchable', () {
    test('mojibake fails the gate as noTextLayer, keeping the page count',
        () async {
      source.pages['/a.pdf'] = ['!" #\$%\$ &\'()' * 40, '!" #\$%\$ &\'()' * 40];

      final result = await service.extract('/a.pdf');

      final n = result as NotSearchable;
      expect(n.reason, NotSearchableReason.noTextLayer);
      expect(n.pageCount, 2);
    });

    test('a scan (blank pages) is noTextLayer', () async {
      source.pages['/a.pdf'] = ['', '  ', ''];

      final result = await service.extract('/a.pdf');

      expect((result as NotSearchable).reason, NotSearchableReason.noTextLayer);
    });

    test('text too short to be worth indexing is noTextLayer', () async {
      source.pages['/a.pdf'] = ['Received.'];

      expect(((await service.extract('/a.pdf')) as NotSearchable).reason,
          NotSearchableReason.noTextLayer);
    });

    test('a file the source cannot open is unreadable', () async {
      final result = await service.extract('/missing.pdf');

      expect((result as NotSearchable).reason, NotSearchableReason.unreadable);
    });

    test('a source that throws is unreadable, never an exception', () async {
      source.throwOnRead = StateError('pdfium exploded');

      final result = await service.extract('/a.pdf');

      expect((result as NotSearchable).reason, NotSearchableReason.unreadable);
    });
  });

  // ── Edge cases ──────────────────────────────────────────────────────────

  group('degenerate input', () {
    test('an empty page list is noTextLayer', () async {
      source.pages['/a.pdf'] = const [];

      expect(((await service.extract('/a.pdf')) as NotSearchable).reason,
          NotSearchableReason.noTextLayer);
    });

    test('one long page still yields several capped chunks', () async {
      source.pages['/a.pdf'] = [prose * 200];

      final extracted = await service.extract('/a.pdf') as Extracted;

      expect(extracted.pageCount, 1);
      expect(extracted.chunks.length, greaterThan(1));
      expect(extracted.chunks.every((c) => c.text.length <= 700), isTrue);
      expect(extracted.chunks.map((c) => c.label).toSet(), {'1'});
    });

    test('Devanagari prose passes the gate and chunks', () async {
      source.pages['/a.pdf'] = ['भारत सरकार के कर्मचारियों के लिए नीति। ' * 10];

      expect(await service.extract('/a.pdf'), isA<Extracted>());
    });
  });
}
