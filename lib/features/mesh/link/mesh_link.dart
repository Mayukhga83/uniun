import 'dart:typed_data';

/// The transport carrying a [MeshLink]. Ordered by preference: when a peer is
/// reachable on several transports at once, the negotiator keeps the one with the
/// highest [preference] (LAN is fast + cross-platform, BLE is slow but universal).
enum TransportKind {
  lan,
  multipeer,
  ble,
  relay;

  /// Higher = preferred. Used by the negotiator to upgrade a peer's active link.
  int get preference => switch (this) {
        TransportKind.lan => 3,
        TransportKind.multipeer => 2,
        TransportKind.ble => 1,
        TransportKind.relay => 0,
      };
}

enum MeshLinkState { connecting, connected, disconnected }

/// A reliable, ordered, message-framed channel to a single nearby peer over one
/// transport. It knows nothing about Nostr or sync — it just moves whole
/// application messages. Each item emitted on [messages] is exactly one complete
/// message that the remote passed to its [send] (the transport owns framing, e.g.
/// length-prefixing for a TCP socket).
///
/// Every transport (LAN socket, BLE native bridge, Multipeer) implements this so
/// the application layer — identity proof, sync engine, the feeds — is identical
/// regardless of which transport won. This is the seam the whole feature rides on.
abstract class MeshLink {
  /// Transport-local identifier for this connection (e.g. a socket "host:port" or
  /// a BLE peripheral id). Stable for the link's lifetime. This is NOT the peer's
  /// Nostr identity — that is proven by the handshake and tracked by `MeshPeer`.
  String get linkId;

  TransportKind get transportKind;

  /// Whole inbound application messages, one per emitted item.
  Stream<Uint8List> get messages;

  /// Connection-state transitions.
  Stream<MeshLinkState> get states;

  MeshLinkState get state;
  bool get isConnected;

  /// Sends one complete application message. The transport frames it so the peer
  /// receives exactly these bytes as a single [messages] item.
  void send(Uint8List message);

  /// Closes the link and releases transport resources.
  Future<void> close();
}
