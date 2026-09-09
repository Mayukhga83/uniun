import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/common/widgets/note_card/cubit/note_card_cubit.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/domain/entities/profile/profile_entity.dart';
import 'package:uniun/domain/usecases/llm_usecases.dart';
import 'package:uniun/domain/usecases/blocked_user_usecases.dart';
import 'package:uniun/domain/usecases/deleted_note_usecases.dart';
import 'package:uniun/domain/usecases/followed_note_usecases.dart';
import 'package:uniun/domain/usecases/manas_usecases.dart';
import 'package:uniun/domain/usecases/profile_usecases.dart';
import 'package:uniun/domain/usecases/saved_note_usecases.dart';
import 'package:uniun/domain/usecases/user_usecases.dart';
import 'package:uniun/domain/usecases/vector_usecases.dart';

import '../../../../_helpers/fixtures.dart';

class _MockWatchProfile extends Mock implements WatchProfileUseCase {}

class _MockRequestProfileFetch extends Mock
    implements RequestProfileFetchUseCase {}

class _MockIsSaved extends Mock implements IsSavedNoteUseCase {}

class _MockSaveNote extends Mock implements SaveNoteUseCase {}

class _MockUnsaveNote extends Mock implements UnsaveNoteUseCase {}

class _MockEmbed extends Mock implements EmbedAndStoreNoteUseCase {}

class _MockWatchIsFollowed extends Mock implements WatchIsFollowedUseCase {}

class _MockFollowNote extends Mock implements FollowNoteUseCase {}

class _MockUnfollowNote extends Mock implements UnfollowNoteUseCase {}

class _MockBlockUser extends Mock implements BlockUserUseCase {}

class _MockDeleteNote extends Mock implements DeleteNoteUseCase {}

class _MockGetActiveUser extends Mock implements GetActiveUserUseCase {}

class _MockGetManasIdsForNote extends Mock
    implements GetManasIdsForNoteUseCase {}

class _MockGetManasList extends Mock implements GetManasListUseCase {}

class _MockRemoveFromManas extends Mock implements RemoveNoteFromManasUseCase {}

class _MockTranslateNote extends Mock implements TranslateNoteUseCase {}

