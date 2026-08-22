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

  /// Mirrors what NoteCardMenu._onTranslate does: reuse the stored language,
  /// or fall back to the app locale on first run and remember it.
  Future<TranslationLanguage> resolveTarget(String appLocale) async {
    final stored = (await getLang.call()).fold((_) => null, (c) => c);
    if (stored != null) return TranslationLanguage.fromCode(stored);
    final seeded = TranslationLanguage.fromCode(appLocale);
    await setLang.call(seeded.code);
    return seeded;
  }

  test('first run seeds from the app locale, persists, and is reused after',
      () async {
    expect((await getLang.call()).getOrElse(() => 'x'), isNull);

    final first = await resolveTarget('hi');
    expect(first.code, 'hi');
    expect((await getLang.call()).getOrElse(() => null), 'hi');

    // A later note translates with no picker involved — even if the app
    // locale has since changed, the user's explicit choice wins.
    final second = await resolveTarget('en');
    expect(second.code, 'hi');
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
    expect(llm.lastPrompt, contains('Never translate a URL'));
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

  test('a note already in the target language yields null, not echoed text',
      () async {
    llm.reply = TranslationPrompt.noopSentinel;

    final result = await translate.call(TranslateNoteInput(
      content: 'already english',
      target: TranslationLanguage.fromCode('en'),
    ));

    expect(result.isRight(), isTrue);
    expect(result.getOrElse(() => 'sentinel-leaked'), isNull);
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
