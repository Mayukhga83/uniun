import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/features/mesh/link/link_session.dart';
import 'package:uniun/features/mesh/link/mesh_peer.dart';
import 'package:uniun/features/mesh/payload/payload_envelope.dart';
import 'package:uniun/features/mesh/router/mesh_router.dart';

import 'support/paired_mesh_link.dart';

/// Unit-tests the multi-hop gossip relay: TTL decrement, loop/dedup prevention, and
/// peer exclusion (the source and same-identity peers). The ingest step is faked, so
/// no Isar is needed.
void main() {
  // A fake peer whose forwarded messages we can observe (decoded off the far end of
  // a paired in-memory link).
  ({MeshPeer peer, List<EventMessage> got}) makePeer(
    String pubkey,
    PeerMode mode,
  ) {
    final links = createPairedLinks();
    final got = <EventMessage>[];
    links.b.messages.listen((bytes) {
      final m = MeshMessage.decode(bytes);
      if (m is EventMessage) got.add(m);
    });
    return (
      peer: MeshPeer(
        pubkey: pubkey,
        mode: mode,
        activeSession: LinkSession(links.a),
      ),
      got: got,
    );
  }

  Map<String, dynamic> event(String id) => {'id': id, 'content': 'x'};
  Future<bool> accept(Map<String, dynamic> _) async => true;
  Future<bool> reject(Map<String, dynamic> _) async => false;

  test('forwards to other stranger/mesh peers with ttl-1, excluding source + '
      'same-identity', () async {
    final a = makePeer('A', PeerMode.stranger); // the source, also in the peer set
    final b = makePeer('B', PeerMode.stranger);
    final c = makePeer('C', PeerMode.mesh);
    final d = makePeer('D', PeerMode.sameIdentity);
    final router =
        MeshRouter(peers: () => [a.peer, b.peer, c.peer, d.peer]);

    await router.onEvent('A', accept, EventMessage(event('e1'), ttl: 3));
    await Future<void>.delayed(Duration.zero);

    expect(b.got.map((e) => e.ttl).toList(), [2]); // relayed, ttl decremented
    expect(c.got.map((e) => e.ttl).toList(), [2]);
    expect(d.got, isEmpty); // same-identity never gossiped to
    expect(a.got, isEmpty); // source never echoed back
  });

  test('dedupes by event id — a re-seen event is not relayed again', () async {
    final b = makePeer('B', PeerMode.stranger);
    final router = MeshRouter(peers: () => [b.peer]);

    await router.onEvent('A', accept, EventMessage(event('dup'), ttl: 3));
    await router.onEvent('X', accept, EventMessage(event('dup'), ttl: 3));
    await Future<void>.delayed(Duration.zero);

    expect(b.got.length, 1);
  });

  test('does not forward once ttl is exhausted', () async {
    final b = makePeer('B', PeerMode.stranger);
    final router = MeshRouter(peers: () => [b.peer]);

    await router.onEvent('A', accept, EventMessage(event('t0'), ttl: 0));
    await Future<void>.delayed(Duration.zero);

    expect(b.got, isEmpty);
  });

  test('does not forward an event the ingestor rejected', () async {
    final b = makePeer('B', PeerMode.stranger);
    final router = MeshRouter(peers: () => [b.peer]);

    await router.onEvent('A', reject, EventMessage(event('bad'), ttl: 3));
    await Future<void>.delayed(Duration.zero);

    expect(b.got, isEmpty);
  });
}
