import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/features/shiv/rag/extraction/chunk.dart';

/// Covers: chunkPages page labels and ordinals, paragraph packing, the 700-char
/// cap, sentence and hard-cut splitting, unicode safety, scale.
void main() {
  group('labels and ordinals', () {
    test('every chunk carries its source page number as label', () {
      final chunks = chunkPages(['first page text', 'second page text']);

      expect(chunks.map((c) => c.label), ['1', '2']);
    });

    test('ordinals run 0..n-1 across pages', () {
      final chunks = chunkPages(['a', 'b', 'c']);

      expect(chunks.map((c) => c.ordinal), [0, 1, 2]);
    });

    test('a whitespace-only page is skipped without renumbering later pages',
        () {
      final chunks = chunkPages(['A', '   \n\t ', 'C']);

      expect(chunks.map((c) => c.label), ['1', '3']);
      expect(chunks.map((c) => c.ordinal), [0, 1]);
    });

    test('no pages, or only blank pages, yield no chunks', () {
      expect(chunkPages(const []), isEmpty);
      expect(chunkPages(['', ' ', '\n\n']), isEmpty);
    });
  });

  group('sections', () {
    test('each chunk carries its section label, including an empty one', () {
      final chunks = chunkSections([
        (label: '', text: 'Preamble.'),
        (label: 'Annual Leave', text: 'Annual Leave\n\n24 days.'),
      ]);

      expect([for (final c in chunks) c.label], ['', 'Annual Leave']);
    });

    test('ordinals run 0..n-1 across sections', () {
      final chunks = chunkSections([
        (label: 'A', text: 'x' * 800),
        (label: 'B', text: 'y'),
      ]);

      expect([for (final c in chunks) c.ordinal], [0, 1, 2]);
      expect([for (final c in chunks) c.label], ['A', 'A', 'B']);
    });

    test('paragraphs never pack across a section boundary', () {
      final chunks = chunkSections([
        (label: 'A', text: 'short a'),
        (label: 'B', text: 'short b'),
      ]);

      expect([for (final c in chunks) c.text], ['short a', 'short b']);
    });

    test('a whitespace-only section yields nothing and shifts no labels', () {
      final chunks = chunkSections([
        (label: 'A', text: ' \n\n '),
        (label: 'B', text: 'body'),
      ]);

      expect(chunks.single.label, 'B');
      expect(chunks.single.ordinal, 0);
    });

    test('chunkPages labels exactly as page-numbered sections would', () {
      final pages = ['one\n\ntwo', '', 'x' * 900];

      expect(
        chunkPages(pages).map((c) => c.toString()),
        chunkSections([
          for (var i = 0; i < pages.length; i++)
            (label: '${i + 1}', text: pages[i]),
        ]).map((c) => c.toString()),
      );
    });
  });

  group('packing', () {
    test('short paragraphs on one page pack into a single chunk', () {
      final chunks =
          chunkPages(['Heading\n\nFirst paragraph.\n\nSecond paragraph.']);

      expect(chunks, hasLength(1));
      expect(chunks.single.text,
          'Heading\n\nFirst paragraph.\n\nSecond paragraph.');
    });

    test('CRLF line endings are normalised', () {
      expect(chunkPages(['One\r\n\r\nTwo']).single.text, 'One\n\nTwo');
    });

    test('paragraphs never pack across a page boundary', () {
      final chunks = chunkPages(['A', 'B']);

      expect(chunks, hasLength(2));
      expect(chunks.map((c) => c.text), ['A', 'B']);
    });
  });

  group('the cap', () {
    test('a paragraph that would overflow starts a new chunk', () {
      final p = 'a' * 400;
      final chunks = chunkPages(['$p\n\n$p']);

      expect(chunks, hasLength(2));
      expect(chunks.every((c) => c.text.length <= kMaxChunkChars), isTrue);
    });

    test('exactly at the cap is one chunk; one over splits in two', () {
      expect(chunkPages(['a' * 700]), hasLength(1));

      final over = chunkPages(['a' * 701]);
      expect(over.map((c) => c.text.length), [700, 1]);
    });

    test('just under the cap stays one chunk', () {
      expect(chunkPages(['a' * 699]), hasLength(1));
    });

    test('an over-long paragraph splits on sentence boundaries', () {
      final sentence = '${'word ' * 30}end.';
      final chunks = chunkPages([List.filled(8, sentence).join(' ')]);

      expect(chunks.length, greaterThan(1));
      expect(chunks.every((c) => c.text.length <= kMaxChunkChars), isTrue);
      expect(chunks.every((c) => c.text.endsWith('end.')), isTrue);
    });

    test('an unbroken run is hard-cut and loses no characters', () {
      final run = 'x' * 2000;
      final chunks = chunkPages([run]);

      expect(chunks.every((c) => c.text.length <= kMaxChunkChars), isTrue);
      expect(chunks.map((c) => c.text).join(), run);
    });

    test('a custom maxChars is honoured', () {
      final chunks = chunkPages(['a' * 100], maxChars: 40);

      expect(chunks.map((c) => c.text.length), [40, 40, 20]);
    });

    test('a maxChars too small to hold a surrogate pair is rejected', () {
      expect(() => chunkPages(['abc'], maxChars: 1), throwsArgumentError);
    });
  });

  // ── Edge cases ──────────────────────────────────────────────────────────

  group('unicode', () {
    test('the Devanagari danda ends a sentence', () {
      final sentence = '${'भारत ' * 30}है।';
      final chunks = chunkPages([List.filled(8, sentence).join(' ')]);

      expect(chunks.length, greaterThan(1));
      expect(chunks.every((c) => c.text.endsWith('है।')), isTrue);
      expect(chunks.every((c) => c.text.length <= kMaxChunkChars), isTrue);
    });

    test('a hard cut never splits a surrogate pair', () {
      final text = 'a${'😀' * 500}';
      final chunks = chunkPages([text]);

      for (final c in chunks) {
        expect(c.text.length, lessThanOrEqualTo(kMaxChunkChars));
        final first = c.text.codeUnitAt(0);
        final last = c.text.codeUnitAt(c.text.length - 1);
        expect(first >= 0xDC00 && first <= 0xDFFF, isFalse,
            reason: 'starts on a low surrogate');
        expect(last >= 0xD800 && last <= 0xDBFF, isFalse,
            reason: 'ends on a high surrogate');
      }
      expect(chunks.map((c) => c.text).join(), text);
    });

    test('RTL text survives chunking intact', () {
      const arabic = 'مرحبا بالعالم هذه سياسة الإجازات المعدلة. ';
      final chunks = chunkPages([arabic * 40]);

      expect(chunks.map((c) => c.text).join(' ').replaceAll(RegExp(r'\s+'), ' '),
          contains('مرحبا بالعالم'));
      expect(chunks.every((c) => c.text.length <= kMaxChunkChars), isTrue);
    });
  });

  group('scale', () {
    test('a long multi-page document respects the cap on every chunk', () {
      final page =
          List.generate(200, (i) => 'Line $i of the document body.').join('\n');
      final chunks = chunkPages([page, page]);

      expect(chunks.length, greaterThan(10));
      expect(chunks.every((c) => c.text.length <= kMaxChunkChars), isTrue);
      expect(chunks.map((c) => c.label).toSet(), {'1', '2'});
      expect(chunks.map((c) => c.ordinal).toList(),
          List.generate(chunks.length, (i) => i));
    });
  });
}
