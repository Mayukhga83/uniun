import 'dart:async';

import 'package:flutter/foundation.dart';

import '../mesh_constants.dart';
import '../payload/payload_envelope.dart';
import 'broadcast_set_builder.dart';

/// The **outbound** half of the Surrounding feed for one stranger peer: pushes our
/// public broadcast set (own + saved notes, paced) as signed Nostr `EVENT` payloads.
/// The inbound half — verifying, storing, and multi-hop relaying received events —
/// is owned by `MeshRouter`.
///
/// One instance is kept per connected peer (for its session lifetime) so it can
/// **dedupe**: the first [broadcast] sends the whole set; later ones (triggered by
/// a new local note) send only events not yet sent to this peer, avoiding
/// re-flooding the network with everything every time.
class SurroundingExchange {
  SurroundingExchange({
    required void Function(MeshMessage) send,
    required BroadcastSetBuilder broadcastSet,
  })  : _send = send,
        _broadcastSet = broadcastSet;

  final void Function(MeshMessage) _send;
  final BroadcastSetBuilder _broadcastSet;

  /// Event ids already sent to this peer this session.
  final Set<String> _sentIds = {};

  /// Minimum gap between paced sends. The receiver accepts only
  /// `SurroundingInbound._maxNotesPerSecond` (2) notes per rolling second; spacing
  /// sends >500ms apart guarantees at most two land in any one-second window, so a
  /// genuine note is never dropped as a flood. 600ms leaves margin for jitter.
  static const Duration _sendInterval = kSurroundingSendInterval;

  /// True while a paced drain is in flight; a concurrent [broadcast] folds into it
  /// via [_pending] rather than starting a second, cursor-racing drain.
  bool _draining = false;
  bool _pending = false;

  /// Streams the current delta to this peer and sends it **one note at a time**,
  /// paced to [_sendInterval] so the receiver's per-second cap never drops a
  /// genuine note. First call = full capped set; later calls = only the delta.
  /// Overlapping calls (a resync firing mid-drain) fold into the running drain and
  /// trigger one more pass at the end, so a delta produced while draining still ships.
  Future<void> broadcast() async {
    if (_draining) {
      _pending = true;
      return;
    }
    _draining = true;
    try {
      do {
        _pending = false;
        await _drainDelta();
      } while (_pending);
    } finally {
      _draining = false;
    }
  }

  Future<void> _drainDelta() async {
    var sent = 0;
    await for (final event in _broadcastSet.deltaEvents()) {
      final id = event['id'] as String?;
      if (id == null) continue;
      if (!_sentIds.add(id)) continue; // already sent to this peer this session
      if (sent > 0) await Future<void>.delayed(_sendInterval);
      _send(EventMessage(event));
      sent++;
    }
    if (sent > 0) {
      debugPrint('MESH/SURR: paced $sent new event(s) to a stranger');
    }
  }
}
