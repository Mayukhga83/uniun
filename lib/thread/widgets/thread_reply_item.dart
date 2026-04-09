import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/common/widgets/user_avatar.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/domain/entities/profile/profile_entity.dart';
import 'package:uniun/domain/usecases/saved_note_usecases.dart';
import 'package:uniun/shiv/rag/embedding/embedding_service.dart';
import 'package:uniun/thread/bloc/thread_bloc.dart';
import 'package:uniun/thread/utils/thread_formatters.dart';

// ── Top-level reply item (Twitter/X style) ────────────────────────────────────

class ThreadReplyItem extends StatefulWidget {
  const ThreadReplyItem({
    super.key,
    required this.reply,
    this.profile,
    required this.nestedReplies,
    required this.nestedProfiles,
    required this.allNestedReplies,
    required this.replyCounts,
    required this.replyCount,
    required this.showThreadLine, // kept for API compat — ignored
    required this.onReplyTap,
    this.onTap, // navigate into this reply's detail
  });

  final NoteEntity reply;
  final ProfileEntity? profile;
  final List<NoteEntity> nestedReplies;
  final Map<String, ProfileEntity> nestedProfiles;
  final Map<String, List<NoteEntity>> allNestedReplies;
  final Map<String, int> replyCounts;
  final int replyCount;
  final bool showThreadLine;
  final VoidCallback onReplyTap;
  /// Tapping the content area of this reply navigates into its detail thread.
  final VoidCallback? onTap;

  @override
  State<ThreadReplyItem> createState() => _ThreadReplyItemState();
}

class _ThreadReplyItemState extends State<ThreadReplyItem> {
  bool _isSaved = false;
  bool _showReplies = false;

  @override
  void initState() {
    super.initState();
    getIt<IsSavedNoteUseCase>()
        .call(widget.reply.id)
        .then((r) => r.fold((_) {}, (v) {
              if (mounted) setState(() => _isSaved = v);
            }));
  }

  @override
  void didUpdateWidget(ThreadReplyItem old) {
    super.didUpdateWidget(old);
    // Auto-open when replies stream in while the user already expanded
    if (_showReplies &&
        widget.nestedReplies.length > old.nestedReplies.length) {
      setState(() {});
    }
  }

  Future<void> _toggleSave() async {
    final nowSaved = !_isSaved;
    setState(() => _isSaved = nowSaved);
    if (nowSaved) {
      final result = await getIt<SaveNoteUseCase>().call(widget.reply);
      result.fold(
        (_) {
          if (mounted) setState(() => _isSaved = false);
        },
        (saved) {
          getIt<EmbeddingService>().embed(saved.content).then((vec) {
            if (vec.isNotEmpty) {
              getIt<UpdateEmbeddingUseCase>().call((saved.eventId, vec));
              print('📦 Embedded saved note (thread reply): ${saved.eventId}');
            }
          }).catchError((e) {
            print('📦 Embedding failed (thread reply): $e');
          });
        },
      );
    } else {
      final result = await getIt<UnsaveNoteUseCase>().call(widget.reply.id);
      result.fold(
        (_) {
          if (mounted) setState(() => _isSaved = true);
        },
        (_) {},
      );
    }
  }

  void _onToggleReplies() {
    if (!_showReplies &&
        widget.nestedReplies.isEmpty &&
        widget.replyCount > 0) {
      context.read<ThreadBloc>().add(ExpandReplyEvent(widget.reply.id));
    }
    setState(() => _showReplies = !_showReplies);
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final displayName = profile?.name ??
        profile?.username ??
        threadShortPubkey(widget.reply.authorPubkey);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Main reply card ────────────────────────────────────────────────────
        GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UserAvatar(
                seed: widget.reply.authorPubkey,
                photoUrl: profile?.avatarUrl,
                size: 40,
                borderRadius: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name · time
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '· ${threadTimeAgo(widget.reply.created)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    // Content
                    Text(
                      widget.reply.content,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.onSurface,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Action row
                    Row(
                      children: [
                        _ActionBtn(
                          icon: Icons.reply_rounded,
                          onTap: widget.onReplyTap,
                        ),
                        const SizedBox(width: 20),
                        if (widget.replyCount > 0)
                          _ActionBtn(
                            icon: _showReplies
                                ? Icons.chat_bubble_rounded
                                : Icons.chat_bubble_outline_rounded,
                            label: '${widget.replyCount}',
                            onTap: _onToggleReplies,
                            active: _showReplies,
                          ),
                        const Spacer(),
                        _ActionBtn(
                          icon: _isSaved
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          onTap: _toggleSave,
                          active: _isSaved,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ), // closes GestureDetector

        // ── Inline sub-replies (one level max) ────────────────────────────────
        if (_showReplies) ...[
          if (widget.nestedReplies.isNotEmpty)
            ...List.generate(widget.nestedReplies.length, (i) {
              final nested = widget.nestedReplies[i];
              final nestedProfile =
                  widget.nestedProfiles[nested.authorPubkey];
              final nestedName = nestedProfile?.name ??
                  nestedProfile?.username ??
                  threadShortPubkey(nested.authorPubkey);
              final nestedCount = widget.replyCounts[nested.id] ?? 0;
              return _InlineReplyItem(
                reply: nested,
                profile: nestedProfile,
                displayName: nestedName,
                replyCount: nestedCount,
                onReplyTap: () {
                  context.read<ThreadBloc>().add(
                        SetReplyTargetEvent(
                          replyToId: nested.id,
                          replyToName: nestedName,
                        ),
                      );
                },
              );
            })
          else if (widget.replyCount > 0)
            const _InlineLoadingSkeleton(),
        ],

        // ── Divider between replies ────────────────────────────────────────────
        Divider(
          height: 1,
          color: AppColors.outlineVariant.withValues(alpha: 0.12),
        ),
      ],
    );
  }
}

// ── Inline sub-reply (one level, compact) ─────────────────────────────────────

class _InlineReplyItem extends StatelessWidget {
  const _InlineReplyItem({
    required this.reply,
    required this.profile,
    required this.displayName,
    required this.replyCount,
    required this.onReplyTap,
  });

  final NoteEntity reply;
  final ProfileEntity? profile;
  final String displayName;
  final int replyCount;
  final VoidCallback onReplyTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 52, bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(
            seed: reply.authorPubkey,
            photoUrl: profile?.avatarUrl,
            size: 30,
            borderRadius: 15,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '· ${threadTimeAgo(reply.created)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  reply.content,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.onSurface,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    GestureDetector(
                      onTap: onReplyTap,
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                        child: Icon(Icons.reply_rounded,
                            size: 16, color: AppColors.onSurfaceVariant),
                      ),
                    ),
                    if (replyCount > 0) ...[
                      const SizedBox(width: 10),
                      Text(
                        '$replyCount ${replyCount == 1 ? 'reply' : 'replies'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared action button ───────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.onTap,
    this.label,
    this.active = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.onSurfaceVariant;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            if (label != null) ...[
              const SizedBox(width: 4),
              Text(
                label!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Skeleton while tree loads ─────────────────────────────────────────────────

class _InlineLoadingSkeleton extends StatelessWidget {
  const _InlineLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 52, bottom: 14),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.outlineVariant.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
