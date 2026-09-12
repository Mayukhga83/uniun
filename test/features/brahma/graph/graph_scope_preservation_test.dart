import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/features/brahma/bloc/brahma_create_bloc.dart';
import 'package:uniun/features/brahma/graph/bloc/graph_bloc.dart';
import 'package:uniun/features/brahma/graph/models/graph_node_type.dart';
import 'package:uniun/features/brahma/graph/pages/graph_page.dart';
import 'package:uniun/features/brahma/graph/widgets/graph_fab.dart';
import 'package:uniun/l10n/app_localizations.dart';

class _MockGraphBloc extends MockBloc<GraphEvent, GraphState>
    implements GraphBloc {}

class _MockBrahmaCreateBloc
    extends MockBloc<BrahmaCreateEvent, BrahmaCreateState>
    implements BrahmaCreateBloc {}

GraphNodeData _draft(String id) => GraphNodeData(
      eventId: id,
      content: 'a draft',
      eTagRefs: const [],
      type: GraphNodeType.draft,
      authorPubkey: 'me',
      created: DateTime(2026, 1, 1),
    );

/// Covers #204: both graph reloads that fire on returning from the compose
/// page must carry the active Manas scope. A bare `LoadGraphEvent()` is an
/// explicit unscope (`manasId == null` ⇒ `clearScope`), so dropping the
/// arguments silently kicks the user out of their scoped view.
void main() {
  late _MockGraphBloc graph;
  late _MockBrahmaCreateBloc create;

  setUpAll(() => registerFallbackValue(const LoadGraphEvent()));

  setUp(() async {
    graph = _MockGraphBloc();
    create = _MockBrahmaCreateBloc();
    when(() => create.state).thenReturn(const BrahmaCreateState());
    when(() => graph.isClosed).thenReturn(false);
    await GetIt.instance.reset();
    GetIt.instance.registerFactory<GraphBloc>(() => graph);
    GetIt.instance.registerFactory<BrahmaCreateBloc>(() => create);
  });

  tearDown(() => GetIt.instance.reset());

  /// Every LoadGraphEvent the widget pushed into the bloc, in order.
  List<LoadGraphEvent> loads() => verify(() => graph.add(captureAny()))
      .captured
      .whereType<LoadGraphEvent>()
      .toList();

  /// Two-route app: [home] at `/`, a stub compose page carrying a Back button
  /// so the test can pop the way a user would.
  Widget host(Widget home) {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => home),
        GoRoute(
          path: '/compose',
          name: AppRoutes.brahmaCreate,
          builder: (ctx, __) => Scaffold(
            body: TextButton(
              onPressed: () => ctx.pop(),
              child: const Text('back'),
            ),
          ),
        ),
      ],
    );
    return MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }

  // ── FAB → compose → back ──────────────────────────────────────────────

  group('GraphFab', () {
    Widget fabHost(GraphState state) {
      when(() => graph.state).thenReturn(state);
      return host(BlocProvider<GraphBloc>.value(
        value: graph,
        child: const Scaffold(body: Center(child: GraphFab())),
      ));
    }

    testWidgets('reload on return carries the active Manas scope', (t) async {
      await t.pumpWidget(fabHost(const GraphState(
        status: GraphStatus.loaded,
        scopedManasId: 'm1',
        scopedManasName: 'Work',
      )));
      await t.tap(find.byType(FloatingActionButton));
      await t.pumpAndSettle();
      await t.tap(find.text('back'));
      await t.pumpAndSettle();

      final load = loads().single;
      expect(load.manasId, 'm1');
      expect(load.manasName, 'Work');
    });

    testWidgets('an unscoped graph reloads unscoped', (t) async {
      await t.pumpWidget(fabHost(const GraphState(status: GraphStatus.loaded)));
      await t.tap(find.byType(FloatingActionButton));
      await t.pumpAndSettle();
      await t.tap(find.text('back'));
      await t.pumpAndSettle();

      final load = loads().single;
      expect(load.manasId, isNull);
      expect(load.manasName, isNull);
    });

    testWidgets('nothing is dispatched while the compose page is still open',
        (t) async {
      await t.pumpWidget(fabHost(const GraphState(
        status: GraphStatus.loaded,
        scopedManasId: 'm1',
      )));
      await t.tap(find.byType(FloatingActionButton));
      await t.pumpAndSettle();

      verifyNever(() => graph.add(any(that: isA<LoadGraphEvent>())));
    });
  });

  // ── Draft node → Edit → compose → back ────────────────────────────────

  group('draft edit from the node panel', () {
    Widget pageHost(GraphState state) {
      when(() => graph.state).thenReturn(state);
      return host(const GraphPage());
    }

    GraphState scoped(String manasId) => GraphState(
          status: GraphStatus.loaded,
          nodes: [_draft('d1')],
          adjacency: const {'d1': <String>{}},
          selectedNodeId: 'd1',
          scopedManasId: manasId,
          scopedManasName: 'Work',
        );

    testWidgets('reload on return carries the active Manas scope', (t) async {
      await t.pumpWidget(pageHost(scoped('m1')));
      await t.pumpAndSettle();

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      await t.tap(find.text(l10n.graphDraftEdit));
      await t.pumpAndSettle();
      await t.tap(find.text('back'));
      await t.pumpAndSettle();

      // loads().first is GraphPage's own mount load (bare by design — a fresh
      // bloc has no scope to preserve); the reload under test is the last.
      final load = loads().last;
      expect(load.manasId, 'm1');
      expect(load.manasName, 'Work');
    });

    testWidgets('the edited draft is re-selected so its panel reopens',
        (t) async {
      // The Edit button calls onClose() first, so selection is already
      // cleared — re-selecting reopens the panel rather than toggling it shut.
      await t.pumpWidget(pageHost(scoped('m1')));
      await t.pumpAndSettle();

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      await t.tap(find.text(l10n.graphDraftEdit));
      await t.pumpAndSettle();
      await t.tap(find.text('back'));
      await t.pumpAndSettle();

      final selects = verify(() => graph.add(captureAny()))
          .captured
          .whereType<SelectGraphNodeEvent>()
          .map((e) => e.nodeId);
      expect(selects, contains('d1'));
    });
  });
}
