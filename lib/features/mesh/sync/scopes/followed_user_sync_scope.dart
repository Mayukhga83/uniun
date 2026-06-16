import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/data/models/followed_user_model.dart';

import '../sync_scope.dart';

/// Reconciles followed users (the local NIP-02 follow pointers), keyed by pubkey.
/// Find-or-create (Kind-3 last-write-wins updates still flow from relays).
class FollowedUserSyncScope implements SyncScope {
  FollowedUserSyncScope(this._isar);

  final Isar _isar;

  @override
  String get name => 'followedUser';

  @override
  Future<Set<String>> localKeys() async {
    final rows = await _isar.followedUserModels.where().findAll();
    return rows.map((u) => u.pubkeyHex).toSet();
  }

  @override
  Future<List<Map<String, dynamic>>> rows(Set<String> keys) async {
    if (keys.isEmpty) return const [];
    final found = await _isar.followedUserModels
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
          final existing = await _isar.followedUserModels
              .where()
              .pubkeyHexEqualTo(model.pubkeyHex)
              .findFirst();
          if (existing != null) continue;
          await _isar.followedUserModels.put(model);
        } catch (e) {
          debugPrint('MESH/SYNC: followedUser upsert skipped: $e');
        }
      }
    });
  }

  static Map<String, dynamic> encode(FollowedUserModel u) => {
        'pubkeyHex': u.pubkeyHex,
        if (u.relayHint != null) 'relayHint': u.relayHint,
        if (u.petname != null) 'petname': u.petname,
        'followedAt': u.followedAt.millisecondsSinceEpoch,
        if (u.lastKind3CreatedAt != null)
          'lastKind3CreatedAt': u.lastKind3CreatedAt!.millisecondsSinceEpoch,
      };

  static FollowedUserModel decode(Map<String, dynamic> j) => FollowedUserModel()
    ..pubkeyHex = j['pubkeyHex'] as String
    ..relayHint = j['relayHint'] as String?
    ..petname = j['petname'] as String?
    ..followedAt =
        DateTime.fromMillisecondsSinceEpoch(j['followedAt'] as int? ?? 0)
    ..lastKind3CreatedAt = j['lastKind3CreatedAt'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(j['lastKind3CreatedAt'] as int);
}
