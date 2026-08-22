import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/core/i18n/translation_language.dart';
import 'package:uniun/data/datasources/app_settings_store.dart';
import 'package:uniun/data/repositories/app_settings_repository_impl.dart';
import 'package:uniun/domain/entities/llm/llm_task_kind.dart';
import 'package:uniun/domain/entities/llm/llm_backend_type.dart';
import 'package:uniun/domain/repositories/llm_repository.dart';
import 'package:uniun/domain/usecases/app_settings_usecases.dart';
import 'package:uniun/domain/usecases/llm_usecases.dart';
import 'package:uniun/features/shiv/generation/prompt/translation_prompt.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records what reached the LLM boundary so the test can assert on the real
/// prompt and scheduler tier, while standing in for the model itself. Every
/// layer above this is production code.
class _RecordingLlmRepository implements LlmRepository {
  String? lastPrompt;
  LlmTaskKind? lastKind;
  int? lastMaxTokens;

  /// What the "model" answers next — set per scenario.
  String? reply;
  Failure? failure;

  @override
  Future<Either<Failure, String?>> generateOneShot({
    required String prompt,
    int maxTokens = 1024,
    LlmTaskKind kind = LlmTaskKind.extract,
    LlmBackendType? backendOverride,
    String? modelIdOverride,
  }) async {
    lastPrompt = prompt;
    lastKind = kind;
    lastMaxTokens = maxTokens;
    if (failure != null) return Left(failure!);
    return Right(reply);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// End-to-end note translation, driving the real settings store, the real
/// use cases and the real prompt builder — only the model itself is stood in
/// for. Covers the user-visible scenarios behind issue #43:
///
///   1. First run: no stored language → caller seeds from the app locale,
///      the choice persists, and the next translation reuses it silently
///   2. The prompt that reaches the model names the right target language
///      and carries the note verbatim
///   3. Translation is dispatched at the foreground scheduler tier
///   4. "Already in that language" comes back as null, not as fake text
///   5. A model failure propagates as Left, leaving the stored language alone
///   6. Changing the language later re-persists and re-targets
void main() {
  late _RecordingLlmRepository llm;
  late TranslateNoteUseCase translate;
  late GetTranslationLanguageUseCase getLang;
  late SetTranslationLanguageUseCase setLang;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final settings = AppSettingsRepositoryImpl(AppSettingsStore(prefs));
    getLang = GetTranslationLanguageUseCase(settings);
    setLang = SetTranslationLanguageUseCase(settings);
    llm = _RecordingLlmRepository();
    translate = TranslateNoteUseCase(llm);
  });

  /// Mirrors NoteCardMenu._onTranslate: the picker opens every time,
  /// preselected with the stored language (app locale until one is chosen).
  /// [pick] stands in for what the user taps — null means they confirmed the
  /// preselection, which is the one-tap common case.
  Future<TranslationLanguage> resolveTarget(
    String appLocale, {
    String? pick,
  }) async {
    final stored = (await getLang.call()).fold((_) => null, (c) => c);
    final seed = TranslationLanguage.fromCode(stored ?? appLocale);
    final picked = pick == null ? seed : TranslationLanguage.fromCode(pick);
    if (picked.code != stored) await setLang.call(picked.code);
    return picked;
  }

  /// What the sheet would preselect on the next translate.
  Future<String> nextSeed(String appLocale) async {
    final stored = (await getLang.call()).fold((_) => null, (c) => c);
    return TranslationLanguage.fromCode(stored ?? appLocale).code;
  }

  test('first run preselects the app locale and persists what is confirmed',
      () async {
    expect((await getLang.call()).getOrElse(() => 'x'), isNull);

    final first = await resolveTarget('hi');
    expect(first.code, 'hi');
    expect((await getLang.call()).getOrElse(() => null), 'hi');

    // Even if the app locale later changes, the user's explicit choice is
    // what the picker comes back preselected with.
    expect(await nextSeed('en'), 'hi');
  });

  test('picking a different language sticks — the NEXT translate preselects '
      'it, and does not fall back to the app locale', () async {
    // Regression: reported as "picked Gujarati, next note went back to
    // English". The stored choice must win over the app locale every time.
    await resolveTarget('en');
    expect(await nextSeed('en'), 'en');

    final second = await resolveTarget('en', pick: 'gu');
    expect(second.code, 'gu');
    expect((await getLang.call()).getOrElse(() => null), 'gu');

    expect(await nextSeed('en'), 'gu');
    final third = await resolveTarget('en');
    expect(third.code, 'gu');
  });

