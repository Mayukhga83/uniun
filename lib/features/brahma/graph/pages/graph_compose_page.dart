import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniun/features/brahma/bloc/brahma_create_bloc.dart';
import 'package:uniun/features/brahma/graph/widgets/compose_header.dart';
import 'package:uniun/features/brahma/graph/widgets/compose_media_sheet.dart';
import 'package:uniun/features/brahma/utils/publish_chain_dialog.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/common/widgets/composer/markdown_text_editing_controller.dart';
import 'package:uniun/common/widgets/composer/uniun_composer.dart';
import 'package:uniun/common/widgets/composer/reference_picker_page.dart';
import 'package:uniun/domain/usecases/user_usecases.dart';
import 'package:uniun/l10n/app_localizations.dart';

/// Compose page opened from the graph FAB or draft edit button.
class GraphComposePage extends StatelessWidget {
  const GraphComposePage({
    super.key,
    this.initialDraftId,
    this.autoPublish = false,
  });

  final String? initialDraftId;

  /// When true the draft is published automatically once pre-filled.
  /// Used by the graph panel's "Publish" button — currently unused since
  /// publish is now fired directly from the panel.
  final bool autoPublish;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BrahmaCreateBloc>(
      create: (_) => getIt<BrahmaCreateBloc>()..add(const LoadDraftsEvent()),
      child: _GraphComposeView(
        initialDraftId: initialDraftId,
        autoPublish: autoPublish,
      ),
    );
  }
}

// ── View ────────────────────────────────────────────────────────────────────────

class _GraphComposeView extends StatefulWidget {
  const _GraphComposeView({this.initialDraftId, this.autoPublish = false});
  final String? initialDraftId;
  final bool autoPublish;

  @override
  State<_GraphComposeView> createState() => _GraphComposeViewState();
}

