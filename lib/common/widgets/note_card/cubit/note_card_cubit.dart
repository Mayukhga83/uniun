import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/domain/entities/manas/manas_entity.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/domain/entities/profile/profile_entity.dart';
import 'package:uniun/core/utils/formatters.dart';
import 'package:uniun/domain/usecases/blocked_user_usecases.dart';
import 'package:uniun/domain/usecases/deleted_note_usecases.dart';
import 'package:uniun/domain/usecases/followed_note_usecases.dart';
import 'package:uniun/domain/usecases/manas_usecases.dart';
import 'package:uniun/domain/usecases/profile_usecases.dart';
import 'package:uniun/domain/usecases/saved_note_usecases.dart';
import 'package:uniun/domain/usecases/user_usecases.dart';
import 'package:uniun/domain/usecases/vector_usecases.dart';
import 'package:uniun/core/i18n/translation_language.dart';
import 'package:uniun/domain/usecases/llm_usecases.dart';

part 'note_card_state.dart';

/// Per-card state holder. Owns everything a [NoteCard] needs to render itself:
/// the author profile (reactive), the saved flag, and the follow flag. Follow
/// state is watched reactively from Isar so it stays consistent across every
/// card showing the same note and the drawer's followed-notes list.
@injectable
class NoteCardCubit extends Cubit<NoteCardState> {
  final WatchProfileUseCase _watchProfile;
  final RequestProfileFetchUseCase _requestProfileFetch;
  final IsSavedNoteUseCase _isSavedUseCase;
  final SaveNoteUseCase _saveNote;
  final UnsaveNoteUseCase _unsaveNote;
  final EmbedAndStoreNoteUseCase _embed;
  final WatchIsFollowedUseCase _watchIsFollowed;
  final FollowNoteUseCase _followNote;
  final UnfollowNoteUseCase _unfollowNote;
  final BlockUserUseCase _blockUser;
  final DeleteNoteUseCase _deleteNote;
  final GetActiveUserUseCase _getActiveUser;
  final GetManasIdsForNoteUseCase _getManasIdsForNote;
  final GetManasListUseCase _getManasList;
  final RemoveNoteFromManasUseCase _removeFromManas;
  final TranslateNoteUseCase _translateNote;
  final NoteEntity note;

  StreamSubscription<ProfileEntity?>? _profileSub;
  StreamSubscription<bool>? _followedSub;

  NoteCardCubit(
    this._watchProfile,
    this._requestProfileFetch,
    this._isSavedUseCase,
    this._saveNote,
    this._unsaveNote,
    this._embed,
    this._watchIsFollowed,
    this._followNote,
    this._unfollowNote,
    this._blockUser,
    this._deleteNote,
    this._getActiveUser,
    this._getManasIdsForNote,
    this._getManasList,
    this._removeFromManas,
    this._translateNote,
    @factoryParam this.note,
  ) : super(const NoteCardState()) {
    _init();
  }

  void _init() {
    _profileSub = _watchProfile.call(note.authorPubkey).listen((p) {
      if (!isClosed && p != null) emit(state.copyWith(profile: p));
    });
    // Ask the gateway to fetch the author's Kind 0 if we don't have it locally.
    _requestProfileFetch.call(note.authorPubkey);
    _followedSub = _watchIsFollowed.call(note.id).listen((followed) {
      if (!isClosed) emit(state.copyWith(isFollowed: followed));
    });
    _loadSaved();
    _loadIsOwnNote();
  }

  Future<void> _loadIsOwnNote() async {
    final r = await _getActiveUser.call();
    r.fold((_) {}, (user) {
      if (!isClosed && user.pubkeyHex == note.authorPubkey) {
        emit(state.copyWith(isOwnNote: true));
      }
    });
  }

  Future<void> _loadSaved() async {
    final r = await _isSavedUseCase.call(note.id);
    r.fold((_) {}, (v) {
      if (!isClosed) emit(state.copyWith(isSaved: v));
    });
  }

  /// Optimistic save toggle; reverts on failure. Embeds the saved note for
  /// RAG/graph on success (same flow as the feed + LargeNoteCard).
  Future<void> toggleSave() async {
    final nowSaved = !state.isSaved;
    emit(state.copyWith(isSaved: nowSaved));
    if (nowSaved) {
      final result = await _saveNote.call(note);
      result.fold(
        (_) {
          if (!isClosed) emit(state.copyWith(isSaved: false));
        },
        (saved) => _embed.call((saved.eventId, saved.content)),
      );
    } else {
      final result = await _unsaveNote.call(note.id);
      result.fold(
        (_) {
          if (!isClosed) emit(state.copyWith(isSaved: true));
        },
        (_) {},
      );
    }
  }

