import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/core/i18n/translation_language.dart';
import 'package:uniun/features/shiv/generation/prompt/translation_prompt.dart';

/// Covers: the translation prompt's target-language naming, its preservation
/// rules for Nostr-load-bearing syntax, the NOOP escape hatch, and that note
/// content rides through verbatim (no collapsing/truncation).
void main() {
  final hindi = TranslationLanguage.fromCode('hi');

  String build(String content, [TranslationLanguage? target]) =>
      TranslationPrompt.build(content: content, target: target ?? hindi);

  test('names the target in English, not by code — models follow it better',
      () {
    final p = build('hello');
    expect(p, contains('Hindi'));
    expect(p, isNot(contains(' hi ')));
  });

  test('leads with the no-think switch so Qwen does not burn the budget', () {
    expect(build('hello').trimLeft(), startsWith('/no_think'));
  });

  test('instructs the model to preserve markdown, hashtags, mentions and URLs',
      () {
    final p = build('x');
    expect(p, contains('markdown'));
    expect(p, contains('#hashtags'));
    expect(p, contains('@mentions'));
    expect(p, contains('URLs'));
  });

  test('forbids translating URLs and identifiers', () {
    expect(build('x'), contains('never translate a URL'));
  });

  test('the NOOP sentinel is reserved for genuine inability, not an easy '
      'already-in-this-language exit', () {
    final p = build('x');
    expect(p, contains(TranslationPrompt.noopSentinel));
    expect(p, contains('If you cannot write Hindi'));
    // A small model reaches for the cheapest exit; offering "already in this
    // language" as one made it lie about notes it simply could not translate.
    expect(p, isNot(contains('ALREADY')));
    expect(p, isNot(contains('already in')));
  });

  test('note content is embedded verbatim — newlines and markup survive', () {
    const content = '# Heading\n\n- bullet **bold**\nhttps://a.example #tag';
    expect(build(content), contains(content));
  });

  test('unicode, RTL and emoji content pass through unchanged', () {
    for (final content in ['مرحبا بالعالم', '🎉 שלום', '日本語テキスト']) {
      expect(build(content), contains(content), reason: content);
    }
  });

  test('the code-mix rule is conditional so a plain note is unaffected', () {
    final p = build('just a normal english sentence');
    // Present, but gated — it must not read as an instruction that applies to
    // every note, or a small model may mangle plain single-language input.
    expect(p, contains('code-mixed'));
    expect(p, contains('Only if the note is'));
  });

  test('romanised Hinglish content survives into the prompt verbatim', () {
    const content = 'kal milte hain yaar, party bohot mast thi';
    expect(build(content), contains(content));
  });

  test('instruction overhead stays lean — prefill dominates on-device cost',
      () {
    // Measured on device: 19.9s prefill vs 3s decode. Every instruction token
    // is paid before the user sees anything, so this is a real budget, not a
    // style preference. Was ~995 chars before trimming.
    final overhead = build('').length;
    expect(overhead, lessThan(600));
  });

  test('the target language is named exactly twice — instruction and NOOP '
      'line; a third restatement is pure prefill cost', () {
    final p = build('x');
    expect('Hindi'.allMatches(p), hasLength(2));
  });

  test('an empty note still produces a well-formed prompt', () {
    final p = build('');
    expect(p, contains('NOTE:'));
    expect(p, contains('Hindi'));
  });

  test('the target language varies the instruction, not just the header', () {
    expect(build('x', TranslationLanguage.fromCode('ja')), contains('Japanese'));
    expect(
      build('x', TranslationLanguage.fromCode('ja')),
      isNot(contains('Hindi')),
    );
  });
}
