import 'package:uniun/core/i18n/translation_language.dart';
import 'package:uniun/features/shiv/generation/prompt/prompt_parts.dart';

/// Prompt for translating one note into the user's chosen language.
///
/// A one-shot call, not a chat turn — the note goes in, the translation comes
/// out, nothing is remembered. Runs through the same `GenerateOneShotUseCase`
/// as every other one-shot, so it works on the local model or UNIUN Cloud
/// without this builder knowing which.
class TranslationPrompt {
  const TranslationPrompt._();

  /// Sentinel for "this is already in the target language". Reusing the shared
  /// NOOP token rather than inventing a second one keeps the strip/skip logic
  /// consistent with Gana and Nataraj.
  static const String noopSentinel = PromptParts.noopSentinel;

  static String build({
    required String content,
    required TranslationLanguage target,
  }) {
    final buf = StringBuffer();
    buf.writeln(PromptParts.noThink);
    buf
      ..writeln('You are a translator. Translate the NOTE below into '
          '${target.englishName}.')
      ..writeln()
      ..writeln('Hard rules:')
      ..writeln('- Output ONLY the translation. No preamble, no notes, no '
          'explanation, no quotes around it, no romanisation.')
      // Notes are Nostr content: markdown, #hashtags, npubs and URLs are
      // load-bearing and must survive the round trip verbatim.
      ..writeln('- Preserve the original formatting: line breaks, markdown, '
          'emoji, #hashtags, @mentions and URLs stay exactly as they are.')
      ..writeln('- Translate only the prose. Never translate a URL, a hashtag '
          'body, or an identifier like an npub/hex key.')
      ..writeln('- Keep the original tone and register. Do not summarise, '
          'expand, censor, or answer the note — only translate it.')
      // Only fires for code-mixed input; a plain single-language note ignores
      // it. Named explicitly because romanised Hindi has no standard spelling,
      // so models otherwise tend to transliterate it back instead of reading
      // it for meaning.
      ..writeln('- If (and only if) the note is code-mixed or romanised '
          '(e.g. Hinglish, Arabizi — a language typed in Latin script and '
          'mixed with English), read it for MEANING rather than script: '
          'translate what the author is actually saying, never transliterate '
          'word-for-word.')
      // Deliberately NOT an "already in this language" escape: a small model
      // reaches for the easiest exit, so a 0.6B asked for a language it cannot
      // write would emit the sentinel and we'd wrongly tell the user their
      // note was already in that language. Reserved for a genuine inability,
      // which the caller reports honestly.
      ..writeln('- Always produce a translation if you can. Only if you are '
          'genuinely unable to write ${target.englishName} at all, output '
          'exactly this token and nothing else: $noopSentinel')
      ..writeln()
      ..writeln('NOTE:')
      ..writeln(content)
      ..writeln()
      ..writeln('Now output the ${target.englishName} translation, or '
          '$noopSentinel.');
    return buf.toString();
  }
}
