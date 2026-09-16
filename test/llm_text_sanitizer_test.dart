import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/core/utils/llm_text_sanitizer.dart';

void main() {
  test('strips tool-call envelope', () {
    final out = LlmTextSanitizer.clean('publish_message(body="hello world")');
    expect(out, 'hello world');
  });

  test('decodes GPT-2 byte-encoded emoji 🌱', () {
    // ð=0xF0 Ł=U+0141 Į=U+012E ±=0xB1 — the encoding for 🌱 (UTF-8 F0 9F 8C B1)
    final input = 'lesson ${String.fromCharCodes([0x00F0, 0x0141, 0x012E, 0x00B1])}';
    final out = LlmTextSanitizer.clean(input);
    expect(out, contains('🌱'));
  });

  test('combined: envelope + emoji', () {
    final body = 'A life lesson: keep growing. ${String.fromCharCodes([0x00F0, 0x0141, 0x012E, 0x00B1])}';
    final out = LlmTextSanitizer.clean('publish_message(body="$body")');
    expect(out, 'A life lesson: keep growing. 🌱');
  });

  test('leaves clean text unchanged', () {
    expect(LlmTextSanitizer.clean('hello world'), 'hello world');
    expect(LlmTextSanitizer.clean('Hola, ¿cómo estás?'), 'Hola, ¿cómo estás?');
  });

  test('strips balanced <think>...</think> blocks', () {
    final out = LlmTextSanitizer.clean(
        '<think>Let me think about this...</think>The answer is 42.');
    expect(out, 'The answer is 42.');
  });

  test('returns empty when truncated mid-think', () {
    final out = LlmTextSanitizer.clean(
        '<think> Okay, the user wants a good motivation life lesson. Let me think abou');
    expect(out, '');
  });

  test('strips multiple think blocks', () {
    final out = LlmTextSanitizer.clean(
        '<think>step 1</think>Hi <think>step 2</think>there.');
    expect(out, contains('Hi'));
    expect(out, contains('there.'));
    expect(out, isNot(contains('<think>')));
  });

  group('echoed answer-cue label (#220)', () {
    test('a leading "Shiv:" the model copied from the cue is dropped', () {
      expect(LlmTextSanitizer.clean('Shiv: I am Shiv, the assistant.'),
          'I am Shiv, the assistant.');
    });

    test('spacing and case variants are dropped too', () {
      for (final raw in [
        'Shiv:hello',
        'Shiv : hello',
        '  shiv:   hello',
        'SHIV: hello',
      ]) {
        expect(LlmTextSanitizer.clean(raw), 'hello', reason: raw);
      }
    });

    test('only the FIRST label goes — a later one is real content', () {
      expect(LlmTextSanitizer.clean('Shiv: quoting Shiv: verbatim'),
          'quoting Shiv: verbatim');
    });

    test('a word merely starting with the label is untouched', () {
      expect(LlmTextSanitizer.clean('Shivam asked me something'),
          'Shivam asked me something');
    });

    test('a label mid-answer is untouched — only a leading echo is a cue', () {
      expect(LlmTextSanitizer.clean('The note says Shiv: hello'),
          'The note says Shiv: hello');
    });

    test('label after a think block is still dropped', () {
      expect(LlmTextSanitizer.clean('<think>hmm</think>Shiv: hello'), 'hello');
    });

    test('a bare label with no answer collapses to empty', () {
      expect(LlmTextSanitizer.clean('Shiv:'), isEmpty);
    });

    test('an ordinary answer is unchanged', () {
      expect(LlmTextSanitizer.clean('Gana testing refers to a process.'),
          'Gana testing refers to a process.');
    });
  });
}
