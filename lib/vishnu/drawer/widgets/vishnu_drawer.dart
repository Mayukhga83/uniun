import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniun/l10n/app_localizations.dart';
import 'package:uniun/common/widgets/user_avatar.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/domain/usecases/followed_note_usecases.dart';
import 'package:uniun/core/scan/uniun_qr_card.dart';
import 'package:uniun/thread/pages/thread_page.dart';
import 'package:uniun/vishnu/drawer/bloc/drawer_bloc.dart' as app_drawer;

class VishnuDrawer extends StatelessWidget {
  const VishnuDrawer({super.key, required this.onSwitchTab});

  final Future<void> Function(int) onSwitchTab;

  void _close(BuildContext context) => Navigator.pop(context);

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.drawerComingSoon(feature)),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      width: 280,
      child: BlocBuilder<app_drawer.DrawerBloc, app_drawer.DrawerState>(
        builder: (context, state) {
          final loaded = state is app_drawer.DrawerLoaded ? state : null;
          final l10n = AppLocalizations.of(context)!;
          return Column(
            children: [
              _DrawerHeader(
                name: loaded?.userName ?? '...',
                npub: loaded?.npub ?? '',
                pubkeyHex: loaded?.pubkeyHex ?? '',
                avatarUrl: loaded?.avatarUrl,
              ),

              Expanded(
                child: ListView(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  children: [
                    // ── Main nav ──────────────────────────────────────────
                    _NavItem(
                      icon: Icons.home_rounded,
                      label: l10n.drawerHome,
                      active: true,
                      onTap: () => _close(context),
                    ),
                    _NavItem(
                      icon: Icons.bookmark_rounded,
                      label: l10n.drawerSavedNotes,
                      onTap: () {
                        _close(context);
                        Navigator.pushNamed(context, AppRoutes.savedNotes);
                      },
                    ),

                    const SizedBox(height: 16),

                    // ── Following Notes (collapsible) ─────────────────────
                    _CollapsibleFollowingSection(
                      items: loaded?.followedNotes ?? [],
                      onAdd: () => _showComingSoon(context, l10n.drawerHome),
                      onItemTap: (item) async {
                        _close(context);
                        getIt<ClearNewReferencesUseCase>().call(item.eventId);
                        await Navigator.pushNamed(
                          context,
                          AppRoutes.thread,
                          arguments: ThreadRouteArgs(
                            item.eventId,
                            hasUnread: item.newReferenceCount > 0,
                          ),
                        );
                        // ignore: use_build_context_synchronously
                        if (context.mounted) {
                          context.read<app_drawer.DrawerBloc>().add(app_drawer.DrawerLoadEvent());
                        }
                      },
                    ),

                    const SizedBox(height: 16),

                    // ── Channels (collapsible) ────────────────────────────
                    _CollapsibleChannelSection(
                      items: loaded?.channels ?? [],
                      onAdd: () {
                        _close(context);
                        Navigator.pushNamed(context, AppRoutes.createChannel);
                      },
                      onItemTap: (channelId) {
                        _close(context);
                        Navigator.pushNamed(
                          context,
                          AppRoutes.channelDetail,
                          arguments: channelId,
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // ── Direct Messages ───────────────────────────────────
                    _SectionHeader(
                      label: l10n.drawerDirectMessages,
                      onAdd: () {
                         _close(context);
                         Navigator.pushNamed(context, AppRoutes.createDm);
                      },
                    ),
                    const SizedBox(height: 4),
                    if ((loaded?.dms ?? []).isEmpty)
                      _EmptyHint(l10n.drawerNoMessages)
                    else
                      ...loaded!.dms.map((dm) => _DmRow(
                            dm: dm,
                            onTap: () {
                              _close(context);
                              Navigator.pushNamed(
                                context, 
                                AppRoutes.chatDm, 
                                arguments: dm.pubkey,
                              );
                            },
                          )),

                    const SizedBox(height: 16),

                    // ── Apps ──────────────────────────────────────────────
                    _SectionHeader(label: l10n.drawerApps),
                    const SizedBox(height: 4),
                    _AppRow(
                      label: l10n.drawerAiAssistant,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primary, Color(0xFF1A5CB8)],
                      ),
                      icon: Icons.smart_toy_rounded,
                      onTap: () {
                        _close(context);
                        onSwitchTab(2);
                      },
                    ),
                  ],
                ),
              ),

              _DrawerFooter(
                onSettings: () {
                  _close(context);
                  Navigator.pushNamed(context, AppRoutes.settings);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────────

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({
    required this.name,
    required this.npub,
    required this.pubkeyHex,
    this.avatarUrl,
  });

  final String name;
  final String npub;
  final String pubkeyHex;
  final String? avatarUrl;

  void _showCard(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => UniunQrCard.user(name: name, pubkeyHex: pubkeyHex),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 16, 16, 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              UserAvatar(
                seed: pubkeyHex,
                photoUrl: avatarUrl,
                size: 40,
                borderRadius: 10,
              ),
              Positioned(
                bottom: -1,
                right: -1,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF22C55E),
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // My card button
          Tooltip(
            message: l10n.drawerShowCard,
            child: IconButton(
              onPressed: () => _showCard(context),
              icon: const Icon(Icons.badge_rounded,
                  color: AppColors.onSurfaceVariant, size: 18),
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(4),
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 2),
          // Scan button
          Tooltip(
            message: l10n.drawerScanCard,
            child: IconButton(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.scanQr),
              icon: const Icon(Icons.qr_code_scanner_rounded,
                  color: AppColors.onSurfaceVariant, size: 18),
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(4),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section header ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, this.onAdd});

  final String label;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: AppColors.outline,
              ),
            ),
          ),
          if (onAdd != null)
            GestureDetector(
              onTap: onAdd,
              child: const Icon(Icons.add_rounded,
                  size: 18, color: AppColors.outline),
            ),
        ],
      ),
    );
  }
}

