import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:uniun/common/widgets/note_card/note_card.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/domain/entities/surrounding/surrounding_note_entity.dart';
import 'package:uniun/l10n/app_localizations.dart';

import '../cubit/surrounding_cubit.dart';
import '../cubit/surrounding_state.dart';

/// The "Surrounding" feed — Kind-1 notes broadcast by nearby devices over the
/// mesh, ordered by arrival time (`receivedAt`). Chat-style: newest at the
/// bottom, opens on the newest note; scroll up for older notes; notes arriving
/// over the mesh slide in at the bottom. Ephemeral (evicted daily); the NoteCard
/// bookmark keeps one forever.
class SurroundingFeedPage extends StatelessWidget {
  const SurroundingFeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SurroundingCubit()..load(),
      child: const _SurroundingView(),
    );
  }
}

class _SurroundingView extends StatefulWidget {
  const _SurroundingView();

  @override
  State<_SurroundingView> createState() => _SurroundingViewState();
}

class _SurroundingViewState extends State<_SurroundingView> {
  final _scrollController = ScrollController();

  /// Distance from the older edge at which the next page is requested.
  static const double _loadTrigger = 240;

  final Set<String> _everVisible = <String>{};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// In a reverse (newest-at-bottom) list the older notes are at the far end
  /// (maxScrollExtent, the top). Nearing it loads the next older page.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final cubit = context.read<SurroundingCubit>();
    if (pos.pixels >= pos.maxScrollExtent - _loadTrigger) {
      if (cubit.state.hasMoreOlder && !cubit.state.isLoadingOlder) {
        cubit.loadOlder();
      }
    }
  }

  /// Marks a note read once it has been majority-visible then leaves view.
  void _onVisibility(SurroundingNoteEntity item, VisibilityInfo info) {
    // VisibilityDetector fires from a deferred timer, which can run after this
    // page is disposed (e.g. scrolled then navigated away). Touching `context`
    // on an unmounted State throws — bail out first.
    if (!mounted) return;
    if (info.visibleFraction >= 0.5) {
      _everVisible.add(item.note.id);
    } else if (info.visibleFraction == 0 &&
        _everVisible.contains(item.note.id)) {
      context.read<SurroundingCubit>().markRead(item.receivedAt);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.onSurface),
        title: Text(
          l10n.surroundingTitle,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
      ),
      body: BlocBuilder<SurroundingCubit, SurroundingState>(
        builder: (context, state) {
          if (state.status == SurroundingStatus.initial ||
              state.status == SurroundingStatus.loading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            );
          }
          if (state.notes.isEmpty) return const _EmptyState();
          return _buildList(context, state);
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, SurroundingState state) {
    final notes = state.notes; // oldest→newest
    // The "Nearby" source tag is localized here (the data layer has no l10n).
    final sourceLabel = AppLocalizations.of(context)!.surroundingSourceLabel;
    return ListView.builder(
      controller: _scrollController,
      reverse: true, // newest at the bottom (chat style)
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 8),
      itemCount: notes.length + (state.isLoadingOlder ? 1 : 0),
      itemBuilder: (ctx, i) {
        // reverse: display index 0 = newest (bottom); higher index = older (up).
        // The older-loading spinner sits past the oldest loaded note (the top).
        if (i == notes.length) return const _EdgeSpinner();
        final item = notes[notes.length - 1 - i];
        return _tile(item, sourceLabel);
      },
    );
  }

  Widget _tile(SurroundingNoteEntity item, String sourceLabel) {
    return VisibilityDetector(
      key: ValueKey('surr-${item.note.id}'),
      onVisibilityChanged: (info) => _onVisibility(item, info),
      child: NoteCard(
        key: ValueKey(item.note.id),
        note: item.note.copyWith(sourceLabel: sourceLabel),
        onTap: () {},
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_tethering_rounded,
              size: 56,
              color: AppColors.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.surroundingEmpty,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.surroundingEmptySub,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// A small progress strip shown while an older page is loading.
class _EdgeSpinner extends StatelessWidget {
  const _EdgeSpinner();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2,
            ),
          ),
        ),
      ),
    );
  }
}
