import 'dart:typed_data';

import '../../mesh_constants.dart';

/// Hard cap on a single framed message (guards against a bogus/huge length on the
/// wire). Mesh app messages (events, sync batches) are well under this. Alias of
/// the shared [kMeshMaxMessageBytes].
const int kLanMaxMessageBytes = kMeshMaxMessageBytes;

class LanFrameException implements Exception {
  LanFrameException(this.message);
  final String message;
  @override
  String toString() => 'LanFrameException: $message';
}

/// Prefixes [message] with a 4-byte big-endian length. A TCP socket is a byte
/// stream with no message boundaries, so every `MeshLink` message is length-framed.
Uint8List lanFrame(Uint8List message) {
  final out = Uint8List(4 + message.length);
  ByteData.view(out.buffer).setUint32(0, message.length, Endian.big);
  out.setRange(4, out.length, message);
  return out;
}

/// Stateful decoder for the length-prefix framing. Feed it raw socket chunks (any
/// size, split anywhere) via [add]; it yields each complete message exactly once,
/// buffering partial headers/payloads across chunks. Throws [LanFrameException] if
/// a declared length exceeds [kLanMaxMessageBytes].
class LanFrameDecoder {
  Uint8List _buf = Uint8List(0);

  Iterable<Uint8List> add(Uint8List chunk) sync* {
    if (chunk.isEmpty) return;
    _buf = _concat(_buf, chunk);

    var offset = 0;
    while (_buf.length - offset >= 4) {
      final len = ByteData.sublistView(_buf, offset, offset + 4)
          .getUint32(0, Endian.big);
      if (len > kLanMaxMessageBytes) {
        throw LanFrameException('frame length $len exceeds cap');
      }
      if (_buf.length - offset - 4 < len) break; // payload not fully arrived
      final start = offset + 4;
      yield Uint8List.fromList(
        Uint8List.sublistView(_buf, start, start + len),
      );
      offset = start + len;
    }

    // Compact the unconsumed remainder.
    _buf = offset == 0
        ? _buf
        : Uint8List.fromList(Uint8List.sublistView(_buf, offset));
  }

  static Uint8List _concat(Uint8List a, Uint8List b) {
    if (a.isEmpty) return Uint8List.fromList(b);
    return Uint8List(a.length + b.length)
      ..setRange(0, a.length, a)
      ..setRange(a.length, a.length + b.length, b);
  }
}
