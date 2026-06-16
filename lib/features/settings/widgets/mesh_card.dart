import 'package:flutter/material.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/data/datasources/app_settings_store.dart';
import 'package:uniun/features/mesh/service/mesh_service.dart';
import 'package:uniun/l10n/app_localizations.dart';

/// Settings card toggling the offline nearby-device mesh on/off and showing the
/// live connected-peer count. Starting/stopping the [MeshService] is idempotent.
class MeshCard extends StatefulWidget {
  const MeshCard({super.key});

  @override
  State<MeshCard> createState() => _MeshCardState();
}

class _MeshCardState extends State<MeshCard> {
  late bool _enabled = getIt<AppSettingsStore>().meshEnabled;

  Future<void> _toggle(bool value) async {
    setState(() => _enabled = value);
    await getIt<AppSettingsStore>().setMeshEnabled(value);
    final mesh = getIt<MeshService>();
    if (value) {
      mesh.start();
    } else {
      await mesh.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mesh = getIt<MeshService>();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.meshTitle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.meshSubtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Switch(
                value: _enabled,
                activeThumbColor: AppColors.primary,
                onChanged: _toggle,
              ),
            ],
          ),
          if (_enabled) ...[
            const SizedBox(height: 14),
            ValueListenableBuilder<int>(
              valueListenable: mesh.connectedPeers,
              builder: (_, count, __) {
                final on = count > 0;
                return Row(
                  children: [
                    Icon(
                      on
                          ? Icons.wifi_tethering_rounded
                          : Icons.wifi_tethering_off_rounded,
                      size: 16,
                      color: on ? AppColors.primary : AppColors.outline,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.meshConnected(count),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: on ? AppColors.primary : AppColors.outline,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
