import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/data/models/dm/dm_conversation_model.dart';

import '../sync_scope.dart';

/// Reconciles DM conversation rows so a synced DM note's `conversationId` (a
/// deterministic hash of the counterparty pubkey) resolves to a real conversation
/// on the other device. Keyed by `otherPubkey`; the Isar id is derived from it, so
/// upsert is an idempotent put under the unique index.
class DmConversationSyncScope implements SyncScope {
  DmConversationSyncScope(this._isar);

  final Isar _isar;

  @override
  String get name => 'dmConversation';

  @override
  Future<Set<String>> localKeys() async {
    final rows = await _isar.dmConversationModels.where().findAll();
    return rows.map((c) => c.otherPubkey).toSet();
  }

  @override
  Future<List<Map<String, dynamic>>> rows(Set<String> keys) async {
    if (keys.isEmpty) return const [];
    final found = await _isar.dmConversationModels
        .filter()
        .anyOf(keys, (q, String k) => q.otherPubkeyEqualTo(k))
        .findAll();
    return found.map(encode).toList();
  }

  @override
  Future<void> upsert(List<Map<String, dynamic>> rows) async {
    await _isar.writeTxn(() async {
      for (final row in rows) {
        try {
          final model = decode(row);
          final existing = await _isar.dmConversationModels
              .where()
              .otherPubkeyEqualTo(model.otherPubkey)
              .findFirst();
          if (existing != null) continue; // idempotent
          await _isar.dmConversationModels.put(model);
        } catch (e) {
          debugPrint('MESH/SYNC: dmConversation upsert skipped: $e');
        }
      }
    });
  }

  static Map<String, dynamic> encode(DmConversationModel c) => {
        'otherPubkey': c.otherPubkey,
        'relays': c.relays,
      };

  static DmConversationModel decode(Map<String, dynamic> j) =>
      DmConversationModel()
        ..otherPubkey = j['otherPubkey'] as String
        ..relays = (j['relays'] as List?)?.cast<String>() ?? const [];
}
