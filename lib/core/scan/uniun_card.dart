import 'package:flutter/material.dart';
import 'package:uniun/core/scan/uniun_payload.dart';
import 'package:uniun/core/theme/app_theme.dart';

class UniunCard extends StatelessWidget {
  const UniunCard._({required UniunEncoded encoded}) : _encoded = encoded;

  factory UniunCard.user({
    required String name,
    required String pubkeyHex,
  }) =>
      UniunCard._(
        encoded: UniunPayload.encodeUser(name: name, pubkeyHex: pubkeyHex),
      );

  factory UniunCard.channel({
    required String name,
    required String about,
    required String channelId,
    required String creatorPubKey,
    String picture = '',
    int createdAt = 0,
  }) =>
      UniunCard._(
        encoded: UniunPayload.encodeChannel(
          channelId: channelId,
          creatorPubKey: creatorPubKey,
          name: name,
          about: about,
          picture: picture,
          createdAt: createdAt,
        ),
      );

  final UniunEncoded _encoded;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Magic label — separate from the grid ──────────────────────
            Text(
              _encoded.magic,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 10),
            // ── Base64 grid — square, primary colour ──────────────────────
            AspectRatio(
              aspectRatio: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(16),
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Text(
                    _encoded.grid,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: Colors.white,
                      height: 1.55,
                      letterSpacing: 1.6,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
