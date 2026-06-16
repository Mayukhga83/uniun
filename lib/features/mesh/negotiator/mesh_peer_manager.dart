import 'dart:async';

import '../handshake/identity_proof.dart';
import '../link/link_session.dart';
import '../link/mesh_link.dart';
import '../link/mesh_peer.dart';
import '../mesh_constants.dart';

enum MeshPeerChange { added, linkUpgraded, removed }

class MeshPeerEvent {
  MeshPeerEvent(this.change, this.peer);
  final MeshPeerChange change;
  final MeshPeer peer;
}

/// Owns the set of proven peers across all transports. Transports hand it freshly
/// connected [MeshLink]s via [onLinkConnected]; it runs the signed-nonce identity
/// proof, then registers a new [MeshPeer] or, if the same Nostr pubkey is already
/// known on another transport, keeps whichever link is preferred
/// ([TransportKind.preference]) and closes the redundant one. Peer lifecycle is
/// published on [events] for the sync/broadcast layers to react to.
///
/// v1 simplification: a peer holds only its single active link (no fallback set).
/// If that link drops, the peer is removed and transports re-discover it.
class MeshPeerManager {
  MeshPeerManager({
    required MeshSigner signer,
    Duration handshakeTimeout = kMeshHandshakeTimeout,
  })  : _signer = signer,
        _handshakeTimeout = handshakeTimeout;

  final MeshSigner _signer;
  final Duration _handshakeTimeout;

  final Map<String, MeshPeer> _peers = {};
  final _events = StreamController<MeshPeerEvent>.broadcast();

  Stream<MeshPeerEvent> get events => _events.stream;
  Iterable<MeshPeer> get peers => _peers.values;
  MeshPeer? peerFor(String pubkey) => _peers[pubkey];

  /// Wraps [link] in a [LinkSession], runs the identity proof over it, and
  /// registers/updates the peer. Returns the resolved [MeshPeer], or null if the
  /// handshake failed (the session/link is closed). The session is kept on the
  /// peer so the sync/broadcast layers can use it after the handshake.
  Future<MeshPeer?> onLinkConnected(MeshLink link) async {
    final session = LinkSession(link);
    final proof = await IdentityProof(_signer, timeout: _handshakeTimeout)
        .negotiate(hellos: session.hellos, send: session.send);
    if (proof == null) {
      await session.close();
      return null;
    }

    final existing = _peers[proof.peerPubkey];
    if (existing == null) {
      final peer = MeshPeer(
        pubkey: proof.peerPubkey,
        mode: proof.mode,
        activeSession: session,
      );
      _peers[peer.pubkey] = peer;
      _watchDisconnect(session, peer.pubkey);
      _emit(MeshPeerEvent(MeshPeerChange.added, peer));
      return peer;
    }

    existing.mode = proof.mode;
    // A link at >= the current transport's preference replaces it. The "==" case
    // is a reconnect (same transport — e.g. the peer restarted): the existing link
    // is likely stale (we may not have processed its drop yet), so the fresh
    // handshake wins. Strictly-inferior links are dropped.
    final replaces = link.transportKind.preference >=
        existing.activeLink.transportKind.preference;
    if (replaces) {
      final old = existing.activeSession;
      existing.activeSession = session;
      _watchDisconnect(session, existing.pubkey);
      await old.close();
      _emit(MeshPeerEvent(MeshPeerChange.linkUpgraded, existing));
    } else {
      await session.close();
    }
    return existing;
  }

  /// Removes the peer when its active [session]'s link drops — nothing else calls
  /// [onLinkDisconnected] in production. No-ops if the session has since been
  /// replaced (e.g. by a reconnect), so closing a stale link doesn't evict the peer.
  void _watchDisconnect(LinkSession session, String pubkey) {
    late final StreamSubscription<MeshLinkState> sub;
    sub = session.link.states.listen((state) {
      if (state != MeshLinkState.disconnected) return;
      unawaited(sub.cancel());
      final peer = _peers[pubkey];
      if (peer != null && identical(peer.activeSession, session)) {
        _peers.remove(pubkey);
        _emit(MeshPeerEvent(MeshPeerChange.removed, peer));
      }
    });
  }

  /// Called by a transport when one of its links drops. Removes the peer if the
  /// dropped link was its active link.
  void onLinkDisconnected(MeshLink link) {
    String? removedKey;
    for (final entry in _peers.entries) {
      if (identical(entry.value.activeLink, link)) {
        removedKey = entry.key;
        break;
      }
    }
    if (removedKey == null) return;
    final peer = _peers.remove(removedKey)!;
    _emit(MeshPeerEvent(MeshPeerChange.removed, peer));
  }

  void _emit(MeshPeerEvent e) {
    if (!_events.isClosed) _events.add(e);
  }

  Future<void> dispose() async {
    for (final p in _peers.values) {
      await p.activeSession.close();
    }
    _peers.clear();
    await _events.close();
  }
}
