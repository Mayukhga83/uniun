import 'package:uniun/core/i18n/translation_language.dart';
import 'package:uniun/features/shiv/generation/prompt/prompt_parts.dart';

/// Builds the one-shot prompt for translating a note into [TranslationLanguage].
///
/// Routed through `GenerateOneShotUseCase`, so the same prompt serves the local
/// model and UNIUN Cloud.
///
/// Terse by necessity: prefill dominates on-device cost (measured 19.9s prefill
/// vs 3s decode), so every instruction token delays the first output character.
class TranslationPrompt {
  const TranslationPrompt._();

  /// Emitted when the model genuinely cannot write the target language.
  /// Reusing the shared NOOP token rather than inventing a second one keeps
  /// the strip/skip logic consistent with Gana and Nataraj.
  static const String noopSentinel = PromptParts.noopSentinel;

  static String build({
    required String content,
    required TranslationLanguage target,
  }) {
    final lang = target.englishName;
    return '''${PromptParts.noThink}
Translate the NOTE into $lang.

Rules:
- Output only the translation. No preamble, quotes or commentary.
- Keep line breaks, markdown, emoji, #hashtags, @mentions and URLs exactly as-is; never translate a URL, hashtag or key.
- Keep the tone. Do not summarise, answer or explain.
- Only if the note is code-mixed/romanised (e.g. Hinglish): translate the meaning, not the spelling.
- If you cannot write $lang, output exactly: $noopSentinel

NOTE:
$content
''';
  }
}
