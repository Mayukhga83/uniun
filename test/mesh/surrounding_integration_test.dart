import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:uniun/core/enum/note_type.dart';
import 'package:uniun/data/datasources/isar_schemas.dart';
import 'package:uniun/data/models/notes/note_model.dart';
import 'package:uniun/data/models/profile_model.dart';
import 'package:uniun/data/models/surrounding_note_model.dart';
import 'package:uniun/features/mesh/link/link_session.dart';
import 'package:uniun/features/mesh/link/mesh_peer.dart';
import 'package:uniun/features/mesh/payload/payload_envelope.dart';
import 'package:uniun/features/mesh/router/mesh_router.dart';
import 'package:uniun/features/mesh/surrounding/broadcast_set_builder.dart';
import 'package:uniun/features/mesh/surrounding/surrounding_exchange.dart';
import 'package:uniun/features/mesh/surrounding/surrounding_inbound.dart';

import 'support/paired_mesh_link.dart';

/// Exercises the Surrounding feed end-to-end over real Isar + real secp256k1 keys:
/// genuine broadcast notes propagate (and verify), forged ones are dropped, and
/// our own note is never re-ingested. Skips if the Isar native core is missing.
void main() {
  var isarReady = false;
  final temps = <Directory>[];

  setUpAll(() async {
    try {
      await Isar.initializeIsarCore(download: true);
      isarReady = true;
    } catch (e) {
      // ignore: avoid_print
      print('Isar core unavailable, skipping: $e');
    }
  });

  tearDownAll(() async {
    for (final d in temps) {
      if (await d.exists()) await d.delete(recursive: true);
    }
  });

  Future<Isar> openIsar(String name) async {
    final dir = await Directory.systemTemp.createTemp('uniun_surr_$name');
    temps.add(dir);
    return Isar.open(isarSchemas, directory: dir.path, name: '$name${temps.length}');
  }

  Future<void> waitUntil(Future<bool> Function() cond) async {
    final deadline = DateTime.now().add(const Duration(seconds: 3));
    while (DateTime.now().isBefore(deadline)) {
      if (await cond()) return;
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
  }

  test('a genuine broadcast note reaches the stranger, verified', () async {
    if (!isarReady) return;
    final isarA = await openIsar('a');
    final isarB = await openIsar('b');
    addTearDown(() async {
      await isarA.close();
      await isarB.close();
    });

    final keyA = Keychain.generate();
    final keyB = Keychain.generate();

    final event = Event.from(
      kind: 1,
      content: 'hello surrounding',
      tags: const [],
      privkey: keyA.private,
    );
    await isarA.writeTxn(() async {
      await isarA.noteModels.put(NoteModel(
        eventId: event.id,
        sig: event.sig,
        authorPubkey: keyA.public,
        content: 'hello surrounding',
        kind: 1,
        type: NoteType.text,
        eTagRefs: const [],
        pTagRefs: const [],
        tTags: const [],
        created: DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000),
      ));
      await isarA.profileModels.put(ProfileModel()
        ..pubkey = keyA.public
        ..name = 'Alice'
        ..username = 'alice'
        ..updatedAt = DateTime.fromMillisecondsSinceEpoch(1700000000000));
    });

    final links = createPairedLinks();
    final sA = LinkSession(links.a);
    final sB = LinkSession(links.b);
    final exA = SurroundingExchange(
      send: sA.send,
      broadcastSet: BroadcastSetBuilder(isarA, keyA.public, keyA.private),
    );
    final exB = SurroundingExchange(
      send: sB.send,
      broadcastSet: BroadcastSetBuilder(isarB, keyB.public, keyB.private),
    );
    // Receive via the router; with no other peers there's no forwarding, so this
    // exercises the dedupe + ingest path.
    final routerA = MeshRouter(peers: () => <MeshPeer>[]);
    final routerB = MeshRouter(peers: () => <MeshPeer>[]);
    final inboundA = SurroundingInbound(isarA, keyA.public);
    final inboundB = SurroundingInbound(isarB, keyB.public);
    sA.onAppMessage((m) {
      if (m is EventMessage) routerA.onEvent(keyB.public, inboundA.ingest, m);
    });
    sB.onAppMessage((m) {
      if (m is EventMessage) routerB.onEvent(keyA.public, inboundB.ingest, m);
    });
    await Future.wait([exA.broadcast(), exB.broadcast()]);
    // Both the note and the author's profile arrive as separate async ingests.
    await waitUntil(() async =>
        (await isarB.surroundingNoteModels
                .where()
                .eventIdEqualTo(event.id)
                .findFirst()) !=
            null &&
        (await isarB.profileModels
                .where()
                .pubkeyEqualTo(keyA.public)
                .findFirst()) !=
            null);

    final got = await isarB.surroundingNoteModels
        .where()
        .eventIdEqualTo(event.id)
        .findFirst();
    expect(got, isNotNull);
    expect(got!.authorPubkey, keyA.public);
    // The "Nearby" tag is localized at the presentation layer (SurroundingFeedPage),
    // not baked into the data-layer model — so toDomain() leaves sourceLabel null.
    expect(got.toDomain().sourceLabel, isNull);
    // We never store our own broadcast.
    expect(await isarA.surroundingNoteModels.count(), 0);

    // The author's kind-0 profile rode along, so names/avatars can render.
    final prof =
        await isarB.profileModels.where().pubkeyEqualTo(keyA.public).findFirst();
    expect(prof, isNotNull);
    expect(prof!.name, 'Alice');
    expect(prof.username, 'alice');
  });

  test('a forged note (tampered content) is rejected', () async {
    if (!isarReady) return;
    final isarB = await openIsar('fb');
    addTearDown(() async => isarB.close());
    final keyA = Keychain.generate();
    final keyB = Keychain.generate();

    final event = Event.from(
      kind: 1,
      content: 'real',
      tags: const [],
      privkey: keyA.private,
    );
    final forged = Map<String, dynamic>.from(event.toJson())
      ..['content'] = 'TAMPERED'; // id no longer matches → invalid

    await SurroundingInbound(isarB, keyB.public).ingest(forged);
    expect(await isarB.surroundingNoteModels.count(), 0);
  });

  test('our own note is not ingested as surrounding', () async {
    if (!isarReady) return;
    final isarA = await openIsar('ob');
    addTearDown(() async => isarA.close());
    final keyA = Keychain.generate();

    final event = Event.from(
      kind: 1,
      content: 'mine',
      tags: const [],
      privkey: keyA.private,
    );
    await SurroundingInbound(isarA, keyA.public).ingest(event.toJson());
    expect(await isarA.surroundingNoteModels.count(), 0);
  });
}
