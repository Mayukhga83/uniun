import 'package:flutter_test/flutter_test.dart';
import 'package:uniun/features/mesh/link/link_session.dart';
import 'package:uniun/features/mesh/sync/sync_scope.dart';
import 'package:uniun/features/mesh/sync/trusted_sync_engine.dart';

import 'support/paired_mesh_link.dart';

/// In-memory scope keyed by each row's `id` field.
class _FakeScope implements SyncScope {
  _FakeScope(this.name, List<Map<String, dynamic>> initial) {
    for (final row in initial) {
      store[row['id'] as String] = row;
    }
  }

  @override
  final String name;
  final Map<String, Map<String, dynamic>> store = {};

  @override
  Future<Set<String>> localKeys() async => store.keys.toSet();

  @override
  Future<List<Map<String, dynamic>>> rows(Set<String> keys) async =>
      keys.where(store.containsKey).map((k) => store[k]!).toList();

  @override
  Future<void> upsert(List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      store[row['id'] as String] = row;
    }
  }

  Set<String> get keys => store.keys.toSet();
}

({TrustedSyncEngine engine, LinkSession session}) _engineOn(
  LinkSession session,
  List<SyncScope> scopes,
) {
  final engine = TrustedSyncEngine(scopes: scopes, send: session.send);
  session.onAppMessage(engine.handleMessage);
  return (engine: engine, session: session);
}

/// Pumps the event loop until [cond] holds (a resync is a one-sided push that
/// resolves once this side has SENT its rows, so the peer's upsert lands a few
/// microtasks later).
Future<void> _until(bool Function() cond) async {
  for (var i = 0; i < 500; i++) {
    if (cond()) return;
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  fail('condition not met within timeout');
}

void main() {
  test('two peers converge a single scope (overlapping + disjoint keys)',
      () async {
    final links = createPairedLinks();
    final scopeA = _FakeScope('note', [
      {'id': '1', 'v': 'a1'},
      {'id': '2', 'v': 'a2'},
    ]);
    final scopeB = _FakeScope('note', [
      {'id': '2', 'v': 'b2'},
      {'id': '3', 'v': 'b3'},
    ]);

    final a = _engineOn(LinkSession(links.a), [scopeA]);
    final b = _engineOn(LinkSession(links.b), [scopeB]);
    await Future.wait([a.engine.run(), b.engine.run()]);

    expect(scopeA.keys, unorderedEquals(['1', '2', '3']));
    expect(scopeB.keys, unorderedEquals(['1', '2', '3']));
    // Missing rows transferred; the pre-existing '1'/'3' carry the other side's data.
    expect(scopeB.store['1']!['v'], 'a1');
    expect(scopeA.store['3']!['v'], 'b3');
  });

  test('multiple scopes all reconcile', () async {
    final links = createPairedLinks();
    final aNotes = _FakeScope('note', [
      {'id': 'n1'},
    ]);
    final aSaved = _FakeScope('saved', [
      {'id': 's1'},
      {'id': 's2'},
    ]);
    final bNotes = _FakeScope('note', [
      {'id': 'n2'},
    ]);
    final bSaved = _FakeScope('saved', <Map<String, dynamic>>[]);

    final a = _engineOn(LinkSession(links.a), [aNotes, aSaved]);
    final b = _engineOn(LinkSession(links.b), [bNotes, bSaved]);
    await Future.wait([a.engine.run(), b.engine.run()]);

    expect(aNotes.keys, unorderedEquals(['n1', 'n2']));
    expect(bNotes.keys, unorderedEquals(['n1', 'n2']));
    expect(bSaved.keys, unorderedEquals(['s1', 's2']));
    expect(aSaved.keys, unorderedEquals(['s1', 's2']));
  });

  test('empty scopes terminate without hanging', () async {
    final links = createPairedLinks();
    final a = _engineOn(
      LinkSession(links.a),
      [_FakeScope('note', <Map<String, dynamic>>[])],
    );
    final b = _engineOn(
      LinkSession(links.b),
      [_FakeScope('note', <Map<String, dynamic>>[])],
    );
    await Future.wait([
      a.engine.run().timeout(const Duration(seconds: 2)),
      b.engine.run().timeout(const Duration(seconds: 2)),
    ]);
  });

  test('resync() pushes newly-added keys over the SAME session (two rounds)',
      () async {
    final links = createPairedLinks();
    final scopeA = _FakeScope('note', [
      {'id': '1'},
    ]);
    final scopeB = _FakeScope('note', [
      {'id': '1'},
    ]);
    final a = _engineOn(LinkSession(links.a), [scopeA]);
    final b = _engineOn(LinkSession(links.b), [scopeB]);

    // Round 1: initial convergence (both already hold '1').
    await Future.wait([a.engine.run(), b.engine.run()]);
    expect(scopeB.keys, unorderedEquals(['1']));

    // A writes a new note, then resyncs over the SAME engine/session (no rebuild).
    scopeA.store['2'] = {'id': '2', 'v': 'a2'};
    await a.engine.resync();
    await _until(() => scopeB.store.containsKey('2'));
    expect(scopeB.store['2']!['v'], 'a2');

    // resync() is re-runnable: a second write propagates too.
    scopeA.store['3'] = {'id': '3'};
    await a.engine.resync();
    await _until(() => scopeB.store.containsKey('3'));
    expect(scopeB.keys, unorderedEquals(['1', '2', '3']));
  });

  test('already-converged peers re-sync to no-ops (idempotent)', () async {
    final links = createPairedLinks();
    final same = [
      {'id': 'x'},
      {'id': 'y'},
    ];
    final scopeA = _FakeScope('note', same);
    final scopeB = _FakeScope('note', same);
    final a = _engineOn(LinkSession(links.a), [scopeA]);
    final b = _engineOn(LinkSession(links.b), [scopeB]);
    await Future.wait([a.engine.run(), b.engine.run()]);

    expect(scopeA.keys, unorderedEquals(['x', 'y']));
    expect(scopeB.keys, unorderedEquals(['x', 'y']));
  });
}
