import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uniun/core/scan/uniun_qr_payload.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/l10n/app_localizations.dart';

class UniunQrCard extends StatelessWidget {
  const UniunQrCard._({required String data, required String label})
      : _data = data,
        _label = label;

  factory UniunQrCard.user({
    required String name,
    required String pubkeyHex,
  }) =>
      UniunQrCard._(
        data: UniunQrPayload.encodeUser(name: name, pubkeyHex: pubkeyHex),
        label: 'UNIUN-U',
      );

  factory UniunQrCard.channel({
    required String name,
    required String about,
    required String channelId,
    required String creatorPubKey,
    String picture = '',
    int createdAt = 0,
  }) =>
      UniunQrCard._(
        data: UniunQrPayload.encodeChannel(
          channelId: channelId,
          creatorPubKey: creatorPubKey,
          name: name,
          about: about,
          picture: picture,
          createdAt: createdAt,
        ),
        label: 'UNIUN-C',
      );

  final String _data;
  final String _label;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Label ─────────────────────────────────────────────────────
            Text(
              _label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                letterSpacing: 2,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 12),

            // ── QR code ───────────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(16),
              child: QrImageView(
                data: _data,
                version: QrVersions.auto,
                errorCorrectionLevel: QrErrorCorrectLevel.M,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppColors.primary,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppColors.primary,
                ),
              ),
            ),

            const SizedBox(height: 10),
            Text(
              l10n.userCardScanHint,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