/// Covers: NoteCardCubit's reactive profile/follow watchers, own-note and
/// saved-flag hydration on init, optimistic save/unsave toggling (including
/// revert-on-failure and the RAG embed side-effect), ensureSavedForManas'
/// own-note/already-saved short circuit, manasesContainingNote's id→entity
/// join, unsaveWithManasRemoval's membership cleanup, follow toggling, block,
/// and delete (including the custom deleter override).
void main() {
  late _MockWatchProfile watchProfile;
  late _MockRequestProfileFetch requestProfileFetch;
  late _MockIsSaved isSaved;
  late _MockSaveNote saveNote;
  late _MockUnsaveNote unsaveNote;
  late _MockEmbed embed;
  late _MockWatchIsFollowed watchIsFollowed;
  late _MockFollowNote followNote;
  late _MockUnfollowNote unfollowNote;
  late _MockBlockUser blockUser;
  late _MockDeleteNote deleteNote;
  late _MockGetActiveUser getActiveUser;
  late _MockGetManasIdsForNote getManasIdsForNote;
  late _MockGetManasList getManasList;
  late _MockRemoveFromManas removeFromManas;
  late _MockTranslateNote translateNote;

  final note = aNote(id: 'n1', authorPubkey: kAlicePub);

  NoteCardCubit build() => NoteCardCubit(
        watchProfile,
        requestProfileFetch,
        isSaved,
        saveNote,
        unsaveNote,
        embed,
        watchIsFollowed,
        followNote,
        unfollowNote,
        blockUser,
        deleteNote,
        getActiveUser,
        getManasIdsForNote,
        getManasList,
        removeFromManas,
        translateNote,
        note,
      );

  setUpAll(() {
    registerFallbackValue(note);
    registerFallbackValue(('id', 'content'));
    registerFallbackValue(const FollowNoteInput(eventId: '', contentPreview: ''));
    registerFallbackValue(const ManasNoteLink('m', 'n'));
  });

  setUp(() {
    watchProfile = _MockWatchProfile();
    requestProfileFetch = _MockRequestProfileFetch();
    isSaved = _MockIsSaved();
    saveNote = _MockSaveNote();
    unsaveNote = _MockUnsaveNote();
    embed = _MockEmbed();
    watchIsFollowed = _MockWatchIsFollowed();
    followNote = _MockFollowNote();
    unfollowNote = _MockUnfollowNote();
    blockUser = _MockBlockUser();
    deleteNote = _MockDeleteNote();
    getActiveUser = _MockGetActiveUser();
    getManasIdsForNote = _MockGetManasIdsForNote();
    getManasList = _MockGetManasList();
    removeFromManas = _MockRemoveFromManas();
    translateNote = _MockTranslateNote();

    when(() => watchProfile.call(any())).thenAnswer((_) => const Stream.empty());
    when(() => requestProfileFetch.call(any()))
        .thenAnswer((_) async => const Right(unit));
    when(() => watchIsFollowed.call(any())).thenAnswer((_) => const Stream.empty());
    when(() => isSaved.call(any())).thenAnswer((_) async => const Right(false));
    when(() => getActiveUser.call())
        .thenAnswer((_) async => const Left(Failure.errorFailure('no user')));
    when(() => embed.call(any())).thenAnswer((_) async => const Right(unit));
  });

  test('init hydrates profile and follow state reactively, and isSaved/'
      'isOwnNote once', () async {
    when(() => watchProfile.call('alice-pub'))
        .thenAnswer((_) => Stream.value(aProfile(pubkey: kAlicePub)));
    when(() => watchIsFollowed.call('n1')).thenAnswer((_) => Stream.value(true));
    when(() => isSaved.call('n1')).thenAnswer((_) async => const Right(true));
    when(() => getActiveUser.call())
        .thenAnswer((_) async => Right(aUserKey(pubkeyHex: kAlicePub)));

    final cubit = build();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(cubit.state.profile?.pubkey, kAlicePub);
    expect(cubit.state.isFollowed, isTrue);
    expect(cubit.state.isSaved, isTrue);
    expect(cubit.state.isOwnNote, isTrue);
    verify(() => requestProfileFetch.call('alice-pub')).called(1);
    await cubit.close();
  });

  test('a null profile emission is ignored', () async {
    when(() => watchProfile.call(any())).thenAnswer((_) => Stream.value(null));
    final cubit = build();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(cubit.state.profile, isNull);
    await cubit.close();
  });

  group('toggleSave', () {
    test('saving optimistically flips the flag, then embeds on success',
        () async {
      when(() => saveNote.call(note)).thenAnswer(
          (_) async => Right(aSavedNote(eventId: note.id, content: 'saved content')));
      final cubit = build();
      await Future<void>.delayed(const Duration(milliseconds: 5));

      await cubit.toggleSave();

      expect(cubit.state.isSaved, isTrue);
      verify(() => embed.call((note.id, 'saved content'))).called(1);
      await cubit.close();
    });

    test('a save failure reverts the optimistic flag', () async {
      when(() => saveNote.call(note))
          .thenAnswer((_) async => const Left(Failure.errorFailure('boom')));
      final cubit = build();
      await Future<void>.delayed(const Duration(milliseconds: 5));

      await cubit.toggleSave();

      expect(cubit.state.isSaved, isFalse);
      verifyZeroInteractions(embed);
      await cubit.close();
    });

    test('unsaving optimistically flips the flag off', () async {
      when(() => isSaved.call('n1')).thenAnswer((_) async => const Right(true));
      when(() => unsaveNote.call('n1')).thenAnswer((_) async => const Right(unit));
      final cubit = build();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(cubit.state.isSaved, isTrue);

      await cubit.toggleSave();

      expect(cubit.state.isSaved, isFalse);
      await cubit.close();
    });

    test('an unsave failure reverts the optimistic flag back to saved',
        () async {
      when(() => isSaved.call('n1')).thenAnswer((_) async => const Right(true));
      when(() => unsaveNote.call('n1'))
          .thenAnswer((_) async => const Left(Failure.errorFailure('boom')));
      final cubit = build();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      await cubit.toggleSave();

      expect(cubit.state.isSaved, isTrue);
      await cubit.close();
    });
  });

  group('ensureSavedForManas', () {
    test('an own note is treated as already persisted, no save call',
        () async {
      when(() => getActiveUser.call())
          .thenAnswer((_) async => Right(aUserKey(pubkeyHex: kAlicePub)));
      final cubit = build();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final result = await cubit.ensureSavedForManas();

      expect(result, isTrue);
      verifyZeroInteractions(saveNote);
      await cubit.close();
    });

    test('an already-saved note short-circuits without saving again',
        () async {
      when(() => isSaved.call('n1')).thenAnswer((_) async => const Right(true));
      final cubit = build();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final result = await cubit.ensureSavedForManas();

      expect(result, isTrue);
      verifyZeroInteractions(saveNote);
      await cubit.close();
    });

    test('a foreign, unsaved note is saved and embedded', () async {
      when(() => saveNote.call(note))
          .thenAnswer((_) async => Right(aSavedNote(eventId: note.id, content: 'x')));
      final cubit = build();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final result = await cubit.ensureSavedForManas();

      expect(result, isTrue);
      expect(cubit.state.isSaved, isTrue);
      verify(() => embed.call((note.id, 'x'))).called(1);
      await cubit.close();
    });

    test('a save failure returns false', () async {
      when(() => saveNote.call(note))
          .thenAnswer((_) async => const Left(Failure.errorFailure('boom')));
      final cubit = build();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final result = await cubit.ensureSavedForManas();

      expect(result, isFalse);
      await cubit.close();
    });
  });

  group('manasesContainingNote', () {
    test('returns no manases when the note belongs to none', () async {
      when(() => getManasIdsForNote.call('n1'))
          .thenAnswer((_) async => const Right(<String>[]));
      final cubit = build();

      final result = await cubit.manasesContainingNote();

      expect(result, isEmpty);
      verifyZeroInteractions(getManasList);
      await cubit.close();
    });

    test('joins matching manas ids against the full list', () async {
      final m1 = aManas(manasId: 'm1');
      final m2 = aManas(manasId: 'm2');
      when(() => getManasIdsForNote.call('n1'))
          .thenAnswer((_) async => const Right(['m1']));
      when(() => getManasList.call()).thenAnswer((_) async => Right([m1, m2]));
      final cubit = build();

      final result = await cubit.manasesContainingNote();

      expect(result.map((m) => m.manasId), ['m1']);
      await cubit.close();
    });

    test('a lookup failure treats it as an empty id set', () async {
      when(() => getManasIdsForNote.call('n1'))
          .thenAnswer((_) async => const Left(Failure.errorFailure('boom')));
      final cubit = build();

      final result = await cubit.manasesContainingNote();

      expect(result, isEmpty);
      await cubit.close();
    });
  });

  test('unsaveWithManasRemoval removes every membership then unsaves, '
      'reverting isSaved on failure', () async {
    when(() => removeFromManas.call(any())).thenAnswer((_) async => const Right(unit));
    when(() => unsaveNote.call('n1'))
        .thenAnswer((_) async => const Left(Failure.errorFailure('boom')));
    final cubit = build();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    await cubit.unsaveWithManasRemoval(['m1', 'm2']);

    final links = verify(() => removeFromManas.call(captureAny())).captured
        .cast<ManasNoteLink>();
    expect(links.map((l) => l.manasId), ['m1', 'm2']);
    expect(links.every((l) => l.noteId == 'n1'), isTrue);
    expect(cubit.state.isSaved, isTrue);
    await cubit.close();
  });

  test('unsaveWithManasRemoval keeps isSaved false on success', () async {
    when(() => removeFromManas.call(any())).thenAnswer((_) async => const Right(unit));
    when(() => unsaveNote.call('n1')).thenAnswer((_) async => const Right(unit));
    final cubit = build();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    await cubit.unsaveWithManasRemoval(['m1']);

    expect(cubit.state.isSaved, isFalse);
    await cubit.close();
  });

  group('toggleFollow', () {
    test('follows when not currently followed', () async {
      when(() => followNote.call(any())).thenAnswer((_) async => const Right(unit));
      final cubit = build();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      await cubit.toggleFollow();

      final input = verify(() => followNote.call(captureAny())).captured.single
          as FollowNoteInput;
      expect(input.eventId, 'n1');
      await cubit.close();
    });

    test('unfollows when currently followed', () async {
      when(() => watchIsFollowed.call('n1')).thenAnswer((_) => Stream.value(true));
      when(() => unfollowNote.call(any())).thenAnswer((_) async => const Right(unit));
      final cubit = build();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      await cubit.toggleFollow();

      verify(() => unfollowNote.call('n1')).called(1);
      await cubit.close();
    });
  });

  test('blockUser delegates to the use case with the note author', () async {
    when(() => blockUser.call('alice-pub')).thenAnswer((_) async => const Right(unit));
    final cubit = build();

    final result = await cubit.blockUser();

    expect(result, const Right(unit));
    await cubit.close();
  });

  group('deleteNote', () {
    test('the default deleter marks the card removed on success', () async {
      when(() => deleteNote.call('n1')).thenAnswer((_) async => const Right(unit));
      final cubit = build();

      final result = await cubit.deleteNote();

      expect(result, const Right(unit));
      expect(cubit.state.isRemoved, isTrue);
      await cubit.close();
    });

    test('a failure leaves the card in place', () async {
      when(() => deleteNote.call('n1'))
          .thenAnswer((_) async => const Left(Failure.errorFailure('boom')));
      final cubit = build();

      await cubit.deleteNote();

      expect(cubit.state.isRemoved, isFalse);
      await cubit.close();
    });

    test('a custom deleter is used instead of the default use case', () async {
      var customCalled = false;
      final cubit = build();

      final result = await cubit.deleteNote(() async {
        customCalled = true;
        return const Right(unit);
      });

      expect(result, const Right(unit));
      expect(customCalled, isTrue);
      expect(cubit.state.isRemoved, isTrue);
      verifyZeroInteractions(deleteNote);
      await cubit.close();
    });
  });

  test('a profile/follow emission after close is a no-op (subscriptions are '
      'cancelled)', () async {
    final profileController = StreamController<ProfileEntity?>.broadcast();
    when(() => watchProfile.call(any())).thenAnswer((_) => profileController.stream);
    final cubit = build();
    await cubit.close();

    // Should not throw ("emit after close") even though the controller is
    // still open — proves _profileSub was cancelled in close().
    profileController.add(aProfile());
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await profileController.close();
  });
}
