import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/core/enum/note_type.dart';
import 'package:uniun/core/notes/note_kinds.dart';
import 'package:uniun/core/notes/reply_edge.dart';
import 'package:uniun/data/models/deleted_note_model.dart';
import 'package:uniun/data/models/notes/note_model.dart';
import 'package:uniun/data/models/notes/unread_note_model.dart';
import 'package:uniun/domain/repositories/note_relation_repository.dart';

import '../sync_scope.dart';

/// Reconciles the unified `Note` collection across a same-identity peer — feed
/// (kind 1), public channel (42), private channel (9023) AND DMs (14/15).
///
/// DMs are included because [conversationId] is now globally stable: the
/// `DmConversation` id is a deterministic hash of the counterparty pubkey
/// (`fastHash(otherPubkey)`), identical on every device, so the FK transfers
/// verbatim. The matching `DmConversation` rows are reconciled by
/// `DmConversationSyncScope`.
///
/// Tombstone-aware (no resurrection); per-row isolated so one bad row can't roll
/// back the batch. Every freshly-inserted note gets an unread row — in
/// same-identity sync the author is always us, so the relay handler's "skip own"
/// guard would wrongly suppress all of them and they'd never surface in the feed
/// banner / unread phase.
class NoteSyncScope implements SyncScope {
  NoteSyncScope(this._isar, this._relations);

  final Isar _isar;
  final NoteRelationRepository _relations;

  @override
  String get name => 'note';

  Future<Set<String>> _tombstonedIds() async {
    final ids = await _isar.deletedNoteModels.where().eventIdProperty().findAll();
    return ids.toSet();
  }

  @override
  Future<Set<String>> localKeys() async {
    final ids = await _isar.noteModels.where().eventIdProperty().findAll();
    final keys = ids.toSet();
    // Never re-request ids we've deleted locally.
    keys.addAll(await _tombstonedIds());
    return keys;
  }

  @override
  Future<List<Map<String, dynamic>>> rows(Set<String> keys) async {
    if (keys.isEmpty) return const [];
    final found = await _isar.noteModels
        .filter()
        .anyOf(keys, (q, String k) => q.eventIdEqualTo(k))
        .findAll();
    return found.map(encode).toList();
  }

  @override
  Future<void> upsert(List<Map<String, dynamic>> rows) async {
    final tombstoned = await _tombstonedIds();
    await _isar.writeTxn(() async {
      for (final row in rows) {
        // Per-row isolation: a single malformed/conflicting row must not roll back
        // the whole batch.
        try {
          final note = decode(row);
          if (tombstoned.contains(note.eventId)) continue; // don't resurrect
          final existing = await _isar.noteModels
              .where()
              .eventIdEqualTo(note.eventId)
              .findFirst();
          if (existing != null) continue; // idempotent
          await _isar.noteModels.put(note);
          // New to THIS device → unread (idempotent via the unique eventId index).
          await putUnreadRowInTxn(_isar, note);
          final parents = replyEdgeParentIds(
            replyToEventId: note.replyToEventId,
            rootEventId: note.rootEventId,
            eTagRefs: note.eTagRefs,
          );
          await _relations.addEdgesInTxn(parents: parents, childId: note.eventId);
        } catch (e) {
          debugPrint('MESH/SYNC: note upsert skipped ${row['eventId']}: $e');
        }
      }
    });
  }

  /// Serializes a [NoteModel] for the wire. The local autoincrement Isar `id` is
  /// omitted; `conversationId` IS carried (it is a stable cross-device hash).
  static Map<String, dynamic> encode(NoteModel n) => {
        'eventId': n.eventId,
        'sig': n.sig,
        'authorPubkey': n.authorPubkey,
        'content': n.content,
        if (n.subject != null) 'subject': n.subject,
        'kind': n.kind,
        if (n.channelId != null) 'channelId': n.channelId,
        if (n.groupId != null) 'groupId': n.groupId,
        if (n.conversationId != null) 'conversationId': n.conversationId,
        'type': n.type.name,
        'eTagRefs': n.eTagRefs,
        if (n.rootEventId != null) 'rootEventId': n.rootEventId,
        if (n.replyToEventId != null) 'replyToEventId': n.replyToEventId,
        'pTagRefs': n.pTagRefs,
        'tTags': n.tTags,
        'created': n.created.millisecondsSinceEpoch,
        if (n.quoteEventId != null) 'quoteEventId': n.quoteEventId,
      };

  static NoteModel decode(Map<String, dynamic> j) => NoteModel(
        eventId: j['eventId'] as String,
        sig: j['sig'] as String? ?? '',
        authorPubkey: j['authorPubkey'] as String,
        content: j['content'] as String? ?? '',
        subject: j['subject'] as String?,
        kind: j['kind'] as int? ?? kNoteKind,
        channelId: j['channelId'] as String?,
        groupId: j['groupId'] as String?,
        conversationId: j['conversationId'] as int?,
        type: NoteType.values.firstWhere(
          (t) => t.name == j['type'],
          orElse: () => NoteType.text,
        ),
        eTagRefs: (j['eTagRefs'] as List?)?.cast<String>() ?? const [],
        rootEventId: j['rootEventId'] as String?,
        replyToEventId: j['replyToEventId'] as String?,
        pTagRefs: (j['pTagRefs'] as List?)?.cast<String>() ?? const [],
        tTags: (j['tTags'] as List?)?.cast<String>() ?? const [],
        created: DateTime.fromMillisecondsSinceEpoch(j['created'] as int),
        quoteEventId: j['quoteEventId'] as String?,
      );
}
