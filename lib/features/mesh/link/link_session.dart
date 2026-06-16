import 'dart:async';
import 'dart:typed_data';

import '../payload/payload_envelope.dart';
import 'mesh_link.dart';

/// Owns the single subscription to a [MeshLink]'s messages and demultiplexes them
/// so the handshake and the post-handshake consumer (sync engine / inbound router)
/// can share one connection — a `MeshLink.messages` stream is single-subscription,
/// so nothing else may listen to it directly.
///
/// `Hello` messages go to [hellos]; everything else (`Event`/`Sync`) is buffered in
/// [_appBuffer] until [onAppMessage] registers the consumer, then replayed and
/// streamed. The negotiator subscribes to [hellos] asynchronously (after session
/// construction, inside `IdentityProof.negotiate`), so [hellos] is a
/// single-subscription controller that buffers until that first listener attaches —
/// neither the opening Hello nor handshake-window app messages can be dropped.
class LinkSession {
  LinkSession(this.link) {
    _sub = link.messages.listen(_onBytes);
  }

  final MeshLink link;
  late final StreamSubscription<Uint8List> _sub;

  // Single-subscription (not broadcast): buffers Hellos until the negotiator's
  // listener attaches, so the opening Hello is never dropped.
  final _hellos = StreamController<HelloMessage>();
  final List<MeshMessage> _appBuffer = [];
  void Function(MeshMessage)? _appHandler;

  /// Identity-proof messages, consumed once by the negotiator.
  Stream<HelloMessage> get hellos => _hellos.stream;

  void _onBytes(Uint8List bytes) {
    final msg = MeshMessage.decode(bytes);
    if (msg == null) return; // drop malformed/unknown
    if (msg is HelloMessage) {
      // Only relevant during the handshake; once the app consumer is attached,
      // stray Hellos are ignored (and wouldn't be drained anyway).
      if (_appHandler == null && !_hellos.isClosed) _hellos.add(msg);
      return;
    }
    final handler = _appHandler;
    if (handler != null) {
      handler(msg);
    } else {
      _appBuffer.add(msg);
    }
  }

  /// Registers the post-handshake consumer, replaying anything buffered during the
  /// handshake, then streaming subsequent app messages. Call once.
  void onAppMessage(void Function(MeshMessage) handler) {
    _appHandler = handler;
    final pending = List<MeshMessage>.of(_appBuffer);
    _appBuffer.clear();
    for (final m in pending) {
      handler(m);
    }
  }

  void send(MeshMessage message) => link.send(message.encode());

  Future<void> close() async {
    await _sub.cancel();
    if (!_hellos.isClosed) await _hellos.close();
    await link.close();
  }
}
