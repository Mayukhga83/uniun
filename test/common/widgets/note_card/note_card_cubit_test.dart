import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/common/widgets/note_card/cubit/note_card_cubit.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/domain/entities/manas/manas_entity.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/domain/entities/profile/profile_entity.dart';
import 'package:uniun/domain/entities/saved_note/saved_note_entity.dart';
import 'package:uniun/domain/entities/user_key/user_key_entity.dart';
import 'package:uniun/domain/usecases/llm_usecases.dart';
import 'package:uniun/domain/usecases/blocked_user_usecases.dart';
import 'package:uniun/domain/usecases/deleted_note_usecases.dart';
import 'package:uniun/domain/usecases/followed_note_usecases.dart';
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

class _MGetManasIds extends Mock implements GetManasIdsForNoteUseCase {}

class _MGetManasList extends Mock implements GetManasListUseCase {}

class _MRemoveFromManas extends Mock implements RemoveNoteFromManasUseCase {}

class _MTranslateNote extends Mock implements TranslateNoteUseCase {}

NoteEntity _note({String id = 'n1', String author = 'pub-other'}) =>
    aNote(id: id, authorPubkey: author);

SavedNoteEntity _saved(String id) =>
    aSavedNote(eventId: id, authorPubkey: 'pub-other');

UserKeyEntity _user(String pub) => aUserKey(pubkeyHex: pub);

ManasEntity _manas(String id) => aManas(manasId: id, name: id);

