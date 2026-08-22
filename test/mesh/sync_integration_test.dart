import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:uniun/core/enum/note_type.dart';
import 'package:uniun/core/utils/fast_hash.dart';
import 'package:uniun/data/datasources/isar_schemas.dart';
import 'package:uniun/data/models/blocked_user_model.dart';
import 'package:uniun/data/models/dm/dm_conversation_model.dart';
import 'package:uniun/data/models/followed_note_model.dart';
import 'package:uniun/data/models/followed_user_model.dart';
import 'package:uniun/data/models/gana_model.dart';
import 'package:uniun/data/models/manas_model.dart';
import 'package:uniun/data/models/manas_note_link_model.dart';
import 'package:uniun/data/models/notes/note_model.dart';
import 'package:uniun/data/models/notes/unread_note_model.dart';
import 'package:uniun/data/models/profile_model.dart';
import 'package:uniun/data/models/saved_note_model.dart';
import 'package:uniun/data/repositories/note_relation_repository_impl.dart';
import 'package:uniun/core/enum/gana_output_type.dart';
import 'package:uniun/core/enum/gana_trigger_mode.dart';
import 'package:uniun/features/mesh/link/link_session.dart';
import 'package:uniun/features/mesh/sync/bodies/blocked_user_body.dart';
import 'package:uniun/features/mesh/sync/bodies/dm_conversation_body.dart';
import 'package:uniun/features/mesh/sync/bodies/followed_note_body.dart';
import 'package:uniun/features/mesh/sync/bodies/followed_user_body.dart';
import 'package:uniun/features/mesh/sync/bodies/gana_body.dart';
import 'package:uniun/features/mesh/sync/bodies/manas_body.dart';
import 'package:uniun/features/mesh/sync/bodies/manas_member_body.dart';
import 'package:uniun/features/mesh/sync/bodies/saved_note_body.dart';
import 'package:uniun/features/mesh/sync/mesh_event_codec.dart';
import 'package:uniun/features/mesh/sync/nip77_reconciler.dart';
import 'package:uniun/features/mesh/sync/negentropy_sync_scopes.dart';

import '../_helpers/isar_test_harness.dart';

import 'support/paired_mesh_link.dart';
import '../_helpers/mesh_test_helpers.dart';

