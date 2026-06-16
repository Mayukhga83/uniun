import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:uniun/core/notes/note_kinds.dart';
import 'package:uniun/data/models/blocked_user_model.dart';
import 'package:uniun/data/models/deleted_note_model.dart';
import 'package:uniun/data/models/notes/note_model.dart';
import 'package:uniun/data/models/profile_model.dart';
import 'package:uniun/data/models/surrounding_note_model.dart';

import '../mesh_constants.dart';

/// Verifies and stores a broadcast Kind-1 note from a nearby stranger into the
/// ephemeral [SurroundingNoteModel] cache. Drops anything that fails the Schnorr
/// signature check (forgery/impersonation), isn't a public feed note, is from a
/// blocked author, is locally tombstoned, or is our own note.
class SurroundingInbound {
  SurroundingInbound(this._isar, this._ownPubkey);

  final Isar _isar;
  final String _ownPubkey;

  /// Max surrounding notes accepted from this peer per rolling second — a flood
  /// guard so a peer can't dump its whole DB on us. One instance lives per peer,
  /// so this is a per-peer cap. Well-behaved senders pace their broadcast to stay
  /// under this rate (see `SurroundingExchange._sendInterval`); anything faster is
  /// treated as abuse and dropped.
  static const int _maxNotesPerSecond = kSurroundingMaxNotesPerSecond;

  /// Timestamps of note acceptances within the trailing second (sliding window).
  final List<DateTime> _recentNoteAccepts = [];

  /// Sliding-window rate limiter: records and allows a slot while under
  /// [_maxNotesPerSecond] notes in the last second, returns false once saturated.
  bool _acceptWithinRateLimit() {
    final now = DateTime.now();
    _recentNoteAccepts.removeWhere(
      (t) => now.difference(t) >= const Duration(seconds: 1),
    );
    if (_recentNoteAccepts.length >= _maxNotesPerSecond) return false;
    _recentNoteAccepts.add(now);
    return true;
  }

  /// Ingests one broadcast event. Returns true when the event is a **valid public
  /// event worth relaying** (passed kind + rate-limit + Schnorr checks) — the signal
  /// the multi-hop router uses to decide whether to forward it. Note that a true
  /// result is independent of local storage: a valid note from a blocked author (or
  /// an older profile) still relays — blocking/tombstoning is a local-view choice —
  /// it just isn't stored here.
  Future<bool> ingest(Map<String, dynamic> json) async {
    final Event event;
    try {
      event = Event.fromJson(json, verify: false);
    } catch (_) {
      debugPrint('MESH/SURR: drop (malformed)');
      return false;
    }
    if (event.pubkey == _ownPubkey) return false; // our own event — never ingested

    // Profiles (kind 0) carry author name/avatar; everything else must be a
    // public feed note. Reject other kinds before any expensive work.
    if (event.kind != 0 && event.kind != kNoteKind) return false;

    // Flood guard: throttle a peer dumping notes on us to [_maxNotesPerSecond]
    // notes/sec. Checked before the Schnorr verification so a flood can't burn
    // CPU verifying signatures for notes we'll drop anyway. Profiles are
    // idempotent (last-write-wins) and exempt from the cap.
    if (event.kind == kNoteKind && !_acceptWithinRateLimit()) {
      debugPrint('MESH/SURR: drop (rate limit $_maxNotesPerSecond/s)');
      return false;
    }

    if (!event.isValid()) {
      debugPrint('MESH/SURR: drop ${event.id.substring(0, 8)}… (bad sig/id)');
      return false; // recomputed id / signature mismatch
    }

    if (event.kind == 0) {
      await _ingestProfile(event); // author metadata for name/avatar rendering
      return true;
    }

    final note = NoteModel.fromEvent(event); // reuse NIP-10 tag parsing

    await _isar.writeTxn(() async {
      final blocked = await _isar.blockedUserModels
          .where()
          .pubkeyHexEqualTo(event.pubkey)
          .findFirst();
      if (blocked != null) return;
      final tombstoned = await _isar.deletedNoteModels
          .where()
          .eventIdEqualTo(event.id)
          .findFirst();
      if (tombstoned != null) return;

      await _isar.surroundingNoteModels.put(SurroundingNoteModel()
        ..eventId = note.eventId
        ..sig = note.sig
        ..authorPubkey = note.authorPubkey
        ..content = note.content
        ..type = note.type
        ..eTagRefs = note.eTagRefs
        ..pTagRefs = note.pTagRefs
        ..tTags = note.tTags
        ..rootEventId = note.rootEventId
        ..replyToEventId = note.replyToEventId
        ..quoteEventId = note.quoteEventId
        ..kind = note.kind
        ..created = note.created
        ..receivedAt = DateTime.now());
      debugPrint('MESH/SURR: stored ${note.eventId.substring(0, 8)}… '
          'from ${event.pubkey.substring(0, 8)}…');
    });
    return true; // valid public note — relay it regardless of local storage
  }

  Future<void> _ingestProfile(Event event) async {
    final incoming = ProfileModel.fromEvent(event);
    await _isar.writeTxn(() async {
      final blocked = await _isar.blockedUserModels
          .where()
          .pubkeyHexEqualTo(event.pubkey)
          .findFirst();
      if (blocked != null) return;
      final existing = await _isar.profileModels
          .where()
          .pubkeyEqualTo(event.pubkey)
          .findFirst();
      // Last-write-wins by the kind-0 created_at.
      if (existing != null && !incoming.updatedAt.isAfter(existing.updatedAt)) {
        return;
      }
      // Reuse the existing row id to replace (pubkey index is unique, not
      // replace), and keep it fresh so the 30-day profile eviction doesn't drop it.
      if (existing != null) incoming.id = existing.id;
      incoming.lastSeenAt = existing?.lastSeenAt ?? DateTime.now();
      await _isar.profileModels.put(incoming);
    });
  }
}
