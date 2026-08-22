import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/common/widgets/note_card/cubit/note_card_cubit.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/core/i18n/translation_language.dart';
import 'package:uniun/domain/entities/profile/profile_entity.dart';
import 'package:uniun/domain/usecases/blocked_user_usecases.dart';
import 'package:uniun/domain/usecases/deleted_note_usecases.dart';
import 'package:uniun/domain/usecases/followed_note_usecases.dart';
import 'package:uniun/domain/usecases/llm_usecases.dart';
import 'package:uniun/domain/usecases/manas_usecases.dart';
import 'package:uniun/domain/usecases/profile_usecases.dart';
import 'package:uniun/domain/usecases/saved_note_usecases.dart';
import 'package:uniun/domain/usecases/user_usecases.dart';
import 'package:uniun/domain/usecases/vector_usecases.dart';

import '../../../_helpers/fixtures.dart';

class _MWatchProfile extends Mock implements WatchProfileUseCase {}
class _MRequestProfile extends Mock implements RequestProfileFetchUseCase {}
class _MIsSaved extends Mock implements IsSavedNoteUseCase {}
class _MSave extends Mock implements SaveNoteUseCase {}
class _MUnsave extends Mock implements UnsaveNoteUseCase {}
class _MEmbed extends Mock implements EmbedAndStoreNoteUseCase {}
class _MWatchFollowed extends Mock implements WatchIsFollowedUseCase {}
class _MFollow extends Mock implements FollowNoteUseCase {}
class _MUnfollow extends Mock implements UnfollowNoteUseCase {}
class _MBlock extends Mock implements BlockUserUseCase {}
class _MDelete extends Mock implements DeleteNoteUseCase {}
class _MGetActive extends Mock implements GetActiveUserUseCase {}
class _MManasIds extends Mock implements GetManasIdsForNoteUseCase {}
class _MManasList extends Mock implements GetManasListUseCase {}
class _MRemoveManas extends Mock implements RemoveNoteFromManasUseCase {}
class _MTranslate extends Mock implements TranslateNoteUseCase {}

