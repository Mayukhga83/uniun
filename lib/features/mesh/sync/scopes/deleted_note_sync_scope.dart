import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/data/models/deleted_note_model.dart';
import 'package:uniun/data/models/notes/note_model.dart';
import 'package:uniun/data/models/notes/unread_note_model.dart';

import '../sync_scope.dart';

/// Reconciles deletion tombstones so a note deleted on one device stays deleted on
/// the other (Feed-Freedom-safe: a local suppression record, not NIP-09). Applying
/// an inbound tombstone also removes the matching `Note` + `UnreadNote` rows, so a
/// note that synced before the tombstone arrived is retracted. Combined with the
/// tombstone-awareness in `NoteSyncScope`, deletions converge without resurrection
/// regardless of scope ordering.
class DeletedNoteSyncScope implements SyncScope {
  DeletedNoteSyncScope(this._isar);

  final Isar _isar;

  @override
  String get name => 'deletedNote';

  @override
  Future<Set<String>> localKeys() async {
    final ids = await _isar.deletedNoteModels.where().eventIdProperty().findAll();
    return ids.toSet();
  }

  @override
  Future<List<Map<String, dynamic>>> rows(Set<String> keys) async {
    if (keys.isEmpty) return const [];
    final found = await _isar.deletedNoteModels
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
          final tombstone = decode(row);
          final existing = await _isar.deletedNoteModels
              .where()
              .eventIdEqualTo(tombstone.eventId)
              .findFirst();
          if (existing == null) {
            await _isar.deletedNoteModels.put(tombstone);
          }
          // Retract the note locally if it slipped in before the tombstone.
          await _isar.noteModels
              .filter()
              .eventIdEqualTo(tombstone.eventId)
              .deleteAll();
          await _isar.unreadNoteModels
              .filter()
              .eventIdEqualTo(tombstone.eventId)
              .deleteAll();
        } catch (e) {
          debugPrint('MESH/SYNC: deletedNote upsert skipped: $e');
        }
      }
    });
  }

  static Map<String, dynamic> encode(DeletedNoteModel d) => {
        'eventId': d.eventId,
        'deletedAt': d.deletedAt.millisecondsSinceEpoch,
      };

  static DeletedNoteModel decode(Map<String, dynamic> j) => DeletedNoteModel()
    ..eventId = j['eventId'] as String
    ..deletedAt = DateTime.fromMillisecondsSinceEpoch(
      j['deletedAt'] as int? ?? 0,
    );
}
