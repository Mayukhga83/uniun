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
    expect(p, contains('URLs'));
  });

  test('forbids translating URLs and identifiers', () {
    expect(build('x'), contains('Never translate a URL'));
  });

  test('offers the NOOP sentinel for already-translated notes', () {
    expect(build('x'), contains(TranslationPrompt.noopSentinel));
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