  test('confirming the preselection does not rewrite the stored value',
      () async {
    await resolveTarget('en', pick: 'gu');
    for (var i = 0; i < 3; i++) {
      expect((await resolveTarget('en')).code, 'gu');
    }
    expect((await getLang.call()).getOrElse(() => null), 'gu');
  });

  test('the prompt reaching the model names the target and carries the note',
      () async {
    llm.reply = 'नमस्ते दुनिया';
    final target = await resolveTarget('hi');

    final result = await translate.call(
      TranslateNoteInput(content: 'hello world #tag', target: target),
    );

    expect(result.getOrElse(() => null), 'नमस्ते दुनिया');
    expect(llm.lastPrompt, contains('Hindi'));
    expect(llm.lastPrompt, contains('hello world #tag'));
    expect(llm.lastPrompt, contains('never translate a URL'));
  });

  test('translation runs at the foreground tier, above background producers',
      () async {
    llm.reply = 'x';
    await translate.call(TranslateNoteInput(
      content: 'a',
      target: TranslationLanguage.fromCode('ja'),
    ));

    expect(llm.lastKind, LlmTaskKind.translate);
    // Non-Latin output needs more room than the Latin source.
    expect(llm.lastMaxTokens, greaterThan(1024));
  });

  test('the NOOP sentinel yields null rather than leaking into the card',
      () async {
    llm.reply = TranslationPrompt.noopSentinel;

    final result = await translate.call(TranslateNoteInput(
      content: 'already english',
      target: TranslationLanguage.fromCode('en'),
    ));

    expect(result.isRight(), isTrue);
    expect(result.getOrElse(() => 'sentinel-leaked'), isNull);
  });

  test('a model that echoes the source back counts as no translation', () async {
    // Observed on device: Qwen3 0.6B handed back the English source when asked
    // for Gujarati. Swapping the body for an identical copy would look like a
    // successful translation.
    llm.reply = 'hello world';
    final result = await translate.call(TranslateNoteInput(
      content: 'hello world',
      target: TranslationLanguage.fromCode('gu'),
    ));
    expect(result.getOrElse(() => 'leaked'), isNull);
  });

  test('an echo differing only by surrounding whitespace is still an echo',
      () async {
    llm.reply = '  hello world \n';
    final result = await translate.call(TranslateNoteInput(
      content: 'hello world',
      target: TranslationLanguage.fromCode('gu'),
    ));
    expect(result.getOrElse(() => 'leaked'), isNull);
  });

  test('corrupted model output is rejected, not shown as a translation',
      () async {
    // Real Qwen3 0.6B output captured on device, asked for a script it could
    // not write: partially-repaired bytes plus replacement chars.
    llm.reply = 'UNIUN \u0995\u09c1\u09b2\u09c7 \uFFFD\u00ae\u09b0\u09bf\u0120\u00e0\u00a6\u00b8';
    final result = await translate.call(TranslateNoteInput(
      content: 'hello world',
      target: TranslationLanguage.fromCode('bn'),
    ));
    expect(result.getOrElse(() => 'leaked'), isNull);
  });

  test('a repetition loop is rejected, not shown as a translation', () async {
    llm.reply = 'kare pro kule kare pro kule kare pro kule kare pro kule '
        'kare pro kule kare pro kule';
    final result = await translate.call(TranslateNoteInput(
      content: 'hello world',
      target: TranslationLanguage.fromCode('gu'),
    ));
    expect(result.getOrElse(() => 'leaked'), isNull);
  });

  test('a blank or whitespace-only model answer is treated as no translation',
      () async {
    for (final blank in ['', '   ', '\n\n']) {
      llm.reply = blank;
      final result = await translate.call(TranslateNoteInput(
        content: 'hi',
        target: TranslationLanguage.fromCode('fr'),
      ));
      expect(result.getOrElse(() => 'leaked'), isNull, reason: '"$blank"');
    }
  });

  test('a model failure propagates as Left and does not disturb the '
      'stored language', () async {
    await resolveTarget('hi');
    llm.failure = const Failure.errorFailure('model unavailable');

    final result = await translate.call(TranslateNoteInput(
      content: 'hello',
      target: TranslationLanguage.fromCode('hi'),
    ));

    expect(result.isLeft(), isTrue);
    expect((await getLang.call()).getOrElse(() => null), 'hi');
  });

  test('changing the language later re-persists and re-targets the prompt',
      () async {
    await resolveTarget('hi');
    llm.reply = 'こんにちは';

    await setLang.call('ja');
    final target = await resolveTarget('hi'); // stored now wins
    expect(target.code, 'ja');

    await translate.call(
      TranslateNoteInput(content: 'hello', target: target),
    );
    expect(llm.lastPrompt, contains('Japanese'));
    expect(llm.lastPrompt, isNot(contains('into Hindi')));
  });
}
