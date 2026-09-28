import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniun/common/widgets/note_card/embedded_note_card.dart';
import 'package:uniun/features/shiv/chat/widgets/document_source_tile.dart';
import 'package:uniun/features/shiv/chat/widgets/shiv_sources_cubit.dart';
import 'package:uniun/l10n/app_localizations.dart';

/// Bottom sheet listing what the last Shiv reply rested on — source notes and
/// PDF passages in one list, so "what grounded this answer" has a single place
/// to look. Read-only: notes render with [EmbeddedNoteCard], PDF passages with
/// [DocumentSourceTile]. The ids are ephemeral (current turn only); resolution
/// happens on open.
class ShivSourcesSheet extends StatelessWidget {
  const ShivSourcesSheet({
    super.key,
    required this.noteIds,
    this.chunkIds = const [],
  });

  final List<String> noteIds;

  /// `"<sha256>:<ordinal>"` ids of the PDF passages behind this reply.
  final List<String> chunkIds;

  static Future<void> show(
    BuildContext context,
    List<String> noteIds, {
    List<String> chunkIds = const [],
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ShivSourcesSheet(noteIds: noteIds, chunkIds: chunkIds),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ShivSourcesCubit()..load(noteIds, chunkIds: chunkIds),
      child: const _ShivSourcesView(),
    );
  }
}

class _ShivSourcesView extends StatelessWidget {
  const _ShivSourcesView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.shivSourcesSheetTitle,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: BlocBuilder<ShivSourcesCubit, ShivSourcesState>(
                builder: (context, state) {
                  if (state.status == ShivSourcesStatus.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          l10n.shivSourcesEmpty,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  }
                  // Documents first: a page-level citation is more specific
                  // evidence than a whole note.
                  final items = <Widget>[
                    for (final c in state.citations)
                      DocumentSourceTile(citation: c),
                    for (final n in state.notes) EmbeddedNoteCard(note: n),
                  ];
                  return ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => items[i],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
