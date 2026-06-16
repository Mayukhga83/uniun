import 'package:isar_community/isar.dart';

part 'mesh_peer_state_model.g.dart';

/// Live set of currently-connected mesh peers, maintained by the mesh isolate.
/// Presence of a row means connected; the row is inserted when the negotiator
/// proves a peer and deleted when its link drops. The main isolate watches the row
/// count to drive the Settings connected-peer indicator — this replaces the
/// in-memory `ValueNotifier` that could not cross the isolate boundary.
@Collection(ignore: {'copyWith'})
@Name('MeshPeerState')
class MeshPeerStateModel {
  Id id = Isar.autoIncrement;

  /// Proven Nostr pubkey (hex) — the cross-transport identity key. Unique so a
  /// link upgrade (same peer, better transport) replaces rather than duplicates.
  @Index(unique: true, replace: true)
  late String pubkeyHex;

  /// `PeerMode` name: sameIdentity | stranger | mesh.
  late String mode;

  /// Active `TransportKind` name: lan | multipeer | ble | relay.
  late String transportKind;

  @Index()
  late DateTime connectedAt;
}
