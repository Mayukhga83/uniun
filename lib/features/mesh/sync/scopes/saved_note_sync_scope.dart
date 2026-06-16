import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/core/enum/note_type.dart';
import 'package:uniun/data/models/saved_note_model.dart';

import '../sync_scope.dart';

/// Reconciles the user's bookmarked notes (separate forever-retained collection).
/// Keyed by `eventId`; idempotent insert (a bookmark already present is left as-is,
/// preserving the local `savedAt`).
class SavedNoteSyncScope implements SyncScope {
  SavedNoteSyncScope(this._isar);

  final Isar _isar;

  @override
  String get name => 'savedNote';

  @override
  Future<Set<String>> localKeys() async {
    final ids = await _isar.savedNoteModels.where().eventIdProperty().findAll();
    return ids.toSet();
  }

  @override
  Future<List<Map<String, dynamic>>> rows(Set<String> keys) async {
    if (keys.isEmpty) return const [];
    final found = await _isar.savedNoteModels
        .filter()
        .anyOf(keys, (q, String k) => q.eventIdEqualTo(k))
        .findAll();
    return found.map(encode).toList();
  }

  @override
  Future<void> upsert(List<Map<String, dynamic>> rows) async {
    await _isar.writeTxn(() async {
      for (final row in rows) {
        try {
          final model = decode(row);
          final existing = await _isar.savedNoteModels
              .where()
              .eventIdEqualTo(model.eventId)
              .findFirst();
          if (existing != null) continue; // idempotent — keep local savedAt
          await _isar.savedNoteModels.put(model);
        } catch (e) {
          debugPrint('MESH/SYNC: savedNote upsert skipped: $e');
        }
      }
    });
  }

  static Map<String, dynamic> encode(SavedNoteModel s) => {
        'eventId': s.eventId,
        'sig': s.sig,
        'authorPubkey': s.authorPubkey,
        'content': s.content,
        'type': s.type.name,
        'eTagRefs': s.eTagRefs,
        if (s.rootEventId != null) 'rootEventId': s.rootEventId,
        if (s.replyToEventId != null) 'replyToEventId': s.replyToEventId,
        'pTagRefs': s.pTagRefs,
        'tTags': s.tTags,
        'created': s.created.millisecondsSinceEpoch,
        'savedAt': s.savedAt.millisecondsSinceEpoch,
        if (s.sourceChannelId != null) 'sourceChannelId': s.sourceChannelId,
        if (s.sourcePrivateGroupId != null)
          'sourcePrivateGroupId': s.sourcePrivateGroupId,
        if (s.quoteEventId != null) 'quoteEventId': s.quoteEventId,
      };

  static SavedNoteModel decode(Map<String, dynamic> j) => SavedNoteModel()
    ..eventId = j['eventId'] as String
    ..sig = j['sig'] as String? ?? ''
    ..authorPubkey = j['authorPubkey'] as String
    ..content = j['content'] as String? ?? ''
    ..type = NoteType.values.firstWhere(
      (t) => t.name == j['type'],
      orElse: () => NoteType.text,
    )
    ..eTagRefs = (j['eTagRefs'] as List?)?.cast<String>() ?? const []
    ..rootEventId = j['rootEventId'] as String?
    ..replyToEventId = j['replyToEventId'] as String?
    ..pTagRefs = (j['pTagRefs'] as List?)?.cast<String>() ?? const []
    ..tTags = (j['tTags'] as List?)?.cast<String>() ?? const []
    ..created = DateTime.fromMillisecondsSinceEpoch(j['created'] as int)
    ..savedAt = DateTime.fromMillisecondsSinceEpoch(j['savedAt'] as int)
    ..sourceChannelId = j['sourceChannelId'] as String?
    ..sourcePrivateGroupId = j['sourcePrivateGroupId'] as String?
    ..quoteEventId = j['quoteEventId'] as String?;
}
