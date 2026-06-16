import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../link/mesh_link.dart';
import '../mesh_transport.dart';
import 'ble_link.dart';

/// The BLE transport's data path inside the mesh engine — the analogue of
/// `LanConnector`. It drives the native BLE layer over two channels:
///   * a [MethodChannel] `in.uniun.app/ble` — `start` / `stop` / `send` / `disconnect`,
///   * an [EventChannel] `in.uniun.app/ble/events` — `peerUp` / `peerDown` / `message`,
/// and turns each connected BLE peer into a [BleLink] on [links], which
/// `MeshEngineHost` wires into the negotiator exactly like a LAN link.
///
/// Native owns discovery, connection, dial arbitration and MTU fragmentation, so
/// this class never touches the radio: `peerUp` makes a link, `message` is one whole
/// app message pushed onto it, `peerDown` closes it. The channels are registered by
/// native ON THE MESH ENGINE, so events arrive here directly with no isolate bridge.
class BleConnector implements MeshTransport {
  BleConnector();

  @override
  TransportKind get kind => TransportKind.ble;

  static const MethodChannel _method = MethodChannel('in.uniun.app/ble');
  static const EventChannel _events = EventChannel('in.uniun.app/ble/events');

  final _links = StreamController<MeshLink>.broadcast();
  // Per-peer inbound pump feeding each BleLink's `messages`.
  final Map<String, StreamController<Uint8List>> _inbound = {};
  final Map<String, BleLink> _byPeer = {};
  StreamSubscription<dynamic>? _eventsSub;

  /// Newly connected BLE links. One identity proof runs per link.
  @override
  Stream<MeshLink> get links => _links.stream;

  @override
  Future<void> start() async {
    _eventsSub = _events.receiveBroadcastStream().listen(
          _onEvent,
          onError: (Object e) => debugPrint('MESH/BLE: event error: $e'),
        );
    try {
      await _method.invokeMethod<void>('start');
    } on MissingPluginException {
      // Platform without native BLE (e.g. a test host) — no-op.
    } on PlatformException catch (e) {
      debugPrint('MESH/BLE: start failed: $e');
    }
  }

  void _onEvent(dynamic event) {
    if (event is! Map) return;
    final type = event['type'] as String?;
    final peerId = event['peerId'] as String?;
    if (type == null || peerId == null) return;
    switch (type) {
      case 'peerUp':
        _onPeerUp(peerId);
      case 'message':
        final bytes = event['bytes'];
        if (bytes is Uint8List) _onMessage(peerId, bytes);
      case 'peerDown':
        _onPeerDown(peerId);
    }
  }

  void _onPeerUp(String peerId) {
    if (_byPeer.containsKey(peerId)) return; // already linked
    final inbound = StreamController<Uint8List>();
    _inbound[peerId] = inbound;
    final link = BleLink(
      linkId: 'ble:$peerId',
      inbound: inbound.stream,
      rawSend: (bytes) => _send(peerId, bytes),
      rawClose: () => _disconnect(peerId),
    );
    _byPeer[peerId] = link;
    if (!_links.isClosed) _links.add(link);
  }

  void _onMessage(String peerId, Uint8List bytes) {
    final inbound = _inbound[peerId];
    if (inbound != null && !inbound.isClosed) inbound.add(bytes);
  }

  void _onPeerDown(String peerId) {
    final link = _byPeer.remove(peerId);
    final inbound = _inbound.remove(peerId);
    unawaited(inbound?.close());
    unawaited(link?.close());
  }

  void _send(String peerId, Uint8List bytes) {
    _method.invokeMethod<void>('send', {'peerId': peerId, 'bytes': bytes});
  }

  Future<void> _disconnect(String peerId) async {
    try {
      await _method.invokeMethod<void>('disconnect', {'peerId': peerId});
    } catch (_) {/* already gone */}
  }

  @override
  Future<void> stop() async {
    try {
      await _method.invokeMethod<void>('stop');
    } on MissingPluginException {
      // no native BLE
    } on PlatformException catch (e) {
      debugPrint('MESH/BLE: stop failed: $e');
    }
    await _eventsSub?.cancel();
    _eventsSub = null;
    for (final c in _inbound.values) {
      unawaited(c.close());
    }
    _inbound.clear();
    for (final l in _byPeer.values) {
      unawaited(l.close());
    }
    _byPeer.clear();
    if (!_links.isClosed) await _links.close();
  }
}
