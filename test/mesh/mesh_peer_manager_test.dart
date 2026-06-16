import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/features/mesh/handshake/identity_proof.dart';
import 'package:uniun/features/mesh/link/mesh_link.dart';
import 'package:uniun/features/mesh/link/mesh_peer.dart';
import 'package:uniun/features/mesh/negotiator/mesh_peer_manager.dart';

import 'support/fake_signer.dart';
import 'support/paired_mesh_link.dart';

/// Drives the peer's end of the handshake so [MeshPeerManager.onLinkConnected]
/// (running on the other end) can complete.
Future<void> _peerAnswers(MeshLink end, String pubkey, String seed) =>
    IdentityProof(FakeSigner(pubkey, nonceSeed: seed)).run(end);

void main() {
  test('registers a stranger peer after a successful handshake', () async {
    final manager = MeshPeerManager(signer: FakeSigner('a' * 64, nonceSeed: 'A'));
    final links = createPairedLinks();
    final peerSide = _peerAnswers(links.b, 'b' * 64, 'B');
    final peer = await manager.onLinkConnected(links.a);
    await peerSide;

    expect(peer, isNotNull);
    expect(peer!.pubkey, 'b' * 64);
    expect(peer.mode, PeerMode.stranger);
    expect(manager.peers.length, 1);
    expect(manager.peerFor('b' * 64), same(peer));
  });

  test('same-identity peer resolves sameIdentity', () async {
    final pub = 'a' * 64;
    final manager = MeshPeerManager(signer: FakeSigner(pub, nonceSeed: 'A'));
    final links = createPairedLinks();
    final peerSide = _peerAnswers(links.b, pub, 'B');
    final peer = await manager.onLinkConnected(links.a);
    await peerSide;

    expect(peer!.mode, PeerMode.sameIdentity);
  });

  test('failed handshake → no peer registered, link closed', () async {
    final manager = MeshPeerManager(
      signer: FakeSigner('a' * 64),
      handshakeTimeout: const Duration(milliseconds: 150),
    );
    final links = createPairedLinks(); // peer end stays silent
    final peer = await manager.onLinkConnected(links.a);

    expect(peer, isNull);
    expect(manager.peers, isEmpty);
    expect(links.a.isConnected, isFalse);
  });

  test('dedupe by pubkey + upgrade BLE → LAN, old link closed', () async {
    final manager = MeshPeerManager(signer: FakeSigner('a' * 64, nonceSeed: 'A'));
    final pubB = 'b' * 64;

    final ble = createPairedLinks(transport: TransportKind.ble);
    final bleSide = _peerAnswers(ble.b, pubB, 'B1');
    final p1 = await manager.onLinkConnected(ble.a);
    await bleSide;
    expect(p1!.activeLink.transportKind, TransportKind.ble);
    expect(manager.peers.length, 1);

    final lan = createPairedLinks(transport: TransportKind.lan);
    final lanSide = _peerAnswers(lan.b, pubB, 'B2');
    final p2 = await manager.onLinkConnected(lan.a);
    await lanSide;

    expect(identical(p1, p2), isTrue); // same MeshPeer, deduped by pubkey
    expect(p2!.activeLink.transportKind, TransportKind.lan); // upgraded
    expect(manager.peers.length, 1);
    expect(ble.a.isConnected, isFalse); // old BLE link closed
  });

  test('inferior transport is dropped, active link unchanged', () async {
    final manager = MeshPeerManager(signer: FakeSigner('a' * 64, nonceSeed: 'A'));
    final pubB = 'b' * 64;

    final lan = createPairedLinks(transport: TransportKind.lan);
    final lanSide = _peerAnswers(lan.b, pubB, 'B1');
    await manager.onLinkConnected(lan.a);
    await lanSide;

    final ble = createPairedLinks(transport: TransportKind.ble);
    final bleSide = _peerAnswers(ble.b, pubB, 'B2');
    final p2 = await manager.onLinkConnected(ble.a);
    await bleSide;

    expect(p2!.activeLink.transportKind, TransportKind.lan); // unchanged
    expect(ble.a.isConnected, isFalse); // redundant BLE link dropped
  });

  test('same-transport reconnect replaces the stale link + re-emits', () async {
    final manager = MeshPeerManager(signer: FakeSigner('a' * 64, nonceSeed: 'A'));
    final pubB = 'b' * 64;
    final events = <MeshPeerEvent>[];
    final sub = manager.events.listen(events.add);

    final c1 = createPairedLinks(transport: TransportKind.lan);
    final s1 = _peerAnswers(c1.b, pubB, 'B1');
    final p1 = await manager.onLinkConnected(c1.a);
    await s1;
    expect(manager.peers.length, 1);

    // Peer reconnects over a fresh lan link (e.g. it restarted).
    final c2 = createPairedLinks(transport: TransportKind.lan);
    final s2 = _peerAnswers(c2.b, pubB, 'B2');
    final p2 = await manager.onLinkConnected(c2.a);
    await s2;

    expect(identical(p1, p2), isTrue);
    expect(manager.peers.length, 1);
    expect(identical(p2!.activeSession.link, c2.a), isTrue); // fresh link active
    expect(c1.a.isConnected, isFalse); // stale link closed
    expect(events.map((e) => e.change),
        containsAllInOrder([MeshPeerChange.added, MeshPeerChange.linkUpgraded]));
    await sub.cancel();
  });

  test('active-link drop removes the peer via the state watcher', () async {
    final manager = MeshPeerManager(signer: FakeSigner('a' * 64, nonceSeed: 'A'));
    final events = <MeshPeerEvent>[];
    final sub = manager.events.listen(events.add);

    final c = createPairedLinks();
    final s = _peerAnswers(c.b, 'b' * 64, 'B');
    final peer = await manager.onLinkConnected(c.a);
    await s;
    expect(manager.peers.length, 1);

    // The active link drops — the watcher should evict the peer.
    await peer!.activeSession.link.close();
    await Future<void>.delayed(Duration.zero);

    expect(manager.peers, isEmpty);
    expect(events.map((e) => e.change), contains(MeshPeerChange.removed));
    await sub.cancel();
  });

  test('disconnect of active link removes the peer + emits event', () async {
    final manager = MeshPeerManager(signer: FakeSigner('a' * 64, nonceSeed: 'A'));
    final events = <MeshPeerEvent>[];
    final sub = manager.events.listen(events.add);

    final links = createPairedLinks();
    final peerSide = _peerAnswers(links.b, 'b' * 64, 'B');
    final peer = await manager.onLinkConnected(links.a);
    await peerSide;
    expect(manager.peers.length, 1);

    manager.onLinkDisconnected(peer!.activeLink);
    await Future<void>.delayed(Duration.zero); // let broadcast deliver

    expect(manager.peers, isEmpty);
    expect(
      events.map((e) => e.change),
      containsAllInOrder([MeshPeerChange.added, MeshPeerChange.removed]),
    );
    await sub.cancel();
  });
}
