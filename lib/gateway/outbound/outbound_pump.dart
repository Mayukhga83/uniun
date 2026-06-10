import 'dart:async';

import 'package:isar_community/isar.dart';
import 'package:uniun/data/models/event_queue_model.dart';
import 'package:uniun/gateway/session/relay_session.dart';

/// Drains [EventQueueModel] rows for one [RelaySession].
///
/// One pump per session. Maintains [_cursor] = the id of the last successfully
/// ACK'd queue item. On each tick:
///   1. Read the next item with id > cursor.
///   2. Ask [shouldSendToThisSession] (router callback) whether it targets us.
///      - If not, advance the cursor and try the next item.
///      - If yes, send and arm the pending-ACK slot.
/// When the session is closed or disconnected, the pump idles.
///
/// On ACK: subscribes to [session.okAcks] and advances cursor + bumps
/// [EventQueueModel.sentCount] in Isar.
class OutboundPump {
  final Isar _isar;
  final RelaySession session;
  final Future<bool> Function(EventQueueModel) _shouldSendToThisSession;

  int _cursor;
  StreamSubscription? _okSub;

  OutboundPump({
    required Isar isar,
    required this.session,
    required int startFromQueueId,
    required Future<bool> Function(EventQueueModel) shouldSendToThisSession,
  })  : _isar = isar,
        _cursor = startFromQueueId,
        _shouldSendToThisSession = shouldSendToThisSession {
    _okSub = session.okAcks.listen(_onOk);
  }

  /// Called when the queue changes or when the session reconnects.
  void onTick() => unawaited(_processNext());

  Future<void> dispose() async {
    await _okSub?.cancel();
  }

  Future<void> _processNext() async {
    if (!session.write || !session.isConnected) return;
    if (session.pendingAck.hasPending) return;

    final next = await _isar.eventQueueModels
        .where()
        .idGreaterThan(_cursor)
        .findFirst();
    if (next == null) return;

    final shouldSend = await _shouldSendToThisSession(next);
    if (!shouldSend) {
      _cursor = next.id;
      // Try the next item right away.
      unawaited(_processNext());
      return;
    }

    session.pendingAck.arm(next.eventId, next.id);
    final frame = next.isRawPassthroughEvent
        ? next.toRawRelayMessage()
        : next.toSerializedRelayMessage();
    session.sendRaw(frame);
  }

  Future<void> _onOk(dynamic msg) async {
    // msg is InboundOk from session — only fields we need are eventId, accepted.
    final eventId = msg.eventId as String;
    final accepted = msg.accepted as bool;

    final releasedQueueId = session.pendingAck.release(eventId);
    if (releasedQueueId == null) return; // wasn't ours

    if (accepted) {
      await _isar.writeTxn(() async {
        final item = await _isar.eventQueueModels
            .where()
            .eventIdEqualTo(eventId)
            .findFirst();
        if (item != null) {
          item.sentCount++;
          await _isar.eventQueueModels.put(item);
        }
      });
      _cursor = releasedQueueId;
    }
    unawaited(_processNext());
  }
}
