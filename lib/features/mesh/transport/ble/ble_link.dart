import 'dart:async';
import 'dart:typed_data';

import '../../link/mesh_link.dart';

/// A [MeshLink] over a single BLE GATT connection.
///
/// The native layer (Android Kotlin / iOS-macOS Swift) owns the radio, MTU
/// negotiation and fragmentation/reassembly, so each item on [inbound] is already
/// ONE whole application message — unlike [LanLink] there is no de-framing here.
/// Outbound [send] hands the whole message to native, which fragments it across the
/// GATT writes/notifications. `messages` is single-subscription (one demux consumer
/// per link), matching the other transports.
class BleLink implements MeshLink {
  BleLink({
    required this.linkId,
    required Stream<Uint8List> inbound,
    required void Function(Uint8List) rawSend,
    required Future<void> Function() rawClose,
  })  : _rawSend = rawSend,
        _rawClose = rawClose {
    _messages = StreamController<Uint8List>(
      onCancel: () => _inboundSub?.cancel(),
    );
    _inboundSub = inbound.listen(
      (msg) {
        if (!_messages.isClosed) _messages.add(msg);
      },
      onError: (_) => _setState(MeshLinkState.disconnected),
      onDone: () => _setState(MeshLinkState.disconnected),
      cancelOnError: true,
    );
  }

  @override
  final String linkId;

  @override
  TransportKind get transportKind => TransportKind.ble;

  final void Function(Uint8List) _rawSend;
  final Future<void> Function() _rawClose;

  late final StreamController<Uint8List> _messages;
  StreamSubscription<Uint8List>? _inboundSub;
  final _states = StreamController<MeshLinkState>.broadcast();
  MeshLinkState _state = MeshLinkState.connected;
  bool _closed = false;

  @override
  Stream<Uint8List> get messages => _messages.stream;

  @override
  Stream<MeshLinkState> get states => _states.stream;

  @override
  MeshLinkState get state => _state;

  @override
  bool get isConnected => _state == MeshLinkState.connected;

  @override
  void send(Uint8List message) {
    if (!isConnected) return;
    try {
      _rawSend(message);
    } catch (_) {
      // Raced with a disconnect; the inbound side drives link state.
    }
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _setState(MeshLinkState.disconnected);
    await _inboundSub?.cancel();
    try {
      await _rawClose();
    } catch (_) {/* already gone */}
    // Don't await: a single-subscription `messages` controller that was never
    // listened to never completes its close() future.
    if (!_messages.isClosed) unawaited(_messages.close());
    if (!_states.isClosed) unawaited(_states.close());
  }

  void _setState(MeshLinkState s) {
    if (_state == s) return;
    _state = s;
    if (!_states.isClosed) _states.add(s);
  }
}
