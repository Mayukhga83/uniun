import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/domain/entities/surrounding/surrounding_note_entity.dart';
import 'package:uniun/domain/repositories/surrounding_note_repository.dart';
import 'package:uniun/features/mesh/mesh_constants.dart';

import 'surrounding_state.dart';

/// Notes loaded per older-page pagination step.
const int _kSurroundingPageSize = kSurroundingPageSize;

/// Drives the "Surrounding" feed: a chat-style list ordered by arrival time
/// (`receivedAt`), newest at the bottom. Opens on the newest page; scrolling up
/// loads older notes; notes arriving over the mesh are appended at the bottom.
/// A read watermark, advanced as notes are scrolled past, tracks what has been
/// viewed.
class SurroundingCubit extends Cubit<SurroundingState> {
  SurroundingCubit({SurroundingNoteRepository? repo})
      : _repo = repo ?? getIt<SurroundingNoteRepository>(),
        super(const SurroundingState()) {
    // Live updates: surrounding notes arrive over the mesh + evict daily.
    _sub = _repo.watch().listen((_) => _onCacheChanged());
  }

  final SurroundingNoteRepository _repo;
  StreamSubscription<void>? _sub;

  /// Highest receivedAt already pushed to the read watermark — avoids a
  /// SharedPreferences write on every scroll frame.
  DateTime _persistedReadMark = DateTime.fromMillisecondsSinceEpoch(0);

  /// Loads the newest page; the feed opens at the bottom on the newest note.
  Future<void> load() async {
    // Serialize against a concurrent in-flight load (e.g. a mesh arrival firing
    // _onCacheChanged before the first load() returns).
    if (state.status == SurroundingStatus.loading) return;
    if (state.status == SurroundingStatus.initial) {
      emit(state.copyWith(status: SurroundingStatus.loading));
    }

    final page = (await _repo.getBefore(
      before: null,
      limit: _kSurroundingPageSize,
    ))
        .getOrElse(() => <SurroundingNoteEntity>[]); // oldest→newest

    if (isClosed) return;
    emit(state.copyWith(
      status: SurroundingStatus.loaded,
      notes: page,
      hasMoreOlder: page.length == _kSurroundingPageSize,
      isLoadingOlder: false,
      isLoadingNewer: false,
    ));
  }

  /// Scrolling up: prepend the next older page.
  Future<void> loadOlder() async {
    if (state.isLoadingOlder || !state.hasMoreOlder || state.notes.isEmpty) {
      return;
    }
    emit(state.copyWith(isLoadingOlder: true));

    final older = (await _repo.getBefore(
      before: state.notes.first.receivedAt,
      limit: _kSurroundingPageSize,
    ))
        .getOrElse(() => <SurroundingNoteEntity>[]);
    if (isClosed) return;
    final existing = state.notes.map((e) => e.note.id).toSet();
    final fresh = older.where((e) => !existing.contains(e.note.id)).toList();
    if (fresh.isEmpty) {
      emit(state.copyWith(isLoadingOlder: false, hasMoreOlder: false));
      return;
    }
    emit(state.copyWith(
      notes: [...fresh, ...state.notes],
      hasMoreOlder: older.length == _kSurroundingPageSize,
      isLoadingOlder: false,
    ));
  }

  /// A mesh arrival: append any notes newer than the last loaded one at the
  /// bottom (inclusive + dedupe so same-millisecond ties are not skipped).
  Future<void> loadNewer() async {
    if (state.isLoadingNewer || state.notes.isEmpty) return;
    emit(state.copyWith(isLoadingNewer: true));

    final newer = (await _repo.getAfter(
      after: state.notes.last.receivedAt,
      inclusive: true,
      limit: _kSurroundingPageSize,
    ))
        .getOrElse(() => <SurroundingNoteEntity>[]);
    if (isClosed) return;
    final existing = state.notes.map((e) => e.note.id).toSet();
    final fresh = newer.where((e) => !existing.contains(e.note.id)).toList();
    if (fresh.isEmpty) {
      emit(state.copyWith(isLoadingNewer: false));
      return;
    }
    emit(state.copyWith(
      notes: [...state.notes, ...fresh],
      isLoadingNewer: false,
    ));
  }

  /// A note scrolled out of view after being seen → advance the read watermark.
  /// Skipped when it would not move the watermark forward.
  void markRead(DateTime receivedAt) {
    if (!receivedAt.isAfter(_persistedReadMark)) return;
    _persistedReadMark = receivedAt;
    // Fire-and-forget: the read mark is best-effort; a failed persist self-heals
    // on the next scroll.
    unawaited(_repo.markReadUpTo(receivedAt));
  }

  /// Mesh arrival or eviction. Empty/not-yet-loaded → full load; otherwise
  /// append newer notes at the bottom without disturbing the scroll position.
  Future<void> _onCacheChanged() async {
    if (state.status != SurroundingStatus.loaded || state.notes.isEmpty) {
      await load();
    } else {
      await loadNewer();
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
