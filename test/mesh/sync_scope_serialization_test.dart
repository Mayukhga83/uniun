import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/core/enum/note_type.dart';
import 'package:uniun/core/utils/fast_hash.dart';
import 'package:uniun/data/models/blocked_user_model.dart';
import 'package:uniun/data/models/deleted_note_model.dart';
import 'package:uniun/data/models/dm/dm_conversation_model.dart';
import 'package:uniun/data/models/followed_note_model.dart';
import 'package:uniun/data/models/followed_user_model.dart';
import 'package:uniun/data/models/notes/note_model.dart';
import 'package:uniun/data/models/profile_model.dart';
import 'package:uniun/data/models/saved_note_model.dart';
import 'package:uniun/features/mesh/sync/scopes/blocked_user_sync_scope.dart';
import 'package:uniun/features/mesh/sync/scopes/deleted_note_sync_scope.dart';
import 'package:uniun/features/mesh/sync/scopes/dm_conversation_sync_scope.dart';
import 'package:uniun/features/mesh/sync/scopes/followed_note_sync_scope.dart';
import 'package:uniun/features/mesh/sync/scopes/followed_user_sync_scope.dart';
import 'package:uniun/features/mesh/sync/scopes/note_sync_scope.dart';
import 'package:uniun/features/mesh/sync/scopes/profile_sync_scope.dart';
import 'package:uniun/features/mesh/sync/scopes/saved_note_sync_scope.dart';