/// Covers: NoteCardCubit.translate — the happy path, the already-in-language
/// NOOP path, failure surfacing, the re-translate short-circuit, the
/// in-flight guard, and toggleOriginal's cost-free flip.
void main() {
  late _MTranslate translate;
  late NoteCardCubit cubit;

  final hindi = TranslationLanguage.fromCode('hi');
  final japanese = TranslationLanguage.fromCode('ja');
  final note = aNote(id: 'n1', authorPubkey: kAlicePub, content: 'hello');

  setUpAll(() {
    registerFallbackValue(
      TranslateNoteInput(content: '', target: TranslationLanguage.all.first),
    );
  });

  setUp(() {
    translate = _MTranslate();
    final watchProfile = _MWatchProfile();
    final watchFollowed = _MWatchFollowed();
    final isSaved = _MIsSaved();
    final getActive = _MGetActive();
    final requestProfile = _MRequestProfile();

    when(() => watchProfile.call(any()))
        .thenAnswer((_) => const Stream<ProfileEntity?>.empty());
    when(() => watchFollowed.call(any()))
        .thenAnswer((_) => const Stream<bool>.empty());
    when(() => isSaved.call(any()))
        .thenAnswer((_) async => const Right(false));
    when(() => getActive.call())
        .thenAnswer((_) async => Left(Failure.errorFailure('none')));
    when(() => requestProfile.call(any()))
        .thenAnswer((_) async => const Right(unit));

    cubit = NoteCardCubit(
      watchProfile,
      requestProfile,
      isSaved,
      _MSave(),
      _MUnsave(),
      _MEmbed(),
      watchFollowed,
      _MFollow(),
      _MUnfollow(),
      _MBlock(),
      _MDelete(),
      getActive,
      _MManasIds(),
      _MManasList(),
      _MRemoveManas(),
      translate,
      note,
    );
  });

  tearDown(() => cubit.close());

  test('a successful translation swaps into the body and records the language',
      () async {
    when(() => translate.call(any()))
        .thenAnswer((_) async => const Right('नमस्ते'));

    await cubit.translate(hindi);

    expect(cubit.state.translation, 'नमस्ते');
    expect(cubit.state.translationLanguage, 'hi');
    expect(cubit.state.showsTranslation, isTrue);
    expect(cubit.state.isTranslating, isFalse);
    expect(cubit.state.translationError, isNull);
  });

  test('the note content and target are forwarded to the use case', () async {
    when(() => translate.call(any()))
        .thenAnswer((_) async => const Right('x'));

    await cubit.translate(japanese);

    final captured = verify(() => translate.call(captureAny())).captured.single
        as TranslateNoteInput;
    expect(captured.content, 'hello');
    expect(captured.target.code, 'ja');
  });

  test('Right(null) — no usable translation — is surfaced, not a body swap',
      () async {
    when(() => translate.call(any()))
        .thenAnswer((_) async => const Right(null));

    await cubit.translate(hindi);

    expect(cubit.state.translation, isNull);
    expect(cubit.state.showsTranslation, isFalse);
    expect(
      cubit.state.translationError,
      NoteCardCubit.kNoTranslationProduced,
    );
  });

  test('a Left failure surfaces its message and leaves the body untouched',
      () async {
    when(() => translate.call(any()))
        .thenAnswer((_) async => Left(Failure.errorFailure('model gone')));

    await cubit.translate(hindi);

    expect(cubit.state.translation, isNull);
    expect(cubit.state.isTranslating, isFalse);
    expect(cubit.state.translationError, isNotNull);
    expect(
      cubit.state.translationError,
      isNot(NoteCardCubit.kNoTranslationProduced),
    );
  });

  test('re-translating into the SAME language does not call the model again',
      () async {
    when(() => translate.call(any()))
        .thenAnswer((_) async => const Right('नमस्ते'));
    await cubit.translate(hindi);
    cubit.toggleOriginal();
    expect(cubit.state.showOriginal, isTrue);

    await cubit.translate(hindi);

    // Short-circuits to un-hiding the translation we already have.
    verify(() => translate.call(any())).called(1);
    expect(cubit.state.showOriginal, isFalse);
  });

  test('translating into a DIFFERENT language does call the model again',
      () async {
    when(() => translate.call(any()))
        .thenAnswer((_) async => const Right('a'));
    await cubit.translate(hindi);
    await cubit.translate(japanese);

    verify(() => translate.call(any())).called(2);
    expect(cubit.state.translationLanguage, 'ja');
  });

  test('a second translate while one is in flight is dropped', () async {
    final gate = Completer<Either<Failure, String?>>();
    when(() => translate.call(any())).thenAnswer((_) => gate.future);

    final first = cubit.translate(hindi);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.isTranslating, isTrue);

    await cubit.translate(japanese); // must be ignored
    gate.complete(const Right('done'));
    await first;

    verify(() => translate.call(any())).called(1);
  });

  test('toggleOriginal flips both ways and keeps the translation in state',
      () async {
    when(() => translate.call(any()))
        .thenAnswer((_) async => const Right('नमस्ते'));
    await cubit.translate(hindi);

    cubit.toggleOriginal();
    expect(cubit.state.showOriginal, isTrue);
    expect(cubit.state.showsTranslation, isFalse);
    expect(cubit.state.translation, 'नमस्ते');

    cubit.toggleOriginal();
    expect(cubit.state.showsTranslation, isTrue);
  });

  test('clearTranslationError clears it without touching the translation',
      () async {
    when(() => translate.call(any()))
        .thenAnswer((_) async => const Right(null));
    await cubit.translate(hindi);
    expect(cubit.state.translationError, isNotNull);

    cubit.clearTranslationError();
    expect(cubit.state.translationError, isNull);
  });
}
