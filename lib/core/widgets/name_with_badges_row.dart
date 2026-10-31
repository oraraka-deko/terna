import 'package:flutter/material.dart';
import 'package:terna/core/constants/app_assets.dart';
import 'package:terna/core/theme/app_colors.dart';

class NameWithBadgesRow extends StatelessWidget {
  final String title;
  final TextStyle? titleStyle;
  final bool hasStar;
  final Color starColor;
  final String? giftBadgeAsset;
  final bool isVerified;
  final bool isMuted;
  final Widget? trailingBadge;

  const NameWithBadgesRow({
    super.key,
    required this.title,
    this.titleStyle,
    this.hasStar = false,
    this.starColor = AppColors.primaryBlue,
    this.giftBadgeAsset,
    this.isVerified = false,
    this.isMuted = false,
    this.trailingBadge,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: titleStyle ??
                const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
          ),
        ),

        // Star badge (e.g., Cat ★, Dinosaur ★, Pepe ★)
        if (hasStar) ...[
          const SizedBox(width: 4),
          Text(
            '★',
            style: TextStyle(
              color: starColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],

        // Collectible gift badge (e.g., Penguin frog icon, Durov gold gift)
        if (giftBadgeAsset != null) ...[
          const SizedBox(width: 4),
          Image.asset(
            giftBadgeAsset!,
            width: 17,
            height: 17,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ],

        // Verified checkmark badge
        if (isVerified) ...[
          const SizedBox(width: 4),
          Image.asset(
            AppAssets.symbolVerify,
            width: 15,
            height: 15,
            errorBuilder: (_, _, _) => const Icon(
              Icons.verified_rounded,
              color: AppColors.primaryBlue,
              size: 15,
            ),
          ),
        ],

        // Muted speaker symbol
        if (isMuted) ...[
          const SizedBox(width: 4),
          const Icon(
            Icons.volume_off_rounded,
            size: 14,
            color: AppColors.textSecondary,
          ),
        ],

        if (trailingBadge != null) ...[
          const SizedBox(width: 4),
          trailingBadge!,
        ],
      ],
    );
  }
}

