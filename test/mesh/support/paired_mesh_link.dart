import 'dart:async';
import 'dart:typed_data';

import 'package:uniun/features/mesh/link/mesh_link.dart';

/// Two in-memory [MeshLink] ends wired back-to-back: bytes sent on one surface as
/// a single `messages` item on the other. Used to drive handshake/sync logic in
/// unit tests without any real transport.
({MeshLink a, MeshLink b}) createPairedLinks({
  TransportKind transport = TransportKind.lan,
}) {
  // Single-subscription (not broadcast): buffers messages sent before the peer
  // subscribes, matching a real socket stream. Each end has exactly one demux
  // listener in production.
  final aIn = StreamController<Uint8List>();
  final bIn = StreamController<Uint8List>();
  final a = _PairedEnd('a', transport, inbound: aIn, peerInbound: bIn);
  final b = _PairedEnd('b', transport, inbound: bIn, peerInbound: aIn);
  return (a: a, b: b);
}

class _PairedEnd implements MeshLink {
  _PairedEnd(
    this.linkId,
    this.transportKind, {
    required StreamController<Uint8List> inbound,
    required StreamController<Uint8List> peerInbound,
  })  : _inbound = inbound,
        _peerInbound = peerInbound;

  @override
  final String linkId;
  @override
  final TransportKind transportKind;

  final StreamController<Uint8List> _inbound;
  final StreamController<Uint8List> _peerInbound;
  final _states = StreamController<MeshLinkState>.broadcast();

  @override
  Stream<Uint8List> get messages => _inbound.stream;

  @override
  Stream<MeshLinkState> get states => _states.stream;

  @override
  MeshLinkState get state =>
      _inbound.isClosed ? MeshLinkState.disconnected : MeshLinkState.connected;

  @override
  bool get isConnected => !_inbound.isClosed;

  @override
  void send(Uint8List message) {
    if (!_peerInbound.isClosed) _peerInbound.add(message);
  }

  @override
  Future<void> close() async {
    if (!_states.isClosed) {
      _states.add(MeshLinkState.disconnected);
      await _states.close();
    }
    if (!_inbound.isClosed) await _inbound.close();
  }
}
