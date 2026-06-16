import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/data/models/blocked_user_model.dart';

import '../sync_scope.dart';

/// Reconciles blocked users so a block on one device applies on the other, keyed
/// by pubkey. Find-or-create; the gateway's in-memory blocklist picks the new row
/// up via its `watchLazy` on `BlockedUser`.
class BlockedUserSyncScope implements SyncScope {
  BlockedUserSyncScope(this._isar);

  final Isar _isar;

  @override
  String get name => 'blockedUser';

  @override
  Future<Set<String>> localKeys() async {
    final rows = await _isar.blockedUserModels.where().findAll();
    return rows.map((b) => b.pubkeyHex).toSet();
  }

  @override
  Future<List<Map<String, dynamic>>> rows(Set<String> keys) async {
    if (keys.isEmpty) return const [];
    final found = await _isar.blockedUserModels
        .filter()
        .anyOf(keys, (q, String k) => q.pubkeyHexEqualTo(k))
        .findAll();
    return found.map(encode).toList();
  }

  @override
  Future<void> upsert(List<Map<String, dynamic>> rows) async {
    await _isar.writeTxn(() async {
      for (final row in rows) {
        try {
          final model = decode(row);
          final existing = await _isar.blockedUserModels
              .where()
              .pubkeyHexEqualTo(model.pubkeyHex)
              .findFirst();
          if (existing != null) continue;
          await _isar.blockedUserModels.put(model);
        } catch (e) {
          debugPrint('MESH/SYNC: blockedUser upsert skipped: $e');
        }
      }
    });
  }

  static Map<String, dynamic> encode(BlockedUserModel b) => {
        'pubkeyHex': b.pubkeyHex,
        'blockedAt': b.blockedAt.millisecondsSinceEpoch,
      };

  static BlockedUserModel decode(Map<String, dynamic> j) => BlockedUserModel()
    ..pubkeyHex = j['pubkeyHex'] as String
    ..blockedAt =
        DateTime.fromMillisecondsSinceEpoch(j['blockedAt'] as int? ?? 0);
}
