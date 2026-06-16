import 'dart:collection';

import '../link/mesh_peer.dart';
import '../mesh_constants.dart';
import '../payload/payload_envelope.dart';

/// Multi-hop gossip relay for public signed events (the Surrounding feed + general
/// mesh). It turns the point-to-point exchange into a flood: a note hops A → B → C
/// beyond direct range, while each event is processed and relayed **at most once**.
///
/// For an inbound [EventMessage] from a peer it:
///   1. dedupes by event id (a bounded seen-set — the loop/amplification guard),
///   2. verifies + stores it via the link's [ingest] (a `SurroundingInbound.ingest`),
///   3. if it was a valid public event AND its TTL isn't exhausted, FORWARDS it to
///      every *other* stranger/mesh peer with `ttl - 1`.
///
/// Same-identity peers are never gossiped to (their content rides the trusted sync),
/// and the source is never echoed back.
class MeshRouter {
  MeshRouter({required Iterable<MeshPeer> Function() peers}) : _peers = peers;

  final Iterable<MeshPeer> Function() _peers;

  /// Event ids already processed. Bounded FIFO: an evicted-then-reseen id is at
  /// worst re-stored (idempotent) and re-relayed with the same TTL budget, which
  /// still terminates — so the cap trades a little redundant traffic for bounded
  /// memory, never a loop.
  static const int _seenCap = kMeshRouterSeenCap;
  final Set<String> _seen = {};
  final Queue<String> _seenOrder = ListQueue<String>();

  /// Handles one inbound event that arrived from [fromPubkey] over its link.
  /// [ingest] is that link's per-peer ingestor (`SurroundingInbound.ingest`, which
  /// carries its own rate limit) — it verifies/stores and returns whether the event
  /// is valid + worth relaying.
  Future<void> onEvent(
    String fromPubkey,
    Future<bool> Function(Map<String, dynamic> event) ingest,
    EventMessage msg,
  ) async {
    final id = msg.event['id'] as String?;
    if (id == null || !_markSeen(id)) return; // unknown id, or already handled
    if (await ingest(msg.event) && msg.ttl > 0) _forward(fromPubkey, msg);
  }

  void _forward(String fromPubkey, EventMessage msg) {
    final relayed = EventMessage(msg.event, ttl: msg.ttl - 1);
    for (final peer in _peers()) {
      if (peer.pubkey == fromPubkey) continue; // never echo to the source
      if (peer.mode == PeerMode.sameIdentity) continue; // not over trusted sync
      peer.activeSession.send(relayed);
    }
  }

  /// Records [id] as seen; returns false if it already was (a duplicate/loop).
  bool _markSeen(String id) {
    if (!_seen.add(id)) return false;
    _seenOrder.add(id);
    if (_seenOrder.length > _seenCap) {
      _seen.remove(_seenOrder.removeFirst());
    }
    return true;
  }
}