  /// Ensures the note is persisted before it's added to a Manas, then reports
  /// whether the caller may open the membership sheet.
  ///
  /// Manas membership only surfaces a note in the Brahma graph if it survives
  /// retention. Own notes are kept forever already, so they're added directly
  /// (no save). Someone else's note is saved first (if not already) — otherwise
  /// it would be cleaned up and the Manas would point at nothing. Embeds the
  /// freshly-saved note for RAG/graph, mirroring [toggleSave].
  Future<bool> ensureSavedForManas() async {
    if (state.isOwnNote || state.isSaved) return true;
    final result = await _saveNote.call(note);
    return result.fold(
      (_) => false,
      (saved) {
        if (!isClosed) emit(state.copyWith(isSaved: true));
        _embed.call((saved.eventId, saved.content));
        return true;
      },
    );
  }

  /// The Manases this note currently belongs to. Drives the unsave
  /// confirmation: unsaving evicts the note from every Manas it's in (a Manas
  /// can only surface a note that survives retention), so the user is warned
  /// and the memberships are cleared first. Empty when the note is in no Manas.
  Future<List<ManasEntity>> manasesContainingNote() async {
    final idsRes = await _getManasIdsForNote.call(note.id);
    final ids = idsRes.fold((_) => const <String>[], (l) => l).toSet();
    if (ids.isEmpty) return const [];
    final listRes = await _getManasList.call();
    final all = listRes.fold((_) => const <ManasEntity>[], (l) => l);
    return [for (final m in all) if (ids.contains(m.manasId)) m];
  }

  /// Removes this note from [manasIds] then unsaves it — the confirmed path when
  /// the bookmark is toggled off on a note that's part of one or more Manases.
  /// Optimistically flips `isSaved`; reverts only if the unsave write fails.
  Future<void> unsaveWithManasRemoval(List<String> manasIds) async {
    emit(state.copyWith(isSaved: false));
    for (final id in manasIds) {
      await _removeFromManas.call(ManasNoteLink(id, note.id));
    }
    final result = await _unsaveNote.call(note.id);
    result.fold(
      (_) {
        if (!isClosed) emit(state.copyWith(isSaved: true));
      },
      (_) {},
    );
  }

  /// Toggles follow state. The reactive `_watchIsFollowed` subscription drives
  /// the emitted [NoteCardState.isFollowed]; this only performs the write.
  Future<void> toggleFollow() async {
    if (state.isFollowed) {
      await _unfollowNote.call(note.id);
    } else {
      await _followNote.call(
        FollowNoteInput(
          eventId: note.id,
          contentPreview: formatContentPreview(note.content),
        ),
      );
    }
  }

  /// Blocks the note's author. Future inbound events from this pubkey are
  /// dropped by the gateway; existing notes already in Isar stay visible.
  Future<Either<Failure, Unit>> blockUser() =>
      _blockUser.call(note.authorPubkey);

  /// Deletes this note and, on success, collapses the card via
  /// [NoteCardState.isRemoved]. By default this suppresses the note in the
  /// unified `Note` store (tombstoned so the gateway never resyncs it). A
  /// surface backed by a different store (e.g. the Surrounding feed) passes
  /// [custom] to run its own deleter instead.
  Future<Either<Failure, Unit>> deleteNote([
    Future<Either<Failure, Unit>> Function()? custom,
  ]) async {
    final result = await (custom?.call() ?? _deleteNote.call(note.id));
    result.fold((_) {}, (_) {
      if (!isClosed) emit(state.copyWith(isRemoved: true));
    });
    return result;
  }

  /// Translates the note body into [target] and swaps it into the card.
  ///
  /// Idempotent per language: re-translating into the language already showing
  /// just un-hides it rather than burning a second inference call.
  Future<void> translate(TranslationLanguage target) async {
    if (state.isTranslating) return;
    if (state.translation != null && state.translationLanguage == target.code) {
      emit(state.copyWith(showOriginal: false));
      return;
    }
    emit(state.copyWith(isTranslating: true, clearTranslationError: true));
    final result = await _translateNote.call(
      TranslateNoteInput(content: note.content, target: target),
    );
    if (isClosed) return;
    result.fold(
      (f) => emit(state.copyWith(
        isTranslating: false,
        translationError: f.toMessage(),
      )),
      (text) {
        // null = the model reported the note is already in the target
        // language. Not an error, but the card has nothing to swap in.
        if (text == null) {
          emit(state.copyWith(
            isTranslating: false,
            translationError: kAlreadyInTargetLanguage,
          ));
          return;
        }
        emit(state.copyWith(
          isTranslating: false,
          translation: text,
          translationLanguage: target.code,
          showOriginal: false,
        ));
      },
    );
  }

  /// Flips between the translated body and the original. Free — the
  /// translation stays in state either way.
  void toggleOriginal() =>
      emit(state.copyWith(showOriginal: !state.showOriginal));

  void clearTranslationError() =>
      emit(state.copyWith(clearTranslationError: true));

  /// Marker for "already in the target language". The cubit has no
  /// BuildContext, so the widget layer swaps this for a localised string.
  static const String kAlreadyInTargetLanguage =
      '__already_in_target_language__';

  @override
  Future<void> close() {
    _profileSub?.cancel();
    _followedSub?.cancel();
    return super.close();
  }
}
