import 'package:isar_community/isar.dart';
import 'package:uniun/domain/repositories/note_relation_repository.dart';

import 'scopes/blocked_user_sync_scope.dart';
import 'scopes/deleted_note_sync_scope.dart';
import 'scopes/dm_conversation_sync_scope.dart';
import 'scopes/followed_note_sync_scope.dart';
import 'scopes/followed_user_sync_scope.dart';
import 'scopes/note_sync_scope.dart';
import 'scopes/profile_sync_scope.dart';
import 'scopes/saved_note_sync_scope.dart';
import 'sync_scope.dart';

/// The collections reconciled with a same-identity peer, a fresh list per session.
/// Covers all Nostr content (feed / channel / private-channel / DM notes),
/// bookmarks, deletion tombstones, DM conversations, cached profiles, follows
/// (users + notes), and blocks.
List<SyncScope> buildTrustedSyncScopes({
  required Isar isar,
  required NoteRelationRepository relations,
}) {
  return [
    NoteSyncScope(isar, relations),
    SavedNoteSyncScope(isar),
    DeletedNoteSyncScope(isar),
    DmConversationSyncScope(isar),
    ProfileSyncScope(isar),
    FollowedUserSyncScope(isar),
    FollowedNoteSyncScope(isar),
    BlockedUserSyncScope(isar),
  ];
}
