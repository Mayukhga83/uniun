import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/data/repositories/note_relation_repository_impl.dart';

import '../link/mesh_peer.dart';
import '../payload/payload_envelope.dart';
import '../router/mesh_router.dart';
import '../security/same_identity_cipher.dart';
import '../surrounding/broadcast_set_builder.dart';
import '../surrounding/surrounding_exchange.dart';
import '../surrounding/surrounding_inbound.dart';
import '../sync/trusted_sync_engine.dart';
import '../sync/trusted_sync_scopes.dart';

/// Owns the per-peer sessions started after a successful identity handshake. Split
/// out of [MeshEngineHost] (which owns transports, discovery, the negotiator, and
/// lifecycle) so the host stays a thin coordinator and this logic is testable in
/// isolation.
///
///   * **same-identity** peer → a kept [TrustedSyncEngine] (AEAD-sealed by [_cipher];
///     a local change re-runs a round via `resync()` on the same session).
///   * **stranger / mesh** peer → a kept [SurroundingExchange] (delta broadcast) whose
///     inbound events flow through the shared [MeshRouter] (verify → store → relay).
///
/// Both maps are keyed by peer pubkey; a kept session lets a local content change
/// re-broadcast just the delta / re-run a round instead of rebuilding.
class MeshPeerSessions {
  MeshPeerSessions({
    required Isar isar,
    required String pubkeyHex,
    required String privkeyHex,
    required NoteRelationRepositoryImpl relations,
    required SameIdentityCipher? cipher,
    required MeshRouter router,
  })  : _isar = isar,
        _pubkeyHex = pubkeyHex,
        _privkeyHex = privkeyHex,
        _relations = relations,
        _cipher = cipher,
        _router = router;

  final Isar _isar;
  final String _pubkeyHex;
  final String _privkeyHex;
  final NoteRelationRepositoryImpl _relations;
  final SameIdentityCipher? _cipher;
  final MeshRouter _router;

  final Map<String, SurroundingExchange> _surrounding = {};
  final Map<String, TrustedSyncEngine> _sync = {};

  /// Start (or restart, on a link upgrade) the session for a freshly-proven peer.
  void onPeerAdded(MeshPeer peer) {
    switch (peer.mode) {
      case PeerMode.sameIdentity:
        _startTrustedSync(peer);
      case PeerMode.stranger:
      case PeerMode.mesh:
        _startSurroundingExchange(peer);
    }
  }

  /// Tear down a dropped peer's session.
  void onPeerRemoved(String pubkey) {
    _surrounding.remove(pubkey);
    _sync.remove(pubkey)?.dispose();
  }

  /// Re-reconcile / re-broadcast to every connected peer (the host calls this,
  /// debounced, on a local content change). Idempotent.
  void resyncAll(Iterable<MeshPeer> peers) {
    for (final peer in peers) {
      switch (peer.mode) {
        case PeerMode.sameIdentity:
          final engine = _sync[peer.pubkey];
          if (engine != null) {
            unawaited(engine.resync());
          } else {
            _startTrustedSync(peer);
          }
        case PeerMode.stranger:
        case PeerMode.mesh:
          final exchange = _surrounding[peer.pubkey];
          if (exchange != null) {
            unawaited(exchange.broadcast());
          } else {
            _startSurroundingExchange(peer);
          }
      }
    }
  }

  /// Exchanges public broadcast notes with a nearby stranger (the Surrounding feed):
  /// pushes our own + saved notes (outbound), and routes theirs through the multi-hop
  /// [MeshRouter] (verify → store → relay to other peers).
  void _startSurroundingExchange(MeshPeer peer) {
    final exchange = SurroundingExchange(
      send: peer.activeSession.send,
      broadcastSet: BroadcastSetBuilder(_isar, _pubkeyHex, _privkeyHex),
    );
    _surrounding[peer.pubkey] = exchange; // fresh session → fresh dedup state
    // Per-link ingestor (carries its own rate limit); the shared router dedupes +
    // relays across all peers.
    final inbound = SurroundingInbound(_isar, _pubkeyHex);
    peer.activeSession.onAppMessage((msg) {
      if (msg is EventMessage) {
        unawaited(_router.onEvent(peer.pubkey, inbound.ingest, msg));
      }
    });
    unawaited(exchange.broadcast().catchError(
          (Object e) => debugPrint('MESH: surrounding exchange error: $e'),
        ));
  }

  /// Reconciles all content scopes with a proven same-identity peer over its link.
  ///
  /// The channel is AEAD-encrypted ([_cipher]): the engine's sync messages — which
  /// carry decrypted DM/profile rows — are sealed before send and opened on receipt,
  /// so they're never cleartext on the wire. Both devices derive the same key from
  /// the shared nsec, so the seal/open are symmetric. The engine is kept so a local
  /// change can `resync()` this session rather than rebuild it.
  void _startTrustedSync(MeshPeer peer) {
    // Drop any engine bound to a now-stale session (reconnect / link upgrade).
    _sync.remove(peer.pubkey)?.dispose();
    final cipher = _cipher;
    final session = peer.activeSession;
    final engine = TrustedSyncEngine(
      scopes: buildTrustedSyncScopes(isar: _isar, relations: _relations),
      send: cipher == null
          ? session.send
          : (m) => unawaited(cipher
              .seal(m.encode())
              .then((sealed) => session.send(EncryptedMessage(sealed)))),
    );
    _sync[peer.pubkey] = engine;
    session.onAppMessage((m) {
      if (cipher == null) {
        engine.handleMessage(m);
      } else if (m is EncryptedMessage) {
        unawaited(cipher.open(m.payload).then((inner) {
          if (inner == null) return; // auth failure — drop
          final decoded = MeshMessage.decode(inner);
          if (decoded != null) engine.handleMessage(decoded);
        }));
      }
    });
    unawaited(engine.run().catchError(
          (Object e) => debugPrint(
              'MESH: sync error with ${peer.pubkey.substring(0, 8)}…: $e'),
        ));
  }

  /// Drops all sessions (called on engine teardown).
  void dispose() {
    for (final engine in _sync.values) {
      engine.dispose();
    }
    _sync.clear();
    _surrounding.clear();
  }
}
