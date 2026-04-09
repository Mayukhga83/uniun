import 'package:avatar_plus/avatar_plus.dart';
import 'package:flutter/material.dart';
import 'package:uniun/core/theme/app_theme.dart';

/// Avatar widget used during onboarding.
///
/// Always seeded from [seed] (the user's pubkeyHex, optionally with a variant
/// suffix like `pubkeyHex_v2`). The seed is the same format used by
/// [UserAvatar] throughout the rest of the app, so what the user sees here
/// is exactly what they'll see in the feed and settings.
///
/// Tapping the shuffle button cycles to the next avatar variant via [onShuffle].
class GeneratedAvatar extends StatelessWidget {
  const GeneratedAvatar({
    super.key,
    required this.seed,
    required this.onShuffle,
    this.size = 96,
  });

  final String seed;
  final VoidCallback onShuffle;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // ── Avatar circle ─────────────────────────────────────────────────
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: AvatarPlus(
            seed.isEmpty ? 'uniun' : seed,
            width: size,
            height: size,
            trBackground: false,
          ),
        ),

        // ── Camera button (bottom-right) — future Blossom upload ─────────
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: () {
              // TODO: image_picker → Blossom upload
            },
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_a_photo_rounded,
                size: 13,
                color: AppColors.primary,
              ),
            ),
          ),
        ),

        // ── Shuffle button (bottom-left) ──────────────────────────────────
        Positioned(
          bottom: 0,
          left: 0,
          child: GestureDetector(
            onTap: onShuffle,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.shuffle_rounded,
                size: 13,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
