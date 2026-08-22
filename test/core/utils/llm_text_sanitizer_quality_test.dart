import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/core/utils/llm_text_sanitizer.dart';

/// Covers: LlmTextSanitizer's output-quality guards — corruption detection
/// (U+FFFD, unrepaired GPT-2 byte chars) and repetition-loop detection.
/// Fixtures include real Qwen3 0.6B output captured on device when asked for
/// a script it could not write.
void main() {
  group('looksCorrupted', () {
    test('real on-device wreckage is rejected', () {
      const sample = 'UNIUN কুলে সা�®রি�ķĠà¦¸্�¥া�¨Ġà¦ķরে প্�°à§īসেসে গা�¨া রোযা';
      expect(LlmTextSanitizer.looksCorrupted(sample), isTrue);
    });

    test('a lone U+FFFD replacement char is enough', () {
      expect(LlmTextSanitizer.looksCorrupted('hello \uFFFD world'), isTrue);
    });

    test('unrepaired GPT-2 byte chars are rejected', () {
      // U+0120 is the BPE space marker; surviving clean() means repair failed.
      expect(LlmTextSanitizer.looksCorrupted('sa\u0120mri'), isTrue);
    });

    test('healthy text in non-Latin scripts is NOT flagged', () {
      for (final good in [
        'નમસ્તે દુનિયા',
        'नमस्ते दुनिया',
        'こんにちは世界',
        'مرحبا بالعالم',
        'Hello world 🎉',
        '',
      ]) {
        expect(LlmTextSanitizer.looksCorrupted(good), isFalse, reason: good);
      }
    });
  });

  group('looksDegenerate', () {
    test('a stuck repetition loop is rejected', () {
      const loop = 'samrik sthan kare pro kule samrik sthan kare pro kule '
          'samrik sthan kare pro kule samrik sthan kare pro kule';
      expect(LlmTextSanitizer.looksDegenerate(loop), isTrue);
    });

    test('normal prose is not flagged', () {
      const prose = 'The quick brown fox jumps over the lazy dog while the '
          'sun sets behind distant hills and the river runs quietly on.';
      expect(LlmTextSanitizer.looksDegenerate(prose), isFalse);
    });

    test('short text is exempt — a repeated word in three words is fine', () {
      expect(LlmTextSanitizer.looksDegenerate('no no no'), isFalse);
      expect(LlmTextSanitizer.looksDegenerate('bye bye'), isFalse);
    });

    test('devanagari danda and CJK punctuation count as separators', () {
      const loop = 'काम काम काम काम काम। काम काम काम काम काम। काम काम काम';
      expect(LlmTextSanitizer.looksDegenerate(loop), isTrue);
    });
  });
}