class _GraphComposeViewState extends State<_GraphComposeView> {
  final _controller = MarkdownTextEditingController();
  final _focusNode = FocusNode();
  bool _didPrefill = false;
  bool _didAutoPublish = false;
  bool _hasText = false;
  String? _avatarUrl;
  String _pubkeySeed = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
    _loadUserProfile();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final result = await getIt<GetActiveUserProfileUseCase>().call();
    result.fold((_) {}, (profile) {
      if (mounted) {
        setState(() {
          _pubkeySeed = profile.pubkeyHex;
          _avatarUrl = profile.avatarUrl;
        });
      }
    });
  }

  Future<void> _openReferencePicker(BrahmaCreateState state) async {
    final l10n = AppLocalizations.of(context)!;
    final bloc = context.read<BrahmaCreateBloc>();
    final selected = [
      for (final n in state.selectedMentions)
        ComposerReference(id: n.id, label: n.content),
      for (final d in state.selectedDraftMentions)
        ComposerReference(
          id: d.draftId,
          label: d.content,
          kind: ComposerReferenceKind.draft,
        ),
    ];

    final result = await Navigator.push<List<ComposerReference>>(
      context,
      MaterialPageRoute(
        builder: (_) => ReferencePickerPage(
          title: l10n.composerReferenceTitle,
          searchHint: l10n.brahmaMentionSearchHint,
          emptyLabel: l10n.brahmaMentionEmpty,
          initialSelected: selected,
        ),
      ),
    );

    if (result != null && mounted) {
      // Rebuild selected mentions from the returned refs, split by kind.
      final noteIds = [
        for (final r in result)
          if (r.kind == ComposerReferenceKind.note) r.id,
      ];
      final draftIds = [
        for (final r in result)
          if (r.kind == ComposerReferenceKind.draft) r.id,
      ];
      bloc.add(RestoreDraftMentionsEvent(
        noteIds: noteIds,
        draftIds: draftIds,
      ));
    }
  }

  void _saveDraft(BrahmaCreateState state) {
    final content = _controller.text.trim();
    if (content.isEmpty && state.pendingMedia.isEmpty) return;
    context.read<BrahmaCreateBloc>().add(SaveDraftEvent(
          content: content,
          draftId: widget.initialDraftId,
        ));
  }

  /// Publishing is irreversible — UNIUN has no delete — so it asks first.
  Future<bool> _confirmPublish() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.brahmaPublishConfirmTitle),
        content: Text(l10n.brahmaPublishConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.brahmaPublish),
          ),
        ],
      ),
    );
    return ok == true && mounted;
  }

  Future<void> _publish() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    final bloc = context.read<BrahmaCreateBloc>();
    // Read the FRESH bloc state — the BlocBuilder closure may have captured
    // an older snapshot if no other state change rebuilt between the picker
    // closing and the user tapping Publish.
    var draftDepCount = bloc.state.selectedDraftMentions.length;

    // Belt-and-braces: when editing an existing draft, also consult the
    // draft row itself in case the user opened compose, didn't touch the
    // picker, and the RestoreDraftMentions emit hasn't landed yet. The row's
    // `draftRefIds` are the authoritative count of unpublished draft refs.
    if (draftDepCount == 0 && widget.initialDraftId != null) {
      final row = bloc.state.drafts
          .where((d) => d.draftId == widget.initialDraftId)
          .firstOrNull;
      if (row != null) draftDepCount = row.draftRefIds.length;
    }

    // Ask before publishing if the composer holds unpublished draft refs —
    // those refs can only ride into the published `e` tags if their target
    // drafts are published in the same operation (Nostr events are immutable).
    var chain = false;
    if (draftDepCount > 0) {
      final choice = await showPublishChainSheet(
        context,
        draftCount: draftDepCount,
      );
      if (choice == PublishChainChoice.cancel || !mounted) return;
      chain = choice == PublishChainChoice.chain;
    } else if (!await _confirmPublish()) {
      // The chain sheet already carries a cancel, so it doubles as the
      // confirmation — only the plain path needs its own (#210).
      return;
    }

    if (widget.initialDraftId != null) {
      bloc.add(PublishDraftEvent(
        draftId: widget.initialDraftId!,
        content: content,
        publishChain: chain,
      ));
    } else {
      bloc.add(SubmitNoteEvent(
        content: content,
        publishChain: chain,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<BrahmaCreateBloc, BrahmaCreateState>(
      listener: (context, state) {
        // Pre-fill from draft if requested
        if (!_didPrefill &&
            widget.initialDraftId != null &&
            state.drafts.isNotEmpty) {
          _didPrefill = true;
          try {
            final draft = state.drafts
                .firstWhere((d) => d.draftId == widget.initialDraftId);
            _controller.text = draft.content;
            _controller.selection =
                TextSelection.collapsed(offset: draft.content.length);
            // Restore saved references as selected mentions — note ids go to
            // `eTagRefs`, draft UUIDs to `draftRefIds`.
            if (draft.eTagRefs.isNotEmpty || draft.draftRefIds.isNotEmpty) {
              context.read<BrahmaCreateBloc>().add(RestoreDraftMentionsEvent(
                    noteIds: draft.eTagRefs,
                    draftIds: draft.draftRefIds,
                  ));
            }
            // Restore staged media so the composer shows it (and re-save /
            // publish carry it).
            if (draft.attachments.isNotEmpty) {
              context
                  .read<BrahmaCreateBloc>()
                  .add(RestoreDraftMediaEvent(draft.attachments));
            }
          } catch (_) {}

          if (widget.autoPublish && !_didAutoPublish) {
            _didAutoPublish = true;
            _publish();
          }
        }

        if (state.status == BrahmaCreateStatus.draftSaved) {
          Navigator.pop(context);
        }

        if (state.status == BrahmaCreateStatus.success) {
          // Pop only the compose route so the user lands back on Brahma (the
          // graph), not Vishnu. The GraphFab/onEditTap awaits this push and
          // reloads the graph on return, so the new note shows immediately.
          Navigator.pop(context);
        }

        if (state.status == BrahmaCreateStatus.error &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.errorMessage!),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ));
        }
      },
      listenWhen: (prev, curr) =>
          prev.status != curr.status ||
          (widget.initialDraftId != null && prev.drafts != curr.drafts),
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          resizeToAvoidBottomInset: true,
          // GestureDetector wraps SizedBox.expand so a tap anywhere on the
          // body — including the blank area below the composer card —
          // dismisses the keyboard. Without SizedBox.expand the detector
          // only covers the column's natural size.
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.opaque,
            child: SizedBox.expand(
              // ScrollView avoids landscape overflow when the composer
              // grows taller than the keyboard-shrunk body. In portrait
              // it just sits at the top, no scroll bar.
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ComposeHeader(l10n: l10n),
                    UniunComposer(
                      controller: _controller,
                      focusNode: _focusNode,
                      autofocus: true,
                      minLines: 8,
                      maxLines: 14,
                      applyBottomInset: false,
                      markdownEnabled: true,
                      avatarUrl: _avatarUrl,
                      avatarSeed: _pubkeySeed,
                      hintText: l10n.brahmaHintText,
                      // Upload now happens at submit time, so `isSubmitting`
                      // (which spans upload + publish) is what disables Send.
                      canSend: _hasText,
                      isSending: state.isSubmitting,
                      references: [
                        for (final n in state.selectedMentions)
                          ComposerReference(id: n.id, label: n.content),
                        for (final d in state.selectedDraftMentions)
                          ComposerReference(
                            id: d.draftId,
                            label: d.content,
                            kind: ComposerReferenceKind.draft,
                          ),
                      ],
                      onRemoveReference: (id) => context
                          .read<BrahmaCreateBloc>()
                          .add(RemoveMentionEvent(id)),
                      onAddReference: () => _openReferencePicker(state),
                      onAttachMedia: () => showComposeMediaSheet(context),
                      attachments: state.pendingMedia,
                      isAttachingMedia: state.isAttachingMedia,
                      onRemoveAttachment: (sha) => context
                          .read<BrahmaCreateBloc>()
                          .add(RemoveAttachedMediaEvent(sha)),
                      onDraft: () => _saveDraft(state),
                      draftIsPrimary: true,
                      draftLabel: l10n.brahmaDraft,
                      onSend: _publish,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

