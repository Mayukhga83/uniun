import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/core/enum/document_kind.dart';
import 'package:uniun/features/shiv/rag/extraction/document_extraction_service.dart';

import '../../../../_helpers/fake_docx_text_source.dart';
import '../../../../_helpers/fake_pdf_text_source.dart';

/// Covers: DocumentExtractionService dispatching by kind and composing source,
/// gate and chunker; both not-searchable reasons; page counts; no exception
/// leak.
void main() {
  const prose = 'The quarterly leave policy has been revised. ';
  late FakePdfTextSource source;
  late FakeDocxTextSource docx;
  late DocumentExtractionService service;

  setUp(() {
    source = FakePdfTextSource();
    docx = FakeDocxTextSource();
    service = DocumentExtractionService(source, docx);
  });

  group('readable prose', () {
    test('becomes labelled chunks with the page count', () async {
      source.pages['/a.pdf'] = [prose * 6, 'Second page. ${prose * 6}'];

      final result = await service.extract('/a.pdf', DocumentKind.pdf);

      expect(result, isA<Extracted>());
      final extracted = result as Extracted;
      expect(extracted.pageCount, 2);
      expect(extracted.chunks.map((c) => c.label).toSet(), {'1', '2'});
      expect(extracted.chunks.map((c) => c.ordinal),
          List.generate(extracted.chunks.length, (i) => i));
    });

    test('reads the file exactly once', () async {
      source.pages['/a.pdf'] = [prose * 6];

      await service.extract('/a.pdf', DocumentKind.pdf);

      expect(source.calls, 1);
    });
  });

  group('not searchable', () {
    test('mojibake fails the gate as noTextLayer, keeping the page count',
        () async {
      source.pages['/a.pdf'] = ['!" #\$%\$ &\'()' * 40, '!" #\$%\$ &\'()' * 40];

      final result = await service.extract('/a.pdf', DocumentKind.pdf);

      final n = result as NotSearchable;
      expect(n.reason, NotSearchableReason.noTextLayer);
      expect(n.pageCount, 2);
    });

    test('a scan (blank pages) is noTextLayer', () async {
      source.pages['/a.pdf'] = ['', '  ', ''];

      final result = await service.extract('/a.pdf', DocumentKind.pdf);

      expect((result as NotSearchable).reason, NotSearchableReason.noTextLayer);
    });

    test('text too short to be worth indexing is noTextLayer', () async {
      source.pages['/a.pdf'] = ['Received.'];

      expect(((await service.extract('/a.pdf', DocumentKind.pdf)) as NotSearchable).reason,
          NotSearchableReason.noTextLayer);
    });

    test('a file the source cannot open is unreadable', () async {
      final result = await service.extract('/missing.pdf', DocumentKind.pdf);

      expect((result as NotSearchable).reason, NotSearchableReason.unreadable);
    });

    test('a source that throws is unreadable, never an exception', () async {
      source.throwOnRead = StateError('pdfium exploded');

      final result = await service.extract('/a.pdf', DocumentKind.pdf);

      expect((result as NotSearchable).reason, NotSearchableReason.unreadable);
    });
  });

  group('docx', () {
    test('sections become heading-labelled chunks with no page count',
        () async {
      docx.sections['/a.docx'] = [
        (label: '', text: prose * 3),
        (label: 'Annual Leave', text: 'Annual Leave\n\n${prose * 3}'),
      ];

      final extracted =
          await service.extract('/a.docx', DocumentKind.docx) as Extracted;

      expect(extracted.pageCount, 0);
      expect(extracted.chunks.map((c) => c.label).toList(),
          ['', 'Annual Leave']);
    });

    test('each kind reads only its own source', () async {
      source.pages['/a.pdf'] = [prose * 6];
      docx.sections['/a.docx'] = [(label: 'A', text: prose * 6)];

      await service.extract('/a.pdf', DocumentKind.pdf);
      await service.extract('/a.docx', DocumentKind.docx);

      expect(source.calls, 1);
      expect(docx.calls, 1);
    });

    test('a file the source cannot read is unreadable', () async {
      final result = await service.extract('/missing.docx', DocumentKind.docx);

      expect((result as NotSearchable).reason, NotSearchableReason.unreadable);
    });

    test('a source that throws is unreadable, never an exception', () async {
      docx.throwOnRead = StateError('zip exploded');

      final result = await service.extract('/a.docx', DocumentKind.docx);

      expect((result as NotSearchable).reason, NotSearchableReason.unreadable);
    });

    test('a short memo is indexed — the prose gate is for PDFs only',
        () async {
      docx.sections['/a.docx'] = [(label: 'Memo', text: 'Memo\n\nApproved.')];

      final e = await service.extract('/a.docx', DocumentKind.docx) as Extracted;

      expect(e.chunks.single.label, 'Memo');
    });

    test('a table of figures is indexed despite few letters', () async {
      docx.sections['/a.docx'] = [
        (label: 'Rates', text: '2024 | 4500 | 3000\n2025 | 4800 | 3200'),
      ];

      expect(await service.extract('/a.docx', DocumentKind.docx),
          isA<Extracted>());
    });

    test('the same short text in a PDF is still refused', () async {
      source.pages['/a.pdf'] = ['Memo. Approved.'];

      expect(
        ((await service.extract('/a.pdf', DocumentKind.pdf)) as NotSearchable)
            .reason,
        NotSearchableReason.noTextLayer,
      );
    });

    test('a DOCX whose sections are all blank is noTextLayer', () async {
      docx.sections['/a.docx'] = [(label: 'X', text: '  \n\n ')];

      final n =
          await service.extract('/a.docx', DocumentKind.docx) as NotSearchable;

      expect(n.reason, NotSearchableReason.noTextLayer);
      expect(n.pageCount, 0);
    });

    test('a document with no sections is noTextLayer', () async {
      docx.sections['/a.docx'] = const [];

      expect(
        ((await service.extract('/a.docx', DocumentKind.docx)) as NotSearchable)
            .reason,
        NotSearchableReason.noTextLayer,
      );
    });
  });

  // ── Edge cases ──────────────────────────────────────────────────────────

  group('degenerate input', () {
    test('an empty page list is noTextLayer', () async {
      source.pages['/a.pdf'] = const [];

      expect(((await service.extract('/a.pdf', DocumentKind.pdf)) as NotSearchable).reason,
          NotSearchableReason.noTextLayer);
    });

    test('one long page still yields several capped chunks', () async {
      source.pages['/a.pdf'] = [prose * 200];

      final extracted = await service.extract('/a.pdf', DocumentKind.pdf) as Extracted;

      expect(extracted.pageCount, 1);
      expect(extracted.chunks.length, greaterThan(1));
      expect(extracted.chunks.every((c) => c.text.length <= 700), isTrue);
      expect(extracted.chunks.map((c) => c.label).toSet(), {'1'});
    });

    test('Devanagari prose passes the gate and chunks', () async {
      source.pages['/a.pdf'] = ['भारत सरकार के कर्मचारियों के लिए नीति। ' * 10];

      expect(await service.extract('/a.pdf', DocumentKind.pdf), isA<Extracted>());
    });
  });
}