void main() {
  late _MWatchProfile watchProfile;
  late _MRequestProfile requestProfile;
  late _MIsSaved isSaved;
  late _MSave save;
  late _MUnsave unsave;
  late _MEmbed embed;
  late _MWatchFollowed watchFollowed;
  late _MFollow follow;
  late _MUnfollow unfollow;
  late _MBlock block;
  late _MDelete deleteNote;
  late _MGetActive getActive;
  late _MGetManasIds getManasIds;
  late _MGetManasList getManasList;
  late _MRemoveFromManas removeFromManas;
  late _MTranslateNote translateNote;

  setUpAll(() {
    registerFallbackValue(_note());
    registerFallbackValue(
      const FollowNoteInput(eventId: 'x', contentPreview: 'p'),
    );
    registerFallbackValue(const ManasNoteLink('m', 'n'));
    registerFallbackValue(('id', 'content'));
  });

  setUp(() {
    watchProfile = _MWatchProfile();
    requestProfile = _MRequestProfile();
    isSaved = _MIsSaved();
    save = _MSave();
    unsave = _MUnsave();
    embed = _MEmbed();
    watchFollowed = _MWatchFollowed();
    follow = _MFollow();
    unfollow = _MUnfollow();
    block = _MBlock();
    deleteNote = _MDelete();
    getActive = _MGetActive();
    getManasIds = _MGetManasIds();
    getManasList = _MGetManasList();
    removeFromManas = _MRemoveFromManas();
    translateNote = _MTranslateNote();

    // Stubs for _init() so unrelated tests don't crash.
    when(() => watchProfile.call(any()))
        .thenAnswer((_) => const Stream<ProfileEntity?>.empty());
    when(() => requestProfile.call(any()))
        .thenAnswer((_) async => const Right(unit));
    when(() => watchFollowed.call(any()))
        .thenAnswer((_) => const Stream<bool>.empty());
    when(() => isSaved.call(any())).thenAnswer((_) async => const Right(false));
    when(() => getActive.call()).thenAnswer(
      (_) async => const Left(Failure.errorFailure('no user')),
    );
    when(() => embed.call(any())).thenAnswer((_) async => const Right(unit));
  });

  NoteCardCubit build({NoteEntity? note}) => NoteCardCubit(
        watchProfile,
        requestProfile,
        isSaved,
        save,
        unsave,
        embed,
        watchFollowed,
        follow,
        unfollow,
        block,
        deleteNote,
        getActive,
        getManasIds,
        getManasList,
        removeFromManas,
        translateNote,
        note ?? _note(),
      );

  group('init', () {
    test('subscribes to profile + followed streams + asks gateway to fetch', () async {
      final c = build();
      await Future<void>.delayed(Duration.zero);
      verify(() => watchProfile.call('pub-other')).called(1);
      verify(() => watchFollowed.call('n1')).called(1);
      verify(() => requestProfile.call('pub-other')).called(1);
      await c.close();
    });

    test('emits profile when stream delivers a value', () async {
      final ctrl = StreamController<ProfileEntity?>();
      when(() => watchProfile.call('pub-other'))
          .thenAnswer((_) => ctrl.stream);
      final c = build();
      final profile = ProfileEntity(
        pubkey: 'pub-other',
        name: 'Alice',
        updatedAt: DateTime(2026, 1, 1),
      );
      ctrl.add(profile);
      await Future<void>.delayed(Duration.zero);
      expect(c.state.profile?.name, 'Alice');
      await ctrl.close();
      await c.close();
    });

    test('null profile from stream is ignored (no emission)', () async {
      final ctrl = StreamController<ProfileEntity?>();
      when(() => watchProfile.call(any())).thenAnswer((_) => ctrl.stream);
      final c = build();
      ctrl.add(null);
      await Future<void>.delayed(Duration.zero);
      expect(c.state.profile, isNull);
      await ctrl.close();
      await c.close();
    });

    test('flips isOwnNote when active user pubkey matches', () async {
      when(() => getActive.call())
          .thenAnswer((_) async => Right(_user('pub-other')));
      final c = build();
      await Future<void>.delayed(Duration.zero);
      expect(c.state.isOwnNote, isTrue);
      await c.close();
    });

    test('isOwnNote stays false when pubkey differs', () async {
      when(() => getActive.call())
          .thenAnswer((_) async => Right(_user('different')));
      final c = build();
      await Future<void>.delayed(Duration.zero);
      expect(c.state.isOwnNote, isFalse);
      await c.close();
    });

    test('isSaved seeded from IsSavedNoteUseCase', () async {
      when(() => isSaved.call('n1')).thenAnswer((_) async => const Right(true));
      final c = build();
      await Future<void>.delayed(Duration.zero);
      expect(c.state.isSaved, isTrue);
      await c.close();
    });

    test('isFollowed updates as the watch stream emits', () async {
      final ctrl = StreamController<bool>();
      when(() => watchFollowed.call(any())).thenAnswer((_) => ctrl.stream);
      final c = build();
      ctrl.add(true);
      await Future<void>.delayed(Duration.zero);
      expect(c.state.isFollowed, isTrue);
      ctrl.add(false);
      await Future<void>.delayed(Duration.zero);
      expect(c.state.isFollowed, isFalse);
      await ctrl.close();
      await c.close();
    });
  });

  group('toggleSave', () {
    blocTest<NoteCardCubit, NoteCardState>(
      'save success: optimistic flip stays, embed is called',
      build: () {
        when(() => save.call(any()))
            .thenAnswer((_) async => Right(_saved('n1')));
        return build();
      },
      act: (c) async {
        await Future<void>.delayed(Duration.zero);
        await c.toggleSave();
      },
      verify: (c) {
        expect(c.state.isSaved, isTrue);
        verify(() => save.call(any())).called(1);
        verify(() => embed.call(any())).called(1);
      },
    );

    blocTest<NoteCardCubit, NoteCardState>(
      'save failure: optimistic flip reverts to false',
      build: () {
        when(() => save.call(any())).thenAnswer(
          (_) async => const Left(Failure.errorFailure('write failed')),
        );
        return build();
      },
      act: (c) async {
        await Future<void>.delayed(Duration.zero);
        await c.toggleSave();
      },
      verify: (c) {
        expect(c.state.isSaved, isFalse);
        verifyNever(() => embed.call(any()));
      },
    );

    blocTest<NoteCardCubit, NoteCardState>(
      'unsave success: state becomes false, no embed',
      build: () {
        when(() => isSaved.call(any()))
            .thenAnswer((_) async => const Right(true));
        when(() => unsave.call(any()))
            .thenAnswer((_) async => const Right(unit));
        return build();
      },
      act: (c) async {
        await Future<void>.delayed(Duration.zero);
        await c.toggleSave();
      },
      verify: (c) {
        expect(c.state.isSaved, isFalse);
        verifyNever(() => embed.call(any()));
      },
    );

    blocTest<NoteCardCubit, NoteCardState>(
      'unsave failure: optimistic flip reverts to true',
      build: () {
        when(() => isSaved.call(any()))
            .thenAnswer((_) async => const Right(true));
        when(() => unsave.call(any())).thenAnswer(
          (_) async => const Left(Failure.errorFailure('write failed')),
        );
        return build();
      },
      act: (c) async {
        await Future<void>.delayed(Duration.zero);
        await c.toggleSave();
      },
      verify: (c) {
        expect(c.state.isSaved, isTrue);
      },
    );
  });

  group('ensureSavedForManas', () {
    test('own note: no save, returns true', () async {
      when(() => getActive.call())
          .thenAnswer((_) async => Right(_user('pub-other')));
      final c = build();
      await Future<void>.delayed(Duration.zero);
      final ok = await c.ensureSavedForManas();
      expect(ok, isTrue);
      verifyNever(() => save.call(any()));
      await c.close();
    });

    test('already saved: no save, returns true', () async {
      when(() => isSaved.call(any()))
          .thenAnswer((_) async => const Right(true));
      final c = build();
      await Future<void>.delayed(Duration.zero);
      final ok = await c.ensureSavedForManas();
      expect(ok, isTrue);
      verifyNever(() => save.call(any()));
      await c.close();
    });

    test('not saved: saves + embeds + returns true', () async {
      when(() => save.call(any()))
          .thenAnswer((_) async => Right(_saved('n1')));
      final c = build();
      await Future<void>.delayed(Duration.zero);
      final ok = await c.ensureSavedForManas();
      expect(ok, isTrue);
      expect(c.state.isSaved, isTrue);
      verify(() => save.call(any())).called(1);
      verify(() => embed.call(any())).called(1);
      await c.close();
    });

    test('save failure: returns false, state unchanged', () async {
      when(() => save.call(any()))
          .thenAnswer((_) async => const Left(Failure.errorFailure('boom')));
      final c = build();
      await Future<void>.delayed(Duration.zero);
      final ok = await c.ensureSavedForManas();
      expect(ok, isFalse);
      expect(c.state.isSaved, isFalse);
      await c.close();
    });
  });

  group('manasesContainingNote', () {
    test('empty ids: returns empty without listing manases', () async {
      when(() => getManasIds.call(any()))
          .thenAnswer((_) async => const Right(<String>[]));
      final c = build();
      await Future<void>.delayed(Duration.zero);
      final m = await c.manasesContainingNote();
      expect(m, isEmpty);
      verifyNever(() => getManasList.call());
      await c.close();
    });

    test('filters list to only the ids the note belongs to', () async {
      when(() => getManasIds.call(any()))
          .thenAnswer((_) async => const Right(['m1', 'm3']));
      when(() => getManasList.call()).thenAnswer(
        (_) async => Right([_manas('m1'), _manas('m2'), _manas('m3')]),
      );
      final c = build();
      await Future<void>.delayed(Duration.zero);
      final m = await c.manasesContainingNote();
      expect(m.map((x) => x.manasId).toList(), ['m1', 'm3']);
      await c.close();
    });
  });

  group('unsaveWithManasRemoval', () {
    blocTest<NoteCardCubit, NoteCardState>(
      'removes from every passed manas then unsaves; flips isSaved=false',
      build: () {
        when(() => removeFromManas.call(any()))
            .thenAnswer((_) async => const Right(unit));
        when(() => unsave.call(any()))
            .thenAnswer((_) async => const Right(unit));
        when(() => isSaved.call(any()))
            .thenAnswer((_) async => const Right(true));
        return build();
      },
      act: (c) async {
        await Future<void>.delayed(Duration.zero);
        await c.unsaveWithManasRemoval(['m1', 'm2']);
      },
      verify: (c) {
        expect(c.state.isSaved, isFalse);
        verify(() => removeFromManas.call(any())).called(2);
        verify(() => unsave.call('n1')).called(1);
      },
    );

    blocTest<NoteCardCubit, NoteCardState>(
      'unsave failure reverts isSaved to true',
      build: () {
        when(() => removeFromManas.call(any()))
            .thenAnswer((_) async => const Right(unit));
        when(() => unsave.call(any())).thenAnswer(
          (_) async => const Left(Failure.errorFailure('boom')),
        );
        when(() => isSaved.call(any()))
            .thenAnswer((_) async => const Right(true));
        return build();
      },
      act: (c) async {
        await Future<void>.delayed(Duration.zero);
        await c.unsaveWithManasRemoval(['m1']);
      },
      verify: (c) {
        expect(c.state.isSaved, isTrue);
      },
    );
  });

  group('toggleFollow', () {
    test('not followed: dispatches FollowNoteUseCase with preview', () async {
      when(() => follow.call(any()))
          .thenAnswer((_) async => const Right(unit));
      final c = build();
      await Future<void>.delayed(Duration.zero);
      await c.toggleFollow();
      verify(() => follow.call(any())).called(1);
      verifyNever(() => unfollow.call(any()));
      await c.close();
    });

    test('already followed: dispatches UnfollowNoteUseCase', () async {
      final ctrl = StreamController<bool>();
      when(() => watchFollowed.call(any())).thenAnswer((_) => ctrl.stream);
      when(() => unfollow.call(any()))
          .thenAnswer((_) async => const Right(unit));
      final c = build();
      ctrl.add(true);
      await Future<void>.delayed(Duration.zero);
      await c.toggleFollow();
      verify(() => unfollow.call('n1')).called(1);
      verifyNever(() => follow.call(any()));
      await ctrl.close();
      await c.close();
    });
  });

  group('blockUser + deleteNote', () {
    test('blockUser forwards to use case with author pubkey', () async {
      when(() => block.call(any()))
          .thenAnswer((_) async => const Right(unit));
      final c = build();
      await Future<void>.delayed(Duration.zero);
      final r = await c.blockUser();
      expect(r.isRight(), isTrue);
      verify(() => block.call('pub-other')).called(1);
      await c.close();
    });

    blocTest<NoteCardCubit, NoteCardState>(
      'deleteNote success → isRemoved flips true',
      build: () {
        when(() => deleteNote.call(any()))
            .thenAnswer((_) async => const Right(unit));
        return build();
      },
      act: (c) async {
        await Future<void>.delayed(Duration.zero);
        await c.deleteNote();
      },
      verify: (c) {
        expect(c.state.isRemoved, isTrue);
      },
    );

    blocTest<NoteCardCubit, NoteCardState>(
      'deleteNote failure → isRemoved stays false',
      build: () {
        when(() => deleteNote.call(any()))
            .thenAnswer((_) async => const Left(Failure.errorFailure('no')));
        return build();
      },
      act: (c) async {
        await Future<void>.delayed(Duration.zero);
        final r = await c.deleteNote();
        expect(r.isLeft(), isTrue);
      },
      verify: (c) {
        expect(c.state.isRemoved, isFalse);
      },
    );
  });

  group('close', () {
    test('cancels both subscriptions on close', () async {
      final pCtrl = StreamController<ProfileEntity?>();
      final fCtrl = StreamController<bool>();
      when(() => watchProfile.call(any())).thenAnswer((_) => pCtrl.stream);
      when(() => watchFollowed.call(any())).thenAnswer((_) => fCtrl.stream);
      final c = build();
      await Future<void>.delayed(Duration.zero);
      await c.close();
      expect(pCtrl.hasListener, isFalse);
      expect(fCtrl.hasListener, isFalse);
      await pCtrl.close();
      await fCtrl.close();
    });
  });
}
