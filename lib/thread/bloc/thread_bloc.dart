import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:uniun/core/enum/note_type.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/domain/entities/profile/profile_entity.dart';
import 'package:uniun/domain/usecases/note_usecases.dart';
import 'package:uniun/domain/usecases/profile_usecases.dart';
import 'package:uniun/domain/usecases/user_usecases.dart';

part 'thread_event.dart';
part 'thread_state.dart';

// ── Isolate data classes (top-level — required by Isolate.run) ───────────────

class _BfsInput {
  const _BfsInput({
    required this.rootId,
    required this.allNotes,
    required this.parentOf,
    required this.replyCounts,
  });

  /// The root note's eventId — used as fallback parent for direct replies.
  final String rootId;

  /// Flat list of every reply note collected by the main isolate (all levels).
  final List<NoteEntity> allNotes;

  /// noteId → parentNoteId, built during BFS discovery on the main isolate.
  /// More reliable than replyToEventId because it comes directly from which
  /// _getReplies(parentId) call returned each child.
  final Map<String, String> parentOf;

  /// All reply counts collected by the main isolate.
  final Map<String, int> replyCounts;
}

class _BfsResult {
  const _BfsResult({required this.nestedReplies});

  /// parentNoteId → sorted list of its direct children.
  final Map<String, List<NoteEntity>> nestedReplies;
}

/// Runs entirely in the background isolate — pure Dart, zero Isar, zero Flutter.
/// Receives flat note data from the main isolate and builds the nested tree.
_BfsResult _buildBfsTree(_BfsInput input) {
  final parentToChildren = <String, List<NoteEntity>>{};

  for (final note in input.allNotes) {
    final parentId = input.parentOf[note.id] ?? input.rootId;
    parentToChildren.putIfAbsent(parentId, () => []).add(note);
  }

  // Sort each bucket oldest → newest so the UI renders chronologically.
  for (final children in parentToChildren.values) {
    children.sort((a, b) => a.created.compareTo(b.created));
  }

  return _BfsResult(nestedReplies: parentToChildren);
}

// ── BLoC ─────────────────────────────────────────────────────────────────────

@injectable
class ThreadBloc extends Bloc<ThreadEvent, ThreadState> {
  final GetNoteByIdUseCase _getNoteById;
  final GetRepliesUseCase _getReplies;
  final PublishNoteUseCase _publishNote;
  final GetProfileUseCase _getProfile;
  final GetReplyCountUseCase _getReplyCount;
  final GetActiveUserKeysUseCase _getActiveUserKeys;

