import 'dart:async';

import 'package:flutter/foundation.dart';

import '../mesh_constants.dart';
import '../payload/payload_envelope.dart';
import 'sync_scope.dart';

/// Reconciles a set of [SyncScope]s with a trusted same-identity peer over a
/// `MeshLink` (via a `LinkSession`). v1 protocol is a symmetric **id-list diff**,
/// run per scope and in both directions:
///
///   HAVE(scope, myKeys) → peer replies NEED(scope, keysItLacks)
///   NEED(scope, keys)   → reply ROWS(scope, serialized rows)
///   ROWS(scope, rows)   → upsert
///
/// A scope is reconciled once it has sent its ROWS (after a NEED) and — for the
/// initial [run] — received the peer's ROWS; the round completes when every scope
/// is reconciled. Even empty scopes terminate (HAVE([]) → NEED([]) → ROWS([])).
///
/// **Re-runnable.** One engine is kept per peer for the session. [resync] re-runs a
/// round over the SAME session (and link handler) after local content changes — it
/// never rebuilds the engine. A resync is a *push* (it completes once it has served
/// the peer's NEEDs) so a one-sided write doesn't block on a reverse direction the
/// peer never asked for. Designed to be swapped for NIP-77 Negentropy later behind
/// the same interface.
class TrustedSyncEngine {
  TrustedSyncEngine({
    required List<SyncScope> scopes,
    required void Function(MeshMessage) send,
    Duration timeout = kTrustedSyncTimeout,
  })  : _send = send,
        _timeout = timeout {
    for (final scope in scopes) {
      _byName[scope.name] = scope;
      _state[scope.name] = _ScopeState();
    }
  }

  final void Function(MeshMessage) _send;
  final Duration _timeout;
  final Map<String, SyncScope> _byName = {};
  final Map<String, _ScopeState> _state = {};
  Completer<void> _done = Completer<void>();
  // A round is in flight; a resync arriving meanwhile folds into one trailing round.
  bool _running = false;
  bool _pending = false;
  // run() reconciles both ways; resync() only needs to finish pushing (send ROWS).
  bool _requireReceive = true;

  /// Feed app messages here (wire `LinkSession.onAppMessage` to it). Non-sync
  /// messages are ignored, so the same channel can also carry mesh `Event`s.
  void handleMessage(MeshMessage msg) {
    if (msg is SyncMessage) {
      unawaited(_handle(msg).catchError(
        (Object e) => debugPrint('MESH/SYNC: handle error (${msg.scope}): $e'),
      ));
    }
  }

  /// Initial reconciliation on connect: sends HAVE for every scope and resolves
  /// when all scopes are reconciled **both ways**, or after [timeout].
  Future<void> run() => _round(requireReceive: true);

  /// Re-reconciles over the SAME session after local content changed — without
  /// rebuilding the engine or re-registering the link handler. Completes once this
  /// side has served the peer's NEEDs (a push); concurrent resyncs fold into one
  /// trailing round.
  Future<void> resync() => _round(requireReceive: false);

  Future<void> _round({required bool requireReceive}) async {
    if (_byName.isEmpty) return;
    if (_running) {
      _pending = true; // a round is busy — run once more when it finishes
      return;
    }
    _running = true;
    var receive = requireReceive;
    do {
      _pending = false;
      _done = Completer<void>();
      _requireReceive = receive;
      for (final s in _state.values) {
        s.sentRows = false;
        s.receivedRows = false;
      }
      for (final scope in _byName.values) {
        final keys = await scope.localKeys();
        _send(SyncMessage(scope: scope.name, op: SyncOp.have, ids: keys.toList()));
      }
      await _done.future.timeout(_timeout, onTimeout: () {
        final pending = _state.entries
            .where((e) => !_reconciled(e.value))
            .map((e) => e.key)
            .toList();
        debugPrint('MESH/SYNC: timed out; unreconciled scopes=$pending');
      });
      receive = false; // any folded follow-up is a push
    } while (_pending);
    _running = false;
  }

  /// Stops a pending round's timeout when the peer is dropped.
  void dispose() {
    if (!_done.isCompleted) _done.complete();
  }

  Future<void> _handle(SyncMessage m) async {
    final scope = _byName[m.scope];
    final state = _state[m.scope];
    if (scope == null || state == null) return; // unknown scope → ignore

    switch (m.op) {
      case SyncOp.have:
        final mine = await scope.localKeys();
        final need = m.ids.where((k) => !mine.contains(k)).toList();
        _send(SyncMessage(scope: m.scope, op: SyncOp.need, ids: need));
      case SyncOp.need:
        final rows = await scope.rows(m.ids.toSet());
        _send(SyncMessage(scope: m.scope, op: SyncOp.rows, rows: rows));
        state.sentRows = true;
        _checkDone();
      case SyncOp.rows:
        if (m.rows.isNotEmpty) await scope.upsert(m.rows);
        state.receivedRows = true;
        _checkDone();
      case SyncOp.done:
        break; // reserved
    }
  }

  bool _reconciled(_ScopeState s) =>
      s.sentRows && (!_requireReceive || s.receivedRows);

  void _checkDone() {
    if (_done.isCompleted) return;
    if (_state.values.every(_reconciled)) _done.complete();
  }
}

class _ScopeState {
  bool sentRows = false;
  bool receivedRows = false;
}
