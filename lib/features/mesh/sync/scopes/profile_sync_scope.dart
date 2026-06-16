import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/data/models/profile_model.dart';

import '../sync_scope.dart';

/// Reconciles cached user profiles (kind 0), keyed by pubkey. Find-or-create:
/// a profile present on both devices is left as-is (the id-list diff only fills
/// missing keys; profile *updates* re-flow from relays). The own-profile sentinel
/// `lastSeenAt` is carried so it stays unevictable on the other device.
class ProfileSyncScope implements SyncScope {
  ProfileSyncScope(this._isar);

  final Isar _isar;

  @override
  String get name => 'profile';

  @override
  Future<Set<String>> localKeys() async {
    final rows = await _isar.profileModels.where().findAll();
    return rows.map((p) => p.pubkey).toSet();
  }

  @override
  Future<List<Map<String, dynamic>>> rows(Set<String> keys) async {
    if (keys.isEmpty) return const [];
    final found = await _isar.profileModels
        .filter()
        .anyOf(keys, (q, String k) => q.pubkeyEqualTo(k))
        .findAll();
    return found.map(encode).toList();
  }

  @override
  Future<void> upsert(List<Map<String, dynamic>> rows) async {
    await _isar.writeTxn(() async {
      for (final row in rows) {
        try {
          final model = decode(row);
          final existing = await _isar.profileModels
              .where()
              .pubkeyEqualTo(model.pubkey)
              .findFirst();
          if (existing != null) continue;
          await _isar.profileModels.put(model);
        } catch (e) {
          debugPrint('MESH/SYNC: profile upsert skipped: $e');
        }
      }
    });
  }

  static Map<String, dynamic> encode(ProfileModel p) => {
        'pubkey': p.pubkey,
        if (p.name != null) 'name': p.name,
        if (p.username != null) 'username': p.username,
        if (p.about != null) 'about': p.about,
        if (p.avatarUrl != null) 'avatarUrl': p.avatarUrl,
        if (p.nip05 != null) 'nip05': p.nip05,
        'updatedAt': p.updatedAt.millisecondsSinceEpoch,
        if (p.lastSeenAt != null)
          'lastSeenAt': p.lastSeenAt!.millisecondsSinceEpoch,
      };

  static ProfileModel decode(Map<String, dynamic> j) => ProfileModel()
    ..pubkey = j['pubkey'] as String
    ..name = j['name'] as String?
    ..username = j['username'] as String?
    ..about = j['about'] as String?
    ..avatarUrl = j['avatarUrl'] as String?
    ..nip05 = j['nip05'] as String?
    ..updatedAt =
        DateTime.fromMillisecondsSinceEpoch(j['updatedAt'] as int? ?? 0)
    ..lastSeenAt = j['lastSeenAt'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(j['lastSeenAt'] as int);
}