void main() {
  test('NoteSyncScope encode/decode round-trips all fields', () {
    final created = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    final note = NoteModel(
      eventId: 'e1',
      sig: 'sig1',
      authorPubkey: 'pk1',
      content: 'hello',
      subject: 'subj',
      kind: 42,
      channelId: 'chan1',
      type: NoteType.link,
      eTagRefs: ['a', 'b'],
      rootEventId: 'r',
      replyToEventId: 'p',
      pTagRefs: ['x'],
      tTags: ['nostr'],
      created: created,
      quoteEventId: 'q1',
    );

    final decoded = NoteSyncScope.decode(NoteSyncScope.encode(note));
    expect(decoded.eventId, 'e1');
    expect(decoded.sig, 'sig1');
    expect(decoded.authorPubkey, 'pk1');
    expect(decoded.content, 'hello');
    expect(decoded.subject, 'subj');
    expect(decoded.kind, 42);
    expect(decoded.channelId, 'chan1');
    expect(decoded.type, NoteType.link);
    expect(decoded.eTagRefs, ['a', 'b']);
    expect(decoded.rootEventId, 'r');
    expect(decoded.replyToEventId, 'p');
    expect(decoded.pTagRefs, ['x']);
    expect(decoded.tTags, ['nostr']);
    expect(decoded.created, created);
    expect(decoded.quoteEventId, 'q1');
  });

  test('NoteSyncScope minimal kind-1 note (nullables stay null)', () {
    final created = DateTime.fromMillisecondsSinceEpoch(1700000001000);
    final note = NoteModel(
      eventId: 'e2',
      sig: '',
      authorPubkey: 'pk',
      content: 'hi',
      type: NoteType.text,
      eTagRefs: const [],
      pTagRefs: const [],
      tTags: const [],
      created: created,
    );

    final decoded = NoteSyncScope.decode(NoteSyncScope.encode(note));
    expect(decoded.eventId, 'e2');
    expect(decoded.kind, 1);
    expect(decoded.channelId, isNull);
    expect(decoded.groupId, isNull);
    expect(decoded.subject, isNull);
    expect(decoded.rootEventId, isNull);
    expect(decoded.quoteEventId, isNull);
    expect(decoded.created, created);
  });

  test('SavedNoteSyncScope round-trips', () {
    final created = DateTime.fromMillisecondsSinceEpoch(1700000002000);
    final savedAt = DateTime.fromMillisecondsSinceEpoch(1700000003000);
    final saved = SavedNoteModel()
      ..eventId = 's1'
      ..sig = 'sig'
      ..authorPubkey = 'pk'
      ..content = 'c'
      ..type = NoteType.image
      ..eTagRefs = ['a']
      ..rootEventId = 'r'
      ..replyToEventId = null
      ..pTagRefs = []
      ..tTags = ['t']
      ..created = created
      ..savedAt = savedAt
      ..sourceChannelId = 'chan'
      ..sourcePrivateGroupId = null
      ..quoteEventId = 'q';

    final decoded = SavedNoteSyncScope.decode(SavedNoteSyncScope.encode(saved));
    expect(decoded.eventId, 's1');
    expect(decoded.type, NoteType.image);
    expect(decoded.created, created);
    expect(decoded.savedAt, savedAt);
    expect(decoded.sourceChannelId, 'chan');
    expect(decoded.sourcePrivateGroupId, isNull);
    expect(decoded.eTagRefs, ['a']);
    expect(decoded.tTags, ['t']);
    expect(decoded.quoteEventId, 'q');
  });

  test('NoteSyncScope carries conversationId for a DM note', () {
    final created = DateTime.fromMillisecondsSinceEpoch(1700000005000);
    final dm = NoteModel(
      eventId: 'dm1',
      sig: '',
      authorPubkey: 'pk',
      content: 'hi there',
      kind: 14,
      conversationId: 123456789,
      type: NoteType.text,
      eTagRefs: const [],
      pTagRefs: const ['recipientpk'],
      tTags: const [],
      created: created,
    );
    final decoded = NoteSyncScope.decode(NoteSyncScope.encode(dm));
    expect(decoded.kind, 14);
    expect(decoded.conversationId, 123456789);
    expect(decoded.pTagRefs, ['recipientpk']);
  });

  test('DmConversationSyncScope round-trips with a deterministic id', () {
    final pub = 'b' * 64;
    final conv = DmConversationModel()
      ..otherPubkey = pub
      ..relays = ['wss://relay.example'];
    final decoded =
        DmConversationSyncScope.decode(DmConversationSyncScope.encode(conv));
    expect(decoded.otherPubkey, pub);
    expect(decoded.relays, ['wss://relay.example']);
    // Same pubkey → same id on every device (this is what makes DM sync work).
    expect(decoded.id, fastHash(pub));
    expect(decoded.id, conv.id);
  });

  test('DeletedNoteSyncScope round-trips', () {
    final at = DateTime.fromMillisecondsSinceEpoch(1700000004000);
    final tombstone = DeletedNoteModel()
      ..eventId = 'd1'
      ..deletedAt = at;
    final decoded =
        DeletedNoteSyncScope.decode(DeletedNoteSyncScope.encode(tombstone));
    expect(decoded.eventId, 'd1');
    expect(decoded.deletedAt, at);
  });

  test('ProfileSyncScope round-trips', () {
    final updated = DateTime.fromMillisecondsSinceEpoch(1700000005000);
    final p = ProfileModel()
      ..pubkey = 'pk1'
      ..name = 'Alice'
      ..username = 'alice'
      ..about = 'hi'
      ..avatarUrl = 'https://x/a.png'
      ..nip05 = 'alice@x.com'
      ..updatedAt = updated
      ..lastSeenAt = DateTime.fromMillisecondsSinceEpoch(1700000006000);
    final d = ProfileSyncScope.decode(ProfileSyncScope.encode(p));
    expect(d.pubkey, 'pk1');
    expect(d.name, 'Alice');
    expect(d.username, 'alice');
    expect(d.nip05, 'alice@x.com');
    expect(d.updatedAt, updated);
    expect(d.lastSeenAt, DateTime.fromMillisecondsSinceEpoch(1700000006000));
  });

  test('FollowedUserSyncScope round-trips', () {
    final at = DateTime.fromMillisecondsSinceEpoch(1700000007000);
    final u = FollowedUserModel()
      ..pubkeyHex = 'pk2'
      ..relayHint = 'wss://r'
      ..petname = 'B'
      ..followedAt = at
      ..lastKind3CreatedAt = at;
    final d = FollowedUserSyncScope.decode(FollowedUserSyncScope.encode(u));
    expect(d.pubkeyHex, 'pk2');
    expect(d.relayHint, 'wss://r');
    expect(d.petname, 'B');
    expect(d.followedAt, at);
    expect(d.lastKind3CreatedAt, at);
  });

  test('FollowedNoteSyncScope round-trips', () {
    final at = DateTime.fromMillisecondsSinceEpoch(1700000008000);
    final n = FollowedNoteModel()
      ..eventId = 'fn1'
      ..contentPreview = 'preview'
      ..followedAt = at
      ..newReferenceCount = 3;
    final d = FollowedNoteSyncScope.decode(FollowedNoteSyncScope.encode(n));
    expect(d.eventId, 'fn1');
    expect(d.contentPreview, 'preview');
    expect(d.followedAt, at);
    expect(d.newReferenceCount, 3);
  });

  test('BlockedUserSyncScope round-trips', () {
    final at = DateTime.fromMillisecondsSinceEpoch(1700000009000);
    final b = BlockedUserModel()
      ..pubkeyHex = 'pk3'
      ..blockedAt = at;
    final d = BlockedUserSyncScope.decode(BlockedUserSyncScope.encode(b));
    expect(d.pubkeyHex, 'pk3');
    expect(d.blockedAt, at);
  });
}
