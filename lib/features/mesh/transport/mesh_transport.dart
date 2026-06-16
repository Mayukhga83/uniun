import '../link/mesh_link.dart';

/// A discovery+connection source for one transport (LAN, BLE, future Multipeer). It
/// advertises us and discovers peers; every freshly-established connection (inbound
/// or outbound) surfaces as a connected [MeshLink] on [links]. `MeshEngineHost` wires
/// each source's [links] into the peer negotiator the **same** way, so adding a
/// transport is one more entry in the engine's transport list and nothing above the
/// [MeshLink] seam changes.
///
/// The source never deals with identity, sync, or features itself — the pubkey is
/// exchanged in the post-connect handshake and never advertised, so it isn't passed
/// here. Implemented by `LanConnector` and `BleConnector`.
abstract class MeshTransport {
  TransportKind get kind;

  /// Newly connected links. The negotiator runs the identity proof on each.
  Stream<MeshLink> get links;

  /// Begins advertising/discovery + any inbound listener. `LanConnector` overrides
  /// the return with its bound server port (covariant) so the engine can advertise it.
  Future<void> start();

  /// Stops advertising/discovery and tears down connections owned by this transport.
  Future<void> stop();
}
