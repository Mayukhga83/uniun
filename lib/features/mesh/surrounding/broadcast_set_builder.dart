import 'dart:convert';

import 'package:isar_community/isar.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:uniun/core/notes/note_kinds.dart';
import 'package:uniun/data/models/notes/note_model.dart';
import 'package:uniun/data/models/profile_model.dart';
import 'package:uniun/data/models/saved_note_model.dart';

import '../mesh_constants.dart';
import 'broadcast_event.dart';

/// Builds the set of public events this device offers to nearby strangers: our
/// own feed notes (kind 1) plus bookmarked public notes, each rebuilt as a signed
/// Nostr event for the receiver to verify, PLUS a freshly-signed copy of our own
/// kind-0 profile so the stranger can render our name/avatar offline.
/// Channel/DM/private content is never broadcast. The note sets are capped
/// newest-first — see [kMaxOwnBroadcastNotes] / [kMaxSavedBroadcastNotes].
///
/// **Stateful / incremental / streaming.** One instance lives per connected peer
/// (created in `MeshService._startSurroundingExchange`) for the session. Each
/// [deltaEvents] yields only the rows added since the previous call: the first call
/// (cursors at 0) yields the full capped set, later calls yield just the new own
/// notes / fresh bookmarks. Own notes and bookmarks always insert at a higher Isar
/// autoincrement
/// id, so an id-range query is an exact, cheap delta — no rescanning the whole
/// history (or re-signing the profile) on every local note write. The exchange's
/// per-peer `_sentIds` stays the wire-level dedup for the own/saved overlap.
class BroadcastSetBuilder {
  BroadcastSetBuilder(this._isar, this._ownPubkey, this._ownPrivkey);

  final Isar _isar;
  final String _ownPubkey;
  final String _ownPrivkey;

  // Highest Isar id already emitted from each collection (0 = nothing yet).
  int _noteCursor = 0;
  int _savedCursor = 0;
  // updatedAt of the profile last emitted; re-sign + re-send only when it changes
  // (signing is a Schnorr op we don't want to repeat on every unrelated write).
  DateTime? _profileSyncedAt;

  /// Yields the events to push to this peer one at a time, newest-first, so the
  /// exchange can pace them within the receiver's accept rate. Profile first (only
  /// if it changed since last sent), then our newest own notes, then our newest
  /// bookmarks. Incremental: each call yields only the rows added since the
  /// previous call (first call = full capped set, later calls = just the delta).
  Stream<Map<String, dynamic>> deltaEvents() async* {
    // Our own profile (kind 0), re-signed so it verifies on the receiver — only
    // when it actually changed since we last sent it.
    final profileEvent = await _ownProfileEventIfChanged();
    if (profileEvent != null) yield profileEvent;

    // Newest-first + cap: a fresh peer (cursor 0) gets only our latest notes, not
    // the whole history. Newest `created` == highest id for own notes, so the
    // cursor still advances to the global max and later deltas stay exact.
    final own = await _isar.noteModels
        .filter()
        .authorPubkeyEqualTo(_ownPubkey)
        .kindEqualTo(kNoteKind)
        .idGreaterThan(_noteCursor)
        .sortByCreatedDesc()
        .limit(kMaxOwnBroadcastNotes)
        .findAll();
    for (final n in own) {
      if (n.id > _noteCursor) _noteCursor = n.id;
      yield buildBroadcastEvent(
        eventId: n.eventId,
        sig: n.sig,
        authorPubkey: n.authorPubkey,
        content: n.content,
        created: n.created,
        kind: kNoteKind,
        eTagRefs: n.eTagRefs,
        pTagRefs: n.pTagRefs,
        tTags: n.tTags,
        rootEventId: n.rootEventId,
        replyToEventId: n.replyToEventId,
        quoteEventId: n.quoteEventId,
      );
    }

    // Saved notes that are plain feed notes (not saved channel/group messages).
    // Same cap, ordered by most-recently-bookmarked (savedAt == id order), so the
    // newest N bookmarks go out and the cursor advances to the global max.
    final saved = await _isar.savedNoteModels
        .filter()
        .sourceChannelIdIsNull()
        .sourcePrivateGroupIdIsNull()
        .idGreaterThan(_savedCursor)
        .sortBySavedAtDesc()
        .limit(kMaxSavedBroadcastNotes)
        .findAll();
    for (final s in saved) {
      if (s.id > _savedCursor) _savedCursor = s.id;
      yield buildBroadcastEvent(
        eventId: s.eventId,
        sig: s.sig,
        authorPubkey: s.authorPubkey,
        content: s.content,
        created: s.created,
        kind: kNoteKind,
        eTagRefs: s.eTagRefs,
        pTagRefs: s.pTagRefs,
        tTags: s.tTags,
        rootEventId: s.rootEventId,
        replyToEventId: s.replyToEventId,
        quoteEventId: s.quoteEventId,
      );
    }
  }

  Future<Map<String, dynamic>?> _ownProfileEventIfChanged() async {
    final profile = await _isar.profileModels
        .where()
        .pubkeyEqualTo(_ownPubkey)
        .findFirst();
    if (profile == null) return null;
    // Already sent this exact version to this peer → skip (don't re-sign/re-send).
    if (_profileSyncedAt != null &&
        !profile.updatedAt.isAfter(_profileSyncedAt!)) {
      return null;
    }
    final meta = <String, dynamic>{
      if (profile.username != null) 'name': profile.username,
      if (profile.name != null) 'display_name': profile.name,
      if (profile.about != null) 'about': profile.about,
      if (profile.avatarUrl != null) 'picture': profile.avatarUrl,
      if (profile.nip05 != null) 'nip05': profile.nip05,
    };
    if (meta.isEmpty) return null;
    // Stable createdAt = the profile's real updatedAt, so the receiver's
    // last-write-wins ingest is idempotent across repeated broadcasts (signing
    // with `now` each time would make every copy "newer" and churn the DB).
    // Event.from treats 0 as "use now" — only an epoch updatedAt hits that.
    final event = Event.from(
      kind: 0,
      content: jsonEncode(meta),
      tags: const [],
      createdAt: profile.updatedAt.millisecondsSinceEpoch ~/ 1000,
      privkey: _ownPrivkey,
    );
    _profileSyncedAt = profile.updatedAt;
    return event.toJson();
  }
}
