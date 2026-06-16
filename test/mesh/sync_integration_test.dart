import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/core/enum/note_type.dart';
import 'package:uniun/core/utils/fast_hash.dart';
import 'package:uniun/data/datasources/isar_schemas.dart';
import 'package:uniun/data/models/blocked_user_model.dart';
import 'package:uniun/data/models/dm/dm_conversation_model.dart';
import 'package:uniun/data/models/followed_note_model.dart';
import 'package:uniun/data/models/followed_user_model.dart';
import 'package:uniun/data/models/notes/note_model.dart';
import 'package:uniun/data/models/notes/unread_note_model.dart';
import 'package:uniun/data/models/profile_model.dart';
import 'package:uniun/data/models/saved_note_model.dart';
import 'package:uniun/data/repositories/note_relation_repository_impl.dart';
import 'package:uniun/features/mesh/link/link_session.dart';
import 'package:uniun/features/mesh/sync/trusted_sync_engine.dart';
import 'package:uniun/features/mesh/sync/trusted_sync_scopes.dart';

import 'support/paired_mesh_link.dart';

/// Drives the REAL TrustedSyncEngine over the REAL Isar-backed scopes against two
/// temp Isar instances — the only test that exercises production upsert/writeTxn
/// (the unit tests use in-memory fakes). Validates actual row transfer, the
/// unconditional unread row, and the deterministic DM-conversation remapping.
///
/// Requires the Isar native core; skips gracefully if it can't initialize.
void main() {
  var isarReady = false;
  final temps = <Directory>[];

  setUpAll(() async {
    try {
      await Isar.initializeIsarCore(download: true);
      isarReady = true;
    } catch (e) {
      // No native core / no network — skip the integration assertions.
      // ignore: avoid_print
      print('Isar core unavailable, skipping integration test: $e');
    }
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

  test('two real Isar peers converge notes, saved, DMs + unread rows', () async {
    if (!isarReady) return; // skipped — see setUpAll log

    final isarA = await openIsar('a${temps.length}');
    final isarB = await openIsar('b${temps.length}');
    addTearDown(() async {
      await isarA.close();
      await isarB.close();
    });

    const ownPubkey = 'aaaa'; // same identity on both devices
    final otherPubkey = 'b' * 64;
    final convId = fastHash(otherPubkey);

    // Seed device A.
    await isarA.writeTxn(() async {
      await isarA.noteModels.put(NoteModel(
        eventId: 'feed1',
        sig: 'sig',
        authorPubkey: ownPubkey,
        content: 'a feed note',
        type: NoteType.text,
        eTagRefs: const [],
        pTagRefs: const [],
        tTags: const [],
        created: DateTime.fromMillisecondsSinceEpoch(1700000000000),
      ));
      await isarA.savedNoteModels.put(SavedNoteModel()
        ..eventId = 'saved1'
        ..sig = 'sig'
        ..authorPubkey = 'someone'
        ..content = 'bookmarked'
        ..type = NoteType.text
        ..eTagRefs = const []
        ..pTagRefs = const []
        ..tTags = const []
        ..created = DateTime.fromMillisecondsSinceEpoch(1700000001000)
        ..savedAt = DateTime.fromMillisecondsSinceEpoch(1700000002000));
      await isarA.dmConversationModels.put(DmConversationModel()
        ..otherPubkey = otherPubkey
        ..relays = const ['wss://relay']);
      await isarA.noteModels.put(NoteModel(
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
      ));
      await isarA.profileModels.put(ProfileModel()
        ..pubkey = otherPubkey
        ..name = 'Bob'
        ..updatedAt = DateTime.fromMillisecondsSinceEpoch(1700000004000));
      await isarA.followedUserModels.put(FollowedUserModel()
        ..pubkeyHex = otherPubkey
        ..followedAt = DateTime.fromMillisecondsSinceEpoch(1700000004000));
      await isarA.followedNoteModels.put(FollowedNoteModel()
        ..eventId = 'fnote1'
        ..contentPreview = 'a followed note'
        ..followedAt = DateTime.fromMillisecondsSinceEpoch(1700000004000)
        ..newReferenceCount = 2);
      await isarA.blockedUserModels.put(BlockedUserModel()
        ..pubkeyHex = 'cccc'
        ..blockedAt = DateTime.fromMillisecondsSinceEpoch(1700000004000));
    });

    // Run both engines over real scopes.
    final scopesA = buildTrustedSyncScopes(
      isar: isarA,
      relations: NoteRelationRepositoryImpl(isar: isarA),
    );
    final scopesB = buildTrustedSyncScopes(
      isar: isarB,
      relations: NoteRelationRepositoryImpl(isar: isarB),
    );
    final links = createPairedLinks();
    final sessionA = LinkSession(links.a);
    final sessionB = LinkSession(links.b);
    final engineA = TrustedSyncEngine(scopes: scopesA, send: sessionA.send);
    final engineB = TrustedSyncEngine(scopes: scopesB, send: sessionB.send);
    sessionA.onAppMessage(engineA.handleMessage);
    sessionB.onAppMessage(engineB.handleMessage);

    await Future.wait([engineA.run(), engineB.run()]);

    // Device B now holds everything A had.
    final feed = await isarB.noteModels.where().eventIdEqualTo('feed1').findFirst();
    expect(feed, isNotNull);
    expect(feed!.authorPubkey, ownPubkey);

    final saved =
        await isarB.savedNoteModels.where().eventIdEqualTo('saved1').findFirst();
    expect(saved, isNotNull);

    final conv = await isarB.dmConversationModels
        .where()
        .otherPubkeyEqualTo(otherPubkey)
        .findFirst();
    expect(conv, isNotNull);
    expect(conv!.id, convId); // deterministic id matches across devices

    final dm = await isarB.noteModels.where().eventIdEqualTo('dmmsg1').findFirst();
    expect(dm, isNotNull);
    expect(dm!.conversationId, convId); // FK resolves to the synced conversation

    // Unconditional unread row makes synced notes show in the feed banner.
    final unread =
        await isarB.unreadNoteModels.where().eventIdEqualTo('feed1').findFirst();
    expect(unread, isNotNull);

    // Profile / follows / block scopes.
    expect(
      await isarB.profileModels.where().pubkeyEqualTo(otherPubkey).findFirst(),
      isNotNull,
    );
    expect(
      await isarB.followedUserModels
          .where()
          .pubkeyHexEqualTo(otherPubkey)
          .findFirst(),
      isNotNull,
    );
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
  });
}
