import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/l10n/app_localizations.dart';
import 'package:uniun/shiv/chat/bloc/shiv_ai_bloc.dart';
import 'package:uniun/shiv/chat/pages/shiv_history_page.dart';
import 'package:uniun/shiv/chat/widgets/shiv_input_composer.dart';
import 'package:uniun/shiv/chat/widgets/shiv_message_bubble.dart';

/// The active conversation chat screen.
/// Header: SHIV title + thread title + history icon + tree icon.
/// No branch/continue buttons in bubbles — that's handled via the tree view.
class ShivChatPage extends StatefulWidget {
  const ShivChatPage({super.key});

  @override
  State<ShivChatPage> createState() => _ShivChatPageState();
}

class _ShivChatPageState extends State<ShivChatPage> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<ShivAIBloc, ShivAIState>(
      listenWhen: (prev, curr) => curr.messages.length != prev.messages.length,
      listener: (context, state) => _scrollToBottom(),
      builder: (context, state) {
        final isStreaming = state.status == ShivChatStatus.streaming;
        final conv = state.activeConversation;

        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            backgroundColor: AppColors.surfaceContainerLowest,
            resizeToAvoidBottomInset: false,
            body: Column(
              children: [
                _ShivChatHeader(
                  threadTitle: conv?.title ?? l10n.shivDefaultConversationTitle,
                  onHistoryTap: () => ShivHistoryPage.show(context),
                  onTreeTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.shivBranchTreeComingSoon),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                Expanded(
                  child: state.messages.isEmpty && !isStreaming
                      ? const _EmptyChat()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.only(top: 16, bottom: 16),
                          itemCount: state.messages.length,
                          itemBuilder: (context, i) {
                            final msg = state.messages[i];
                            final isLast = i == state.messages.length - 1;
                            final streamingContent =
                                isStreaming && isLast && msg.role.name == 'assistant'
                                    ? state.streamingContent
                                    : null;
                            return ShivMessageBubble(
                              key: ValueKey(msg.messageId),
                              message: msg,
                              streamingContent: streamingContent,
                            );
                          },
                        ),
                ),
                ShivInputComposer(
                  isStreaming: isStreaming,
                  onSend: (text) =>
                      context.read<ShivAIBloc>().add(ShivAIEvent.sendMessage(text)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────────

class _ShivChatHeader extends StatelessWidget {
  const _ShivChatHeader({
    required this.threadTitle,
    required this.onHistoryTap,
    required this.onTreeTap,
  });

  final String threadTitle;
  final VoidCallback onHistoryTap;
  final VoidCallback onTreeTap;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.only(left: 20, right: 8, top: top + 12, bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.85),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          // SHIV + thread title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.shivName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                    color: AppColors.primary,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  threadTitle,
                  style: const TextStyle(
                    fontSize: 11,
                    letterSpacing: 0.8,
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // History — back to conversation list
          _HeaderIcon(
            icon: Icons.history_rounded,
            onTap: onHistoryTap,
            tooltip: l10n.shivConversationsTooltip,
          ),
          // Tree — branch graph for this conversation
          _HeaderIcon(
            icon: Icons.account_tree_outlined,
            onTap: onTreeTap,
            tooltip: l10n.shivBranchTreeTooltip,
            isActive: true,
          ),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.isActive = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            size: 22,
            color: isActive ? AppColors.primary : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                size: 28,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.shivEmptyTitle,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.shivEmptyBody,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.55,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
