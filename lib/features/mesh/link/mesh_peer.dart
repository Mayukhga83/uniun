import 'link_session.dart';
import 'mesh_link.dart';

/// How a connected peer is treated, decided by the signed-nonce identity proof.
enum PeerMode {
  /// Proven to control the SAME Nostr identity as us → trusted full reconciliation
  /// of all our content collections.
  sameIdentity,

  /// A different but signature-verified identity → exchange the broadcast
  /// (surrounding) set only.
  stranger,

  /// Identity not (yet) proven → general mesh relay of signed events only.
  mesh,
}

/// A nearby peer keyed by its proven Nostr pubkey, possibly reachable over several
/// transports at once. The negotiator dedupes by [pubkey] and keeps the best
/// available [activeSession] (highest [TransportKind.preference]).
class MeshPeer {
  MeshPeer({
    required this.pubkey,
    required this.mode,
    required this.activeSession,
  });

  /// Proven Nostr pubkey (hex) — the cross-transport identity key.
  final String pubkey;

  /// Resolved from the identity proof; may be upgraded as more is learned.
  PeerMode mode;

  /// The demuxed session over the currently chosen link. The sync/broadcast layers
  /// use this to send and to receive post-handshake app messages.
  LinkSession activeSession;

  /// The underlying link of the active session (transport + lifecycle).
  MeshLink get activeLink => activeSession.link;
}
