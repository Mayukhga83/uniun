import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:uniun/l10n/app_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/domain/entities/profile/profile_entity.dart';
import 'package:uniun/domain/repositories/event_queue_repository.dart';
import 'package:uniun/domain/usecases/profile_usecases.dart';
import 'package:uniun/domain/usecases/user_usecases.dart';
import 'package:nostr/nostr.dart';
import 'package:uniun/features/onboarding/widgets/key_card.dart';
import 'package:uniun/features/onboarding/widgets/onboarding_app_bar.dart';

/// Shows the generated npub + nsec after profile setup.
/// Route args: Map{'npub': String, 'nsec': String}
///
/// Step-based reveal:
///   Step 0 — public key only (must copy to proceed)
///   Step 1 — private key revealed after pub is copied (must copy to proceed)
///   Step 2 — Save & Continue enabled after both keys copied
class YourIdentityKeysPage extends StatefulWidget {
  const YourIdentityKeysPage({super.key, this.args});

  final Map? args;

  @override
  State<YourIdentityKeysPage> createState() => _YourIdentityKeysPageState();
}

class _YourIdentityKeysPageState extends State<YourIdentityKeysPage> {
  bool _pubKeyCopied = false;
  bool _privKeyCopied = false;
  bool _nsecVisible = false;
  bool _termsAccepted = false;

  Future<void> _saveAndContinue(BuildContext context, Map args, String nsec) async {
    final l10n = AppLocalizations.of(context)!;
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await getIt<ImportKeyUseCase>().call(nsec);
    if (!mounted) return;
    await result.fold(
      (failure) async => messenger.showSnackBar(
        SnackBar(content: Text(l10n.keysFailedToSave(failure.toMessage()))),
      ),
      (user) async {
        // Save profile data collected in AboutYouPage
        final displayName = args['displayName'] as String? ?? '';
        final username = args['username'] as String? ?? '';
        final bio = args['bio'] as String? ?? '';
        // avatarSeed is only set when user shuffled away from the default.
        // Store as 'generated:<seed>' so UserAvatar can detect and use it.
        final avatarSeed = args['avatarSeed'] as String?;
        final avatarUrl = avatarSeed != null ? 'generated:$avatarSeed' : null;
        if (displayName.isNotEmpty || username.isNotEmpty) {
          final profile = ProfileEntity(
            pubkey: user.pubkeyHex,
            name: displayName.isEmpty ? null : displayName,
            username: username.isEmpty ? null : username,
            about: bio.isEmpty ? null : bio,
            avatarUrl: avatarUrl,
            updatedAt: DateTime.now(),
            lastSeenAt: DateTime(3000, 6, 1),
          );
          await getIt<SaveProfileUseCase>().call(profile);
          await _enqueueKind0MetadataEvent(user.nsec, profile);
        }
        if (!mounted) return;
        router.goNamed(AppRoutes.home);
      },
    );
  }

