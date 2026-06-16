import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../../link/mesh_link.dart';
import 'lan_framer.dart';

/// A [MeshLink] over a single TCP connection on the local network. Outbound
/// messages are length-framed ([lanFrame]); inbound raw bytes are de-framed by a
/// [LanFrameDecoder] so each emitted item is one whole application message.
///
/// Constructed from injected stream/sink callbacks so the framing + lifecycle can
/// be unit-tested without a real socket; [LanLink.fromSocket] wires a `dart:io`
/// [Socket]. `messages` is single-subscription (it buffers until the first
/// listener, matching a paused socket) — one demux consumer reads it per link.
class LanLink implements MeshLink {
  LanLink({
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
      (chunk) {
        try {
          for (final msg in _decoder.add(chunk)) {
            if (!_messages.isClosed) _messages.add(msg);
          }
        } catch (_) {
          // Framing violation (oversized/garbage length) → drop the link.
          unawaited(close());
        }
      },
      onError: (_) => _setState(MeshLinkState.disconnected),
      onDone: () => _setState(MeshLinkState.disconnected),
      cancelOnError: true,
    );
  }

  factory LanLink.fromSocket(Socket socket) {
    socket.setOption(SocketOption.tcpNoDelay, true);
    // Swallow write-side (IOSink) errors: a peer reset mid-send otherwise surfaces
    // as an unhandled SocketException. The read-side listener drives link state.
    unawaited(socket.done.catchError((Object _) {}));
    return LanLink(
      linkId: '${socket.remoteAddress.address}:${socket.remotePort}',
      inbound: socket.cast<Uint8List>(),
      rawSend: socket.add,
      rawClose: () async {
        try {
          await socket.flush();
        } catch (_) {/* peer already gone */}
        await socket.close();
      },
    );
  }

  @override
  final String linkId;

  @override
  TransportKind get transportKind => TransportKind.lan;

  final void Function(Uint8List) _rawSend;
  final Future<void> Function() _rawClose;
  final LanFrameDecoder _decoder = LanFrameDecoder();

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
      _rawSend(lanFrame(message));
    } catch (_) {
      // Write raced with a reset/close; the read-side handles disconnection.
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
    // listened to never completes its close() future (the done event has no
    // listener to deliver to).
    if (!_messages.isClosed) unawaited(_messages.close());
    if (!_states.isClosed) unawaited(_states.close());
  }

  void _setState(MeshLinkState s) {
    if (_state == s) return;
    _state = s;
    if (!_states.isClosed) _states.add(s);
  }
}
