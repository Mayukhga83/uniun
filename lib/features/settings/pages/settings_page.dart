import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniun/l10n/app_localizations.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/common/widgets/drop_icon.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/features/settings/cubit/settings_cubit.dart';
import 'package:uniun/features/settings/cubit/storage_cubit.dart';
import 'package:uniun/features/settings/widgets/ai_card.dart';
import 'package:uniun/features/settings/widgets/cloud_provider_card.dart';
import 'package:uniun/features/settings/widgets/identity_card.dart';
import 'package:uniun/features/settings/widgets/mesh_card.dart';
import 'package:uniun/features/settings/widgets/profile_card.dart';
import 'package:uniun/features/settings/widgets/section_label.dart';
import 'package:uniun/features/settings/widgets/settings_app_bar.dart';
import 'package:uniun/features/settings/widgets/storage_card.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<SettingsCubit>()),
        BlocProvider(create: (_) => getIt<StorageCubit>()),
      ],
      child: const _SettingsContent(),
    );
  }
}

class _SettingsContent extends StatelessWidget {
  const _SettingsContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: SettingsAppBar(title: AppLocalizations.of(context)!.settingsTitle),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          final l10n = AppLocalizations.of(context)!;
          return ListView(
            padding: const EdgeInsets.only(
              top: 16,
              left: 20,
              right: 20,
              bottom: 48,
            ),
            children: [
              // ── Account ───────────────────────────────────────────────────
              SettingsSectionLabel(l10n.settingsAccount),
              const SizedBox(height: 12),
              ProfileCard(state: state),

              const SizedBox(height: 16),

              // ── Identity ──────────────────────────────────────────────────
              SettingsSectionLabel(
                l10n.settingsIdentity,
                icon: Icons.lock_outline_rounded,
              ),
              const SizedBox(height: 12),
              IdentityCard(state: state),

              const SizedBox(height: 16),

              // ── AI · Shiv ─────────────────────────────────────────────────
              SettingsSectionLabel(
                l10n.settingsAiShiv,
                leading: const DropIcon(
                  size: 14,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              const AICard(),

              const SizedBox(height: 16),

              // ── Cloud AI ──────────────────────────────────────────────────
              SettingsSectionLabel(
                l10n.settingsCloudProvider,
                icon: Icons.cloud_outlined,
              ),
              const SizedBox(height: 12),
              const CloudProviderCard(),

              const SizedBox(height: 16),

              // ── Storage ───────────────────────────────────────────────────
              SettingsSectionLabel(
                l10n.settingsStorage,
                icon: Icons.storage_rounded,
              ),
              const SizedBox(height: 12),
              const StorageCard(),

              const SizedBox(height: 16),

              // ── Nearby Sync ───────────────────────────────────────────────
              SettingsSectionLabel(
                l10n.settingsNearbySync,
                icon: Icons.wifi_tethering_rounded,
              ),
              const SizedBox(height: 12),
              const MeshCard(),

              const SizedBox(height: 36),

              // ── Version ───────────────────────────────────────────────────
              Center(
                child: Text(
                  l10n.appVersion,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.4,
                    color: AppColors.outline,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
