import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniun/features/brahma/graph/bloc/graph_bloc.dart';
import 'package:uniun/core/router/app_routes.dart';
/// FAB that opens the compose page and reloads the graph on return.
class GraphFab extends StatelessWidget {
  const GraphFab({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _onTap(context),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      elevation: 4,
      shape: const CircleBorder(),
      child: const Icon(Icons.add_rounded, size: 28),
    );
  }

  Future<void> _onTap(BuildContext context) async {
    final bloc = context.read<GraphBloc>();
    await context.pushNamed(AppRoutes.brahmaCreate);
    // A bare LoadGraphEvent() means "unscope" (manasId == null ⇒ clearScope),
    // so the active Manas has to ride along.
    bloc.add(LoadGraphEvent(
      manasId: bloc.state.scopedManasId,
      manasName: bloc.state.scopedManasName,
    ));
  }
}
