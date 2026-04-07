import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/domain/entities/shiv/shiv_conversation_entity.dart';
import 'package:uniun/l10n/app_localizations.dart';
import 'package:uniun/shiv/chat/bloc/shiv_ai_bloc.dart';

/// Full-screen conversation history list.
/// Shown when user taps the history icon from the chat header.
class ShivHistoryPage extends StatelessWidget {
  const ShivHistoryPage({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<ShivAIBloc>(),
        child: const ShivHistoryPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
                child: Row(
                  children: [
                    Text(
                      l10n.shivConversations,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Spacer(),
                    // New conversation
                    BlocBuilder<ShivAIBloc, ShivAIState>(
                      builder: (context, state) => IconButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          context
                              .read<ShivAIBloc>()
                              .add(const ShivAIEvent.createConversation());
                        },
                        icon: const Icon(Icons.add_rounded),
                        color: AppColors.primary,
                        tooltip: l10n.shivNewConversationTooltip,
                      ),
                    ),
                  ],
                ),
              ),
              // List
              Expanded(
                child: BlocBuilder<ShivAIBloc, ShivAIState>(
                  builder: (context, state) {
                    if (state.conversations.isEmpty) {
                      return _Empty(l10n: l10n);
                    }
                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: state.conversations.length,
                      itemBuilder: (context, i) {
                        return _ConversationTile(
                          conversation: state.conversations[i],
                          isActive: state.activeConversation?.conversationId ==
                              state.conversations[i].conversationId,
                          onTap: () {
                            Navigator.of(context).pop();
                            context.read<ShivAIBloc>().add(
                                ShivAIEvent.openConversation(
                                    state.conversations[i].conversationId));
                          },
                          onDelete: () {
                            context.read<ShivAIBloc>().add(
                                ShivAIEvent.deleteConversation(
                                    state.conversations[i].conversationId));
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.isActive,
    required this.onTap,
    required this.onDelete,
  });

  final ShivConversationEntity conversation;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dismissible(
      key: Key(conversation.conversationId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.onError),
      ),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.12)
                : AppColors.surfaceContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.chat_bubble_outline_rounded,
            size: 18,
            color: isActive ? AppColors.primary : AppColors.onSurfaceVariant,
          ),
        ),
        title: Text(
          conversation.title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: AppColors.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          _formatDate(conversation.updatedAt, l10n),
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        trailing: isActive
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  l10n.shivActiveLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              )
            : const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.onSurfaceVariant,
                size: 20,
              ),
      ),
    );
  }

  String _formatDate(DateTime dt, AppLocalizations l10n) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return l10n.shivTimeJustNow;
    if (diff.inHours < 1) return l10n.shivTimeMinutesAgo(diff.inMinutes);
    if (diff.inDays < 1) return l10n.shivTimeHoursAgo(diff.inHours);
    if (diff.inDays < 7) return l10n.shivTimeDaysAgo(diff.inDays);
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        l10n.shivNoConversations,
        style: const TextStyle(
          fontSize: 15,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}