  Future<void> _enqueueKind0MetadataEvent(String nsec, ProfileEntity profile) async {
    final privkeyHex = nsec.startsWith('nsec1') ? Nip19.decodePrivkey(nsec) : nsec;
    if (privkeyHex.isEmpty) return;

    final metadata = <String, dynamic>{
      if (profile.name != null) 'display_name': profile.name,
      if (profile.username != null) 'name': profile.username,
      if (profile.about != null) 'about': profile.about,
      if (profile.avatarUrl != null) 'picture': profile.avatarUrl,
      if (profile.nip05 != null) 'nip05': profile.nip05,
    };

    final event = Event.from(
      privkey: privkeyHex,
      kind: 0,
      content: jsonEncode(metadata),
      tags: const [],
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );

    await getIt<EventQueueRepository>().enqueueSignedEvent(
      eventId: event.id,
      authorPubkey: event.pubkey,
      sig: event.sig,
      kind: 0,
      eTagRefs: const [],
      pTagRefs: const [],
      tTags: const [],
      content: event.content,
      created: DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000),
    );
  }

  void _copyPub(String value) {
    final l10n = AppLocalizations.of(context)!;
    Clipboard.setData(ClipboardData(text: value));
    setState(() => _pubKeyCopied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.keysPublicCopied),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _copyPriv(String value) {
    final l10n = AppLocalizations.of(context)!;
    Clipboard.setData(ClipboardData(text: value));
    setState(() => _privKeyCopied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.keysPrivateCopied),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _downloadBackup(String npub, String nsec) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/uniun_keys_backup.txt');
      await file.writeAsString(
        'UNIUN Identity Backup\n'
        '=====================\n\n'
        'Public Key (npub):\n$npub\n\n'
        'Private Key (nsec):\n$nsec\n\n'
        'WARNING: Never share your private key with anyone.\n'
        'Lose this file = lose access to your account forever.\n',
      );
      if (!mounted) return;
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.keysBackupSaved(file.path))),
      );
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.keysBackupFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.args ?? {};
    final npub = args['npub'] as String? ?? 'npub1...';
    final nsec = args['nsec'] as String? ?? 'nsec1...';
    final canContinue = _pubKeyCopied && _privKeyCopied && _termsAccepted;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final h = constraints.maxHeight;
            final topGap = h < 680 ? 8.0 : 16.0;
            final midGap = h < 680 ? 8.0 : 12.0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OnboardingAppBar(onBack: () => Navigator.pop(context)),

                Expanded(
                  child: LayoutBuilder(
                    builder: (context, innerC) => SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: innerC.maxHeight),
                        child: IntrinsicHeight(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                        SizedBox(height: topGap),

                        Text(
                          l10n.keysTitle,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.6,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.keysSubtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),

                        SizedBox(height: midGap + 4),

                        KeyCard(
                          title: l10n.keysPublicKeyTitle,
                          subtitle: l10n.keysPublicKeySubtitle,
                          keyValue: npub,
                          icon: Icons.share_rounded,
                          iconColor: AppColors.primary,
                          iconBg: AppColors.primary.withValues(alpha: 0.08),
                          isSecret: false,
                          isVisible: true,
                          onToggle: null,
                          isCopied: _pubKeyCopied,
                          onCopy: () => _copyPub(npub),
                        ),

                        SizedBox(height: midGap),

                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _pubKeyCopied
                              ? KeyCard(
                                  key: const ValueKey('priv'),
                                  title: l10n.keysPrivateKeyTitle,
                                  subtitle: l10n.keysPrivateKeySubtitle,
                                  keyValue: nsec,
                                  icon: Icons.lock_rounded,
                                  iconColor: AppColors.error,
                                  iconBg:
                                      AppColors.error.withValues(alpha: 0.08),
                                  isSecret: true,
                                  isVisible: _nsecVisible,
                                  onToggle: () => setState(
                                      () => _nsecVisible = !_nsecVisible),
                                  isCopied: _privKeyCopied,
                                  onCopy: () => _copyPriv(nsec),
                                  warning: l10n.keysPrivateKeyWarning,
                                )
                              : const PrivKeyHint(key: ValueKey('hint')),
                        ),

                        const Spacer(),

                        _TermsCheckbox(
                          accepted: _termsAccepted,
                          onChanged: (v) =>
                              setState(() => _termsAccepted = v),
                          onOpenTerms: () => context.pushNamed(
                            AppRoutes.privacyPolicy,
                            extra: true,
                          ),
                          onOpenPrivacy: () =>
                              context.pushNamed(AppRoutes.privacyPolicy),
                        ),

                        SizedBox(height: midGap),

                        GestureDetector(
                          onTap: canContinue
                              ? () => _saveAndContinue(context, args, nsec)
                              : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: double.infinity,
                            height: 52,
                            decoration: BoxDecoration(
                              color: canContinue
                                  ? AppColors.primary
                                  : AppColors.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: canContinue
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.22),
                                        blurRadius: 20,
                                        offset: const Offset(0, 6),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                l10n.keysSaveAndContinue,
                                style: TextStyle(
                                  color: canContinue
                                      ? AppColors.onPrimary
                                      : AppColors.outline,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 4),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () => _downloadBackup(npub, nsec),
                              child: Text(
                                l10n.keysDownloadBackup,
                                style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12),
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.verified_user_rounded,
                                    size: 11, color: AppColors.outline),
                                const SizedBox(width: 4),
                                Text(
                                  l10n.keysE2eEncrypted,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1,
                                    color: AppColors.outline,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Terms & Conditions / Privacy Policy acceptance checkbox shown above the
/// Save & Continue button. Both labels are tappable and open the policy page.
class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({
    required this.accepted,
    required this.onChanged,
    required this.onOpenTerms,
    required this.onOpenPrivacy,
  });

  final bool accepted;
  final ValueChanged<bool> onChanged;
  final VoidCallback onOpenTerms;
  final VoidCallback onOpenPrivacy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const linkStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: AppColors.primary,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.primary,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: accepted,
            onChanged: (v) => onChanged(v ?? false),
            activeColor: AppColors.primary,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                l10n.keysAgreePrefix,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              GestureDetector(
                onTap: onOpenTerms,
                child: Text(l10n.keysAgreeTerms, style: linkStyle),
              ),
              Text(
                l10n.keysAgreeConjunction,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              GestureDetector(
                onTap: onOpenPrivacy,
                child: Text(l10n.keysAgreePrivacy, style: linkStyle),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
