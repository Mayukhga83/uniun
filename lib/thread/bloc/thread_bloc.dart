import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:uniun/core/enum/note_type.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/domain/entities/profile/profile_entity.dart';
import 'package:uniun/domain/usecases/note_usecases.dart';
import 'package:uniun/domain/usecases/profile_usecases.dart';
import 'package:uniun/domain/usecases/user_usecases.dart';
import 'package:uniun/domain/usecases/vector_usecases.dart';

part 'thread_event.dart';
part 'thread_state.dart';

// ── BLoC ─────────────────────────────────────────────────────────────────────

@injectable
class ThreadBloc extends Bloc<ThreadEvent, ThreadState> {
  final GetNoteByIdUseCase _getNoteById;
  final GetRepliesUseCase _getReplies;
  final PublishNoteUseCase _publishNote;
  final GetProfileUseCase _getProfile;
  final GetReplyCountUseCase _getReplyCount;
  final GetActiveUserKeysUseCase _getActiveUserKeys;
  final EmbedAndStoreNoteUseCase _embedAndStore;

  ThreadBloc(
    this._getNoteById,
    this._getReplies,
    this._publishNote,
    this._getProfile,
    this._getReplyCount,
    this._getActiveUserKeys,
    this._embedAndStore,
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

    // ── Phase 2: fetch root profile + direct replies + parent chain in parallel
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

    // ── Walk up the parent chain (max 2 levels) ───────────────────────────────
    // Needed to display context above the focused note (X/Twitter style).
    final parentChain = <NoteEntity>[];
    var parentId = rootNote.replyToEventId;
    var depth = 0;
    while (parentId != null && depth < 2) {
      final pr = await _getNoteById.call(parentId);
      if (pr.isLeft()) break;
      final parent = pr.getOrElse(() => throw StateError('unreachable'));
      parentChain.insert(0, parent); // oldest first
      if (!profiles.containsKey(parent.authorPubkey)) {
        final pfr = await _getProfile.call(parent.authorPubkey);
        pfr.fold((_) {}, (p) => profiles[p.pubkey] = p);
      }
      parentId = parent.replyToEventId;
      depth++;
    }

    emit(state.copyWith(
      rootNote: rootNote,
      parentChain: parentChain,
      profiles: Map.from(profiles),
      replies: directReplies,
      replyCounts: Map.from(replyCounts),
      nestedReplies: const {},
      status: ThreadStatus.loaded,
    ));
  }

  // ── Lazy expand (on-demand, beyond BFS depth limit) ───────────────────────

  Future<void> _onExpand(
    ExpandReplyEvent event,
    Emitter<ThreadState> emit,
  ) async {
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
    emit(state.copyWith(
      replyText: event.text,
      postStatus: ThreadPostStatus.idle,
    ));
  }

  void _onSetTarget(SetReplyTargetEvent event, Emitter<ThreadState> emit) {
    emit(state.copyWith(
      replyingToId: event.replyToId,
      replyingToName: event.replyToName,
      postStatus: ThreadPostStatus.idle,
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
        // Fire-and-forget: embed own authored reply for RAG.
        unawaited(_embedAndStore.call((published.id, published.content)));
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