  ThreadBloc(
    this._getNoteById,
    this._getReplies,
    this._publishNote,
    this._getProfile,
    this._getReplyCount,
    this._getActiveUserKeys,
  ) : super(const ThreadState()) {
    on<LoadThreadEvent>(_onLoad, transformer: droppable());
    on<UpdateReplyTextEvent>(_onUpdateText);
    on<SetReplyTargetEvent>(_onSetTarget);
    on<PostReplyEvent>(_onPost, transformer: droppable());
    on<SwitchTabEvent>(_onSwitchTab);
    on<ExpandReplyEvent>(_onExpand, transformer: sequential());
  }

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> _onLoad(
    LoadThreadEvent event,
    Emitter<ThreadState> emit,
  ) async {
    emit(state.copyWith(status: ThreadStatus.loading));

    // ── Phase 1: fetch root note ─────────────────────────────────────────────
    final rootResult = await _getNoteById.call(event.noteId);
    if (rootResult.isLeft()) {
      emit(state.copyWith(
        status: ThreadStatus.error,
        errorMessage: rootResult.fold((f) => f.toMessage(), (_) => ''),
      ));
      return;
    }
    final rootNote = rootResult.getOrElse(() => throw StateError(''));

    // ── Phase 2: fetch root profile + direct replies in parallel ─────────────
    final profiles = <String, ProfileEntity>{};
    final replyCounts = <String, int>{};

    final rootProfileFuture = _getProfile.call(rootNote.authorPubkey);
    final repliesResult = await _getReplies.call(event.noteId);
    final directReplies = repliesResult.fold((_) => <NoteEntity>[], (r) => r);

    final rootProfile = await rootProfileFuture;
    rootProfile.fold((_) {}, (p) => profiles[p.pubkey] = p);

    // Profiles + counts for direct replies — all parallel
    await Future.wait(directReplies.map((reply) async {
      final cr = await _getReplyCount.call(reply.id);
      cr.fold((_) {}, (c) => replyCounts[reply.id] = c);
      final pr = await _getProfile.call(reply.authorPubkey);
      pr.fold((_) {}, (p) => profiles[p.pubkey] = p);
    }));

    // ── SKELETON EMIT — screen renders immediately ────────────────────────────
    // isTreeBuilding = true signals widgets to show skeleton placeholders
    // when the user expands a reply before the background isolate is done.
    emit(state.copyWith(
      rootNote: rootNote,
      profiles: Map.from(profiles),
      replies: directReplies,
      replyCounts: Map.from(replyCounts),
      nestedReplies: const {},
      status: ThreadStatus.loaded,
      isTreeBuilding: true,
    ));

    // ── Phase 3: BFS discovery on main isolate (I/O only, no tree building) ──
    // We only collect flat data here. The tree structure is built in the
    // background isolate in Phase 4. This keeps the main thread free.
    final allNotes = <NoteEntity>[...directReplies];
    final parentOf = <String, String>{
      for (final r in directReplies) r.id: rootNote.id,
    };

    var queue = directReplies.map((r) => r.id).toList();
    final visited = <String>{rootNote.id, ...directReplies.map((r) => r.id)};
    int limit = 60;

    while (queue.isNotEmpty && limit > 0) {
      final batch = queue.take(limit).toList();
      limit -= batch.length;
      queue = [];

      // Fetch children for every node in this level — pure I/O, parallel
      final childResults = await Future.wait(
        batch.map((id) => _getReplies.call(id)),
      );

      for (int i = 0; i < batch.length; i++) {
        childResults[i].fold((_) {}, (children) {
          for (final child in children) {
            if (!visited.contains(child.id)) {
              visited.add(child.id);
              allNotes.add(child);
              parentOf[child.id] = batch[i]; // parent = node we queried
              queue.add(child.id);
            }
          }
        });
      }

      // Fetch profiles + counts for newly discovered nodes — parallel
      await Future.wait(queue.map((id) async {
        final node = allNotes.where((n) => n.id == id).firstOrNull;
        if (node == null) return;

        final cr = await _getReplyCount.call(id);
        cr.fold((_) {}, (c) => replyCounts[id] = c);

        if (!profiles.containsKey(node.authorPubkey)) {
          final pr = await _getProfile.call(node.authorPubkey);
          pr.fold((_) {}, (p) => profiles[p.pubkey] = p);
        }
      }));
    }

    if (emit.isDone) return;

    // ── Phase 4: background isolate builds the tree (CPU, off main thread) ───
    // compute() sends _BfsInput data to a fresh isolate and calls _buildBfsTree
    // with it. Unlike Isolate.run(() => ...), compute() takes a top-level
    // function reference + data separately — no closure, nothing captures
    // ThreadBloc or Isar, so SendPort.send() succeeds.
    final bfsResult = await compute(
      _buildBfsTree,
      _BfsInput(
        rootId: rootNote.id,
        allNotes: allNotes,
        parentOf: Map.from(parentOf),
        replyCounts: Map.from(replyCounts),
      ),
    );

    if (emit.isDone) return;

    // ── Phase 5: back on main isolate — update UI with the full tree ──────────
    emit(state.copyWith(
      profiles: Map.from(profiles),
      replyCounts: Map.from(replyCounts),
      nestedReplies: bfsResult.nestedReplies,
      isTreeBuilding: false,
    ));
  }

  // ── Lazy expand (on-demand, beyond BFS depth limit) ───────────────────────