// ── Nav item ───────────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: active ? AppColors.primary : AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? AppColors.primary : AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Followed note row ──────────────────────────────────────────────────────────

class _FollowedNoteRow extends StatelessWidget {
  const _FollowedNoteRow({required this.item, required this.onTap});
  final app_drawer.DrawerFollowedNoteItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(
          children: [
            const Icon(Icons.link_rounded, size: 16, color: AppColors.outline),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.contentPreview,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
            if (item.newReferenceCount > 0)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Collapsible following section ─────────────────────────────────────────────

class _CollapsibleFollowingSection extends StatefulWidget {
  const _CollapsibleFollowingSection({
    required this.items,
    required this.onAdd,
    required this.onItemTap,
  });

  final List<app_drawer.DrawerFollowedNoteItem> items;
  final VoidCallback onAdd;
  final void Function(app_drawer.DrawerFollowedNoteItem) onItemTap;

  @override
  State<_CollapsibleFollowingSection> createState() =>
      _CollapsibleFollowingSectionState();
}

class _CollapsibleFollowingSectionState
    extends State<_CollapsibleFollowingSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header with toggle ───────────────────────────────────
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.drawerFollowingNotes,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: AppColors.outline,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: widget.onAdd,
                  child: const Icon(Icons.add_rounded,
                      size: 18, color: AppColors.outline),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: _expanded ? 0 : -0.25,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.keyboard_arrow_down_rounded,
                      size: 18, color: AppColors.outline),
                ),
              ],
            ),
          ),
        ),
        // ── Expandable list ───────────────────────────────────────────────
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: _expanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: Column(
            children: [
              const SizedBox(height: 4),
              if (widget.items.isEmpty)
                _EmptyHint(AppLocalizations.of(context)!.drawerNoFollowedNotes)
              else
                ...widget.items.map(
                  (n) => _FollowedNoteRow(
                    item: n,
                    onTap: () => widget.onItemTap(n),
                  ),
                ),
            ],
          ),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ── Collapsible channel section ───────────────────────────────────────────────

class _CollapsibleChannelSection extends StatefulWidget {
  const _CollapsibleChannelSection({
    required this.items,
    required this.onAdd,
    required this.onItemTap,
  });

  final List<app_drawer.DrawerChannelItem> items;
  final VoidCallback onAdd;
  final ValueChanged<String> onItemTap;

  @override
  State<_CollapsibleChannelSection> createState() =>
      _CollapsibleChannelSectionState();
}

class _CollapsibleChannelSectionState
    extends State<_CollapsibleChannelSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.drawerChannels,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: AppColors.outline,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: widget.onAdd,
                  child: const Icon(Icons.add_rounded,
                      size: 18, color: AppColors.outline),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: _expanded ? 0 : -0.25,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.keyboard_arrow_down_rounded,
                      size: 18, color: AppColors.outline),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState:
              _expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: Column(
            children: [
              const SizedBox(height: 4),
              if (widget.items.isEmpty)
                _EmptyHint(l10n.drawerNoChannels)
              else
                ...widget.items.map(
                  (ch) => _ChannelRow(
                    channel: ch,
                    onTap: () => widget.onItemTap(ch.id),
                  ),
                ),
            ],
          ),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ── Channel row ────────────────────────────────────────────────────────────────

class _ChannelRow extends StatelessWidget {
  const _ChannelRow({required this.channel, required this.onTap});
  final app_drawer.DrawerChannelItem channel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(
          children: [
            const Icon(Icons.tag_rounded, size: 18, color: AppColors.outline),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                channel.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      channel.hasUnread ? FontWeight.w600 : FontWeight.w400,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
            if (channel.hasUnread)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── DM row ─────────────────────────────────────────────────────────────────────

class _DmRow extends StatelessWidget {
  const _DmRow({required this.dm, required this.onTap});
  final app_drawer.DrawerDmItem dm;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(
          children: [
            UserAvatar(seed: dm.pubkey, photoUrl: dm.avatarUrl, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                dm.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      dm.unreadCount > 0 ? FontWeight.w600 : FontWeight.w400,
                  color: AppColors.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (dm.unreadCount > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${dm.unreadCount}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── App row ────────────────────────────────────────────────────────────────────

class _AppRow extends StatelessWidget {
  const _AppRow({
    required this.label,
    required this.gradient,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final Gradient gradient;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 14, color: AppColors.onPrimary),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty hint ─────────────────────────────────────────────────────────────────

class _EmptyHint extends StatelessWidget {
  const _EmptyHint(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.outlineVariant,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

// ── Footer ─────────────────────────────────────────────────────────────────────

class _DrawerFooter extends StatelessWidget {
  const _DrawerFooter({required this.onSettings});
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        border: Border(
          top: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: InkWell(
          onTap: onSettings,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                const Icon(Icons.settings_rounded,
                    size: 20, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.drawerSettings,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
