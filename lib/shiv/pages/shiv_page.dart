import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/l10n/app_localizations.dart';
import 'package:uniun/shiv/chat/bloc/shiv_ai_bloc.dart';
import 'package:uniun/shiv/chat/pages/shiv_chat_page.dart';
import 'package:uniun/shiv/chat/pages/shiv_history_page.dart';

/// Shiv AI assistant tab root.
///
/// Provides the [ShivAIBloc], loads conversations on mount, then:
/// - If no conversation is active → landing screen with "New Chat" + history button.
/// - If a conversation is active → [ShivChatPage].
///
/// Model availability is guaranteed by [HomePage] before this tab is shown.
class ShivPage extends StatelessWidget {
  const ShivPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ShivAIBloc>()
        ..add(const ShivAIEvent.loadConversations()),
      child: const _ShivRoot(),
    );
  }
}

class _ShivRoot extends StatelessWidget {
  const _ShivRoot();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShivAIBloc, ShivAIState>(
      buildWhen: (prev, curr) =>
          (prev.activeConversation == null) != (curr.activeConversation == null),
      builder: (context, state) {
        if (state.activeConversation != null) {
          return const ShivChatPage();
        }
        return const _ShivLanding();
      },
    );
  }
}

// ── Landing screen (no active conversation) ───────────────────────────────────

class _ShivLanding extends StatelessWidget {
  const _ShivLanding();

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLowest,
      body: Column(
        children: [
          // Header
          Container(
            padding:
                EdgeInsets.only(left: 20, right: 8, top: top + 12, bottom: 12),
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
                // SHIV + tagline
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
                        l10n.shivTagline,
                        style: const TextStyle(
                          fontSize: 11,
                          letterSpacing: 0.8,
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // History
                _HeaderIcon(
                  icon: Icons.history_rounded,
                  tooltip: l10n.shivConversationsTooltip,
                  onTap: () => ShivHistoryPage.show(context),
                ),
                // Tree (disabled on landing — no active conversation)
                _HeaderIcon(
                  icon: Icons.account_tree_outlined,
                  tooltip: l10n.shivBranchTreeTooltip,
                  isActive: false,
                  onTap: () {},
                ),
              ],
            ),
          ),
          // Body
          Expanded(
            child: BlocBuilder<ShivAIBloc, ShivAIState>(
              builder: (context, state) {
                return _LandingBody(
                  conversationCount: state.conversations.length,
                  onNewChat: () => context
                      .read<ShivAIBloc>()
                      .add(const ShivAIEvent.createConversation()),
                  onHistory: () => ShivHistoryPage.show(context),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LandingBody extends StatelessWidget {
  const _LandingBody({
    required this.conversationCount,
    required this.onNewChat,
    required this.onHistory,
  });

  final int conversationCount;
  final VoidCallback onNewChat;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Halo avatar
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondaryContainer.withValues(alpha: 0.25),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                size: 36,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.shivName,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 4,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.shivLandingBody,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 40),
            // New chat CTA
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: onNewChat,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_rounded, color: AppColors.onPrimary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        l10n.shivNewConversation,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (conversationCount > 0) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: onHistory,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    l10n.shivViewConversations(conversationCount),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
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