  Future<void> _onExpand(
    ExpandReplyEvent event,
    Emitter<ThreadState> emit,
  ) async {
    // Background isolate is still building — it will cover this node.
    // Widget shows skeleton during this time. Ignore the event.
    if (state.isTreeBuilding) return;

    // Already loaded — nothing to do
    if (state.nestedReplies.containsKey(event.replyId)) return;

    final nr = await _getReplies.call(event.replyId);
    if (nr.isLeft()) return;

    final children = nr.getOrElse(() => []);
    if (children.isEmpty) return;

    final profiles = Map<String, ProfileEntity>.from(state.profiles);
    final replyCounts = Map<String, int>.from(state.replyCounts);

    await Future.wait(children.map((child) async {
      final cr = await _getReplyCount.call(child.id);
      cr.fold((_) {}, (c) => replyCounts[child.id] = c);

      if (!profiles.containsKey(child.authorPubkey)) {
        final pr = await _getProfile.call(child.authorPubkey);
        pr.fold((_) {}, (p) => profiles[p.pubkey] = p);
      }
    }));

    final updated = Map<String, List<NoteEntity>>.from(state.nestedReplies);
    updated[event.replyId] = children;

    if (!emit.isDone) {
      emit(state.copyWith(
        nestedReplies: updated,
        replyCounts: replyCounts,
        profiles: profiles,
      ));
    }
  }

  // ── Reply composer ────────────────────────────────────────────────────────

  void _onUpdateText(UpdateReplyTextEvent event, Emitter<ThreadState> emit) {
    emit(state.copyWith(replyText: event.text));
  }

  void _onSetTarget(SetReplyTargetEvent event, Emitter<ThreadState> emit) {
    emit(state.copyWith(
      replyingToId: event.replyToId,
      replyingToName: event.replyToName,
    ));
  }

  Future<void> _onPost(
    PostReplyEvent event,
    Emitter<ThreadState> emit,
  ) async {
    if (!state.canPost || state.rootNote == null) return;
    emit(state.copyWith(postStatus: ThreadPostStatus.posting));

    final keysResult = await _getActiveUserKeys.call();
    if (keysResult.isLeft()) {
      emit(state.copyWith(
        postStatus: ThreadPostStatus.error,
        errorMessage: keysResult.fold((f) => f.toMessage(), (_) => ''),
      ));
      return;
    }
    final keys = keysResult.getOrElse(() => throw StateError('unreachable'));

    final rootId = state.rootNote!.id;
    final replyToId = state.replyingToId ?? rootId;

    // Build NIP-10 tags
    final tags = <List<String>>[
      ['e', rootId, '', 'root'],
      if (replyToId != rootId) ['e', replyToId, '', 'reply'],
    ];

    // Sign with user's private key
    late final Event signed;
    try {
      signed = Event.from(
        kind: 1,
        tags: tags,
        content: state.replyText.trim(),
        privkey: keys.privkeyHex,
      );
    } catch (e) {
      emit(state.copyWith(
        postStatus: ThreadPostStatus.error,
        errorMessage: 'Signing failed: $e',
      ));
      return;
    }

    final note = NoteEntity(
      id: signed.id,
      sig: signed.sig,
      authorPubkey: keys.pubkeyHex,
      content: signed.content,
      type: NoteType.text,
      eTagRefs: [rootId, if (replyToId != rootId) replyToId],
      pTagRefs: const [],
      tTags: const [],
      created: DateTime.fromMillisecondsSinceEpoch(signed.createdAt * 1000),
      isSeen: true,
      rootEventId: rootId,
      replyToEventId: replyToId,
    );

    final result = await _publishNote.call(note);
    result.fold(
      (f) => emit(state.copyWith(
        postStatus: ThreadPostStatus.error,
        errorMessage: f.toMessage(),
      )),
      (published) {
        final updatedState = state.copyWith(
          replyText: '',
          replyingToId: null,
          replyingToName: null,
          postStatus: ThreadPostStatus.posted,
        );
        if (replyToId == rootId) {
          emit(updatedState.copyWith(
            replies: [...state.replies, published],
          ));
        } else {
          final updatedNested =
              Map<String, List<NoteEntity>>.from(state.nestedReplies);
          updatedNested[replyToId] = [
            ...(updatedNested[replyToId] ?? []),
            published,
          ];
          final updatedCounts = Map<String, int>.from(state.replyCounts);
          updatedCounts[replyToId] = (updatedCounts[replyToId] ?? 0) + 1;
          emit(updatedState.copyWith(
            nestedReplies: updatedNested,
            replyCounts: updatedCounts,
          ));
        }
      },
    );
  }

  void _onSwitchTab(SwitchTabEvent event, Emitter<ThreadState> emit) {
    emit(state.copyWith(activeTab: event.index));
  }
}
