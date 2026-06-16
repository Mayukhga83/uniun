import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../link/mesh_link.dart';
import '../mesh_transport.dart';
import 'lan_link.dart';
import 'lan_server.dart';

/// The LAN transport's data path: it owns the TCP [LanServer] (inbound) and dials
/// peers (outbound). Discovery (mDNS browse/advertise via bonsoir) is owned by
/// [MeshEngineHost], which now runs in the same headless engine and calls [dial]
/// directly on each peer it decides to connect to — there is no longer a
/// cross-isolate `MeshDiscovery` hand-off. Both inbound and outbound connections
/// surface as connected [MeshLink]s on [links], which the host wires into the
/// negotiator.
class LanConnector implements MeshTransport {
  LanConnector();

  @override
  TransportKind get kind => TransportKind.lan;

  final LanServer _server = LanServer();
  final _links = StreamController<MeshLink>.broadcast();
  final List<StreamSubscription<dynamic>> _subs = [];

  /// Newly connected links (inbound + outbound). One identity proof runs per link.
  @override
  Stream<MeshLink> get links => _links.stream;

  /// Binds the inbound server. Returns the OS-assigned server port so the caller
  /// can advertise it over mDNS (covariant override of [MeshTransport.start]).
  @override
  Future<int> start() async {
    await _server.start();
    _subs.add(_server.connections.listen((socket) {
      if (!_links.isClosed) _links.add(LanLink.fromSocket(socket));
    }));
    return _server.port;
  }

  /// Opens an outbound TCP connection to a discovered peer and surfaces it as a
  /// [MeshLink]. Failures (commonly a stale mDNS record for a peer that has gone
  /// away) are handled, not fatal — the caller has already deduped the dial.
  Future<void> dial(String host, int port) async {
    try {
      final socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 5),
      );
      if (_links.isClosed) {
        socket.destroy();
        return;
      }
      _links.add(LanLink.fromSocket(socket));
    } catch (e) {
      debugPrint('MESH/LAN: dial to $host:$port skipped: $e');
    }
  }

  @override
  Future<void> stop() async {
    for (final sub in _subs) {
      await sub.cancel();
    }
    _subs.clear();
    await _server.stop();
    if (!_links.isClosed) await _links.close();
  }
}