/// Drives the REAL Nip77Reconciler over the REAL
/// Isar-backed scopes against two temp Isar instances — the only test that
/// exercises production upsert/writeTxn on both engines at once (the unit
/// tests use in-memory fakes). Validates actual row transfer, the
/// unconditional unread row, the deterministic DM-conversation remapping,
/// and (Phase 1) the negentropy-driven SavedNote convergence.
///
/// Requires the Isar native core; skips gracefully if it can't initialize.
void main() {
  stubSecureStorageChannel();

  final temps = <Directory>[];

  setUpAll(() async {
    // A core init failure must FAIL the suite, not silently skip it —
    // ensureIsarCore (shared harness) is race-safe and mock-proof.
    await ensureIsarCore();
  });

  tearDownAll(() async {
    for (final d in temps) {
      if (await d.exists()) await d.delete(recursive: true);
    }
  });

  Future<Isar> openIsar(String name) async {
    final dir = await Directory.systemTemp.createTemp('uniun_mesh_$name');
    temps.add(dir);
    return Isar.open(isarSchemas, directory: dir.path, name: name);
  }

  test(
    'two real Isar peers converge notes, saved, DMs + unread rows',
    () async {
      final isarA = await openIsar('a${temps.length}');
      final isarB = await openIsar('b${temps.length}');
      addTearDown(() async {
        await isarA.close();
        await isarB.close();
      });

      // Shared identity — same-pubkey mesh sync between two of the user's own
      // devices. SavedNote sync (Phase 1) requires real keys so the codec can
      // sign + self-encrypt.
      final me = Keychain.generate();
      final ownPubkey = me.public;
      final codec = MeshEventCodec(
        privkeyHex: me.private,
        pubkeyHex: me.public,
      );
      // Bob is the other party in the user's DM / follow / profile records.
      // We need his private key so we can sign a real Kind-0 profile event —
      // in Phase 3 profile sync is exactly that raw Nostr event, not a
      // hand-rolled ProfileModel row.
      final other = Keychain.generate();
      final otherPubkey = other.public;
      final convId = fastHash(otherPubkey);

      // Kind 0 (Bob's profile) — signed by Bob. Any author is fine on Kind 0
      // (foreign profiles render in the UI).
      final kind0EventJson = jsonEncode(
        Event.from(
          kind: 0,
          tags: const [],
          content: jsonEncode({'name': 'Bob'}),
          privkey: other.private,
          createdAt: 1700000004,
        ).toJson(),
      );

      // Pre-sign the SavedNote row's mesh event so the Nip77Reconciler's
      // `localIndex()` on side A picks it up. Production does this inline in
      // SavedNoteRepositoryImpl.saveNote / MeshSchemaMigration; here we do it
      // by hand so the test doesn't have to spin up either.
      final savedRow = SavedNoteModel()
        ..eventId = 'saved1'
        ..sig = 'sig'
        ..authorPubkey = 'someone'
        ..content = 'bookmarked'
        ..type = NoteType.text
        ..eTagRefs = const []
        ..pTagRefs = const []
        ..tTags = const []
        ..created = DateTime.fromMillisecondsSinceEpoch(1700000001000)
        ..savedAt = DateTime.fromMillisecondsSinceEpoch(1700000002000);
      savedRow.signedNostrEvent = await codec.signRecord(
        kind: MeshEventKinds.savedNote,
        dTag: 'saved1',
        content: SavedNoteBody.forActive(savedRow),
        createdAtSec: 1700000002,
      );

      // Phase 2 kinds — DmConversation / FollowedNote / BlockedUser also flow
      // through Nip77Reconciler, so each row must ship pre-signed. (Phase 6
      // removed LocalHide / 30504 from this list — hide is device-local.)
      final dmConvRow = DmConversationModel()
        ..otherPubkey = otherPubkey
        ..relays = const ['wss://relay'];
      dmConvRow.signedNostrEvent = await codec.signRecord(
        kind: MeshEventKinds.dmConversation,
        dTag: otherPubkey,
        content: DmConversationBody.forActive(dmConvRow),
        createdAtSec: 1700000005,
      );

      final followedUserRow = FollowedUserModel()
        ..pubkeyHex = otherPubkey
        ..followedAt = DateTime.fromMillisecondsSinceEpoch(1700000005000)
        ..lastKind3CreatedAt = DateTime.fromMillisecondsSinceEpoch(
          1700000005000,
        );
      followedUserRow.signedNostrEvent = await codec.signRecord(
        kind: MeshEventKinds.followedUser,
        dTag: otherPubkey,
        content: FollowedUserBody.forActive(followedUserRow),
        createdAtSec: 1700000005,
      );

      final followedRow = FollowedNoteModel()
        ..eventId = 'fnote1'
        ..contentPreview = 'a followed note'
        ..followedAt = DateTime.fromMillisecondsSinceEpoch(1700000004000);
      followedRow.signedNostrEvent = await codec.signRecord(
        kind: MeshEventKinds.followedNote,
        dTag: 'fnote1',
        content: FollowedNoteBody.forActive(followedRow),
        createdAtSec: 1700000006,
      );

      final blockedRow = BlockedUserModel()
        ..pubkeyHex = 'cccc'
        ..blockedAt = DateTime.fromMillisecondsSinceEpoch(1700000004000);
      blockedRow.signedNostrEvent = await codec.signRecord(
        kind: MeshEventKinds.blockedUser,
        dTag: 'cccc',
        content: BlockedUserBody.forActive(blockedRow),
        createdAtSec: 1700000007,
      );

      // Phase 4 kinds — Manas definition (30510) + membership edge (30511).
      // Two separate addressable slots per plan §5 so concurrent adds on two
      // devices can't clobber each other.
      final manasRow = ManasModel()
        ..manasId = 'm-research'
        ..name = 'Research'
        ..description = 'papers I want to remember'
        ..iconName = 'science'
        ..createdAt = DateTime.fromMillisecondsSinceEpoch(1700000004000)
        ..updatedAt = DateTime.fromMillisecondsSinceEpoch(1700000004000);
      manasRow.signedNostrEvent = await codec.signRecord(
        kind: MeshEventKinds.manas,
        dTag: 'm-research',
        content: ManasBody.forActive(manasRow),
        createdAtSec: 1700000009,
      );

      final manasLinkRow = ManasNoteLinkModel()
        ..manasId = 'm-research'
        ..noteId = 'feed1'
        ..addedAt = DateTime.fromMillisecondsSinceEpoch(1700000004500);
      manasLinkRow.signedNostrEvent = await codec.signRecord(
        kind: MeshEventKinds.manasMember,
        dTag: ManasMemberBody.buildDTag('m-research', 'feed1'),
        content: ManasMemberBody.forActive(manasLinkRow),
        createdAtSec: 1700000010,
      );

      // Phase 5 kind — Gana definition (30520). Cursor state stays per-device,
      // so we set nothing on this seed; the body encoder never emits cursor
      // fields anyway.
      final ganaRow = GanaModel()
        ..ganaId = 'g-daily'
        ..name = 'Daily digest'
        ..manasIds = const ['m-research']
        ..taskPrompt = 'summarise notes'
        ..outputType = GanaOutputType.feed
        ..triggerReactive = false
        ..triggerIntervalMinutes = 60
        ..triggerMode = GanaTriggerMode.recurring
        ..maxOutputs = 5
        ..enabled = true
        ..createdAt = DateTime.fromMillisecondsSinceEpoch(1700000004700)
        ..updatedAt = DateTime.fromMillisecondsSinceEpoch(1700000004700);
      ganaRow.signedNostrEvent = await codec.signRecord(
        kind: MeshEventKinds.gana,
        dTag: 'g-daily',
        content: GanaBody.forActive(ganaRow),
        createdAtSec: 1700000011,
      );

      // Seed device A.
      // feed1 is a REAL signed Kind-1 event: SignedNoteSyncScope forwards the raw
      // event verbatim and device B verifies id+sig, so it must be genuinely
      // signed (a fake id/sig would fail `event.isValid()` on receive).
      final feedEvent = Event.from(
        kind: 1,
        tags: const [],
        content: 'a feed note',
        privkey: me.private,
        createdAt: 1700000000,
      );
      await isarA.writeTxn(() async {
        await isarA.noteModels.put(
          NoteModel(
            eventId: feedEvent.id,
            sig: feedEvent.sig,
            authorPubkey: ownPubkey,
            content: 'a feed note',
            type: NoteType.text,
            eTagRefs: const [],
            pTagRefs: const [],
            tTags: const [],
            created: DateTime.fromMillisecondsSinceEpoch(1700000000000),
            rawEventJson: jsonEncode(feedEvent.toJson()),
          ),
        );
        await isarA.savedNoteModels.put(savedRow);
        await isarA.dmConversationModels.put(dmConvRow);
        await isarA.noteModels.put(
          NoteModel(
            eventId: 'dmmsg1',
            sig: '',
            authorPubkey: ownPubkey,
            content: 'a dm',
            kind: 14,
            conversationId: convId,
            type: NoteType.text,
            eTagRefs: const [],
            pTagRefs: [otherPubkey],
            tTags: const [],
            created: DateTime.fromMillisecondsSinceEpoch(1700000003000),
          ),
        );
        await isarA.profileModels.put(
          ProfileModel()
            ..pubkey = otherPubkey
            ..name = 'Bob'
            ..updatedAt = DateTime.fromMillisecondsSinceEpoch(1700000004000)
            ..rawEventJson = kind0EventJson,
        );
        await isarA.followedUserModels.put(followedUserRow);
        await isarA.followedNoteModels.put(followedRow);
        await isarA.blockedUserModels.put(blockedRow);
        await isarA.manasModels.put(manasRow);
        await isarA.manasNoteLinkModels.put(manasLinkRow);
        await isarA.ganaModels.put(ganaRow);
      });

      // Run the REAL Nip77Reconciler over real scopes — mirrors production wiring
      // in `mesh_peer_sessions._startSameIdentitySync`.
      final negScopesA = buildNegentropySyncScopes(
        isar: isarA,
        codec: codec,
        relations: NoteRelationRepositoryImpl(isar: isarA),
        activePubkeyHex: me.public,
      );
      final negScopesB = buildNegentropySyncScopes(
        isar: isarB,
        codec: codec,
        relations: NoteRelationRepositoryImpl(isar: isarB),
        activePubkeyHex: me.public,
      );
      final links = createPairedLinks();
      final sessionA = LinkSession(links.a);
      final sessionB = LinkSession(links.b);
      // Wall-clock guard only — it exists so a wedged reconcile fails instead
      // of hanging the suite, and is NOT an assertion about how fast sync is.
      // 5s was tight enough that a loaded CI runner timed out mid-reconcile
      // (this test drives two real Isar peers across ~10 record scopes plus
      // signing), leaving B empty and failing the first expect with a bare
      // "Expected: not null".
      const kReconcileTimeout = Duration(seconds: 60);
      final reconcilerA = Nip77Reconciler(
        scopes: negScopesA,
        send: sessionA.send,
        timeout: kReconcileTimeout,
      );
      final reconcilerB = Nip77Reconciler(
        scopes: negScopesB,
        send: sessionB.send,
        timeout: kReconcileTimeout,
      );
      sessionA.onAppMessage(reconcilerA.handleMessage);
      sessionB.onAppMessage(reconcilerB.handleMessage);

      await Future.wait([reconcilerA.run(), reconcilerB.run()]);

      // Device B now holds everything A had.
      final feed = await isarB.noteModels
          .where()
          .eventIdEqualTo(feedEvent.id)
          .findFirst();
      expect(feed, isNotNull);
      expect(feed!.authorPubkey, ownPubkey);

      final saved = await isarB.savedNoteModels
          .where()
          .eventIdEqualTo('saved1')
          .findFirst();
      expect(saved, isNotNull);

      final conv = await isarB.dmConversationModels
          .where()
          .otherPubkeyEqualTo(otherPubkey)
          .findFirst();
      expect(conv, isNotNull);
      expect(conv!.id, convId); // deterministic id matches across devices

      final dm = await isarB.noteModels
          .where()
          .eventIdEqualTo('dmmsg1')
          .findFirst();
      expect(dm, isNotNull);
      expect(
        dm!.conversationId,
        convId,
      ); // FK resolves to the synced conversation

      // Unconditional unread row makes synced notes show in the feed banner.
      final unread = await isarB.unreadNoteModels
          .where()
          .eventIdEqualTo(feedEvent.id)
          .findFirst();
      expect(unread, isNotNull);

      // Profile / follows / block scopes.
      final profile = await isarB.profileModels
          .where()
          .pubkeyEqualTo(otherPubkey)
          .findFirst();
      expect(profile, isNotNull);
      expect(profile!.name, 'Bob');
      expect(
        await isarB.followedUserModels
            .where()
            .pubkeyHexEqualTo(otherPubkey)
            .findFirst(),
        isNotNull,
      );
      expect(profile.rawEventJson, isNotNull);
      final followedUser = await isarB.followedUserModels
          .where()
          .pubkeyHexEqualTo(otherPubkey)
          .findFirst();
      expect(followedUser, isNotNull);
      expect(followedUser!.signedNostrEvent, isNotNull);
      expect(
        await isarB.followedNoteModels
            .where()
            .eventIdEqualTo('fnote1')
            .findFirst(),
        isNotNull,
      );
      expect(
        await isarB.blockedUserModels
            .where()
            .pubkeyHexEqualTo('cccc')
            .findFirst(),
        isNotNull,
      );
      // Phase 4 — Manas definition + membership edge both converge.
      final manasB = await isarB.manasModels
          .where()
          .manasIdEqualTo('m-research')
          .findFirst();
      expect(manasB, isNotNull);
      expect(manasB!.name, 'Research');
      expect(manasB.removedAt, isNull);

      final linkB = await isarB.manasNoteLinkModels
          .filter()
          .manasIdEqualTo('m-research')
          .noteIdEqualTo('feed1')
          .findFirst();
      expect(linkB, isNotNull);
      expect(linkB!.removedAt, isNull);

      // Phase 5 — Gana definition converges (cursor stays local — nothing to
      // assert on that side since we never seeded a cursor on device A).
      final ganaB = await isarB.ganaModels
          .where()
          .ganaIdEqualTo('g-daily')
          .findFirst();
      expect(ganaB, isNotNull);
      expect(ganaB!.name, 'Daily digest');
      expect(ganaB.manasIds, const ['m-research']);
      expect(ganaB.enabled, isTrue);
      expect(ganaB.removedAt, isNull);
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );
}
