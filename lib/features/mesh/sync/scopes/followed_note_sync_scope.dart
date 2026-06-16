import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/data/models/followed_note_model.dart';

import '../sync_scope.dart';

/// Reconciles followed notes (subscriptions to a note's reference graph), keyed by
/// eventId. Find-or-create; `newReferenceCount` is carried from the source but not
/// merged (it re-accrues from the gateway's `#e` subscriptions).
class FollowedNoteSyncScope implements SyncScope {
  FollowedNoteSyncScope(this._isar);

  final Isar _isar;

  @override
  String get name => 'followedNote';

  @override
  Future<Set<String>> localKeys() async {
    final rows = await _isar.followedNoteModels.where().findAll();
    return rows.map((n) => n.eventId).toSet();
  }

  @override
  Future<List<Map<String, dynamic>>> rows(Set<String> keys) async {
    if (keys.isEmpty) return const [];
    final found = await _isar.followedNoteModels
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
          final existing = await _isar.followedNoteModels
              .where()
              .eventIdEqualTo(model.eventId)
              .findFirst();
          if (existing != null) continue;
          await _isar.followedNoteModels.put(model);
        } catch (e) {
          debugPrint('MESH/SYNC: followedNote upsert skipped: $e');
        }
      }
    });
  }

  static Map<String, dynamic> encode(FollowedNoteModel n) => {
        'eventId': n.eventId,
        'contentPreview': n.contentPreview,
        'followedAt': n.followedAt.millisecondsSinceEpoch,
        'newReferenceCount': n.newReferenceCount,
      };

  static FollowedNoteModel decode(Map<String, dynamic> j) => FollowedNoteModel()
    ..eventId = j['eventId'] as String
    ..contentPreview = j['contentPreview'] as String? ?? ''
    ..followedAt =
        DateTime.fromMillisecondsSinceEpoch(j['followedAt'] as int? ?? 0)
    ..newReferenceCount = j['newReferenceCount'] as int? ?? 0;
}
