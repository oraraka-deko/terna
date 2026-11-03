import 'package:flutter/material.dart';
import 'package:terna/core/theme/app_colors.dart';
import 'safe_avatar_image.dart';

class StoryAvatarWidget extends StatelessWidget {
  final String? assetPath;
  final String? initialLetter;
  final double size;
  final bool hasStory;
  final bool isLive;
  final bool isOnline;
  final bool hasAddBadge;
  final VoidCallback? onTap;

  const StoryAvatarWidget({
    super.key,
    this.assetPath,
    this.initialLetter,
    this.size = 54,
    this.hasStory = false,
    this.isLive = false,
    this.isOnline = false,
    this.hasAddBadge = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ringPadding = (hasStory || isLive) ? 3.5 : 0.0;
    final innerAvatarSize = size - (ringPadding * 2);

    Widget avatarContent;

    if (initialLetter != null && initialLetter!.isNotEmpty) {
      avatarContent = Container(
        width: innerAvatarSize,
        height: innerAvatarSize,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFF5AC8FA), Color(0xFF007AFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          initialLetter!,
          style: TextStyle(
            color: Colors.white,
            fontSize: innerAvatarSize * 0.45,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else if (assetPath != null && assetPath!.trim().isNotEmpty) {
      avatarContent = SafeAvatarImage(
        imageSource: assetPath,
        size: innerAvatarSize,
        shape: BoxShape.circle,
        fallback: Container(
          width: innerAvatarSize,
          height: innerAvatarSize,
          color: Colors.grey.shade300,
          child: Icon(Icons.person, size: innerAvatarSize * 0.6, color: Colors.grey.shade600),
        ),
      );
    } else {
      avatarContent = Container(
        width: innerAvatarSize,
        height: innerAvatarSize,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.person, size: innerAvatarSize * 0.6, color: Colors.grey.shade600),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Outer Story Highlight Ring
            if (isLive)
              Container(
                width: size,
                height: size,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      Color(0xFFFF2D55),
                      Color(0xFFFF375F),
                      Color(0xFFFF7597),
                      Color(0xFFFF2D55),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(2.5),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  padding: const EdgeInsets.all(1.5),
                  child: avatarContent,
                ),
              )
            else if (hasStory)
              Container(
                width: size,
                height: size,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      Color(0xFF34C759),
                      Color(0xFF30D158),
                      Color(0xFF007AFF),
                      Color(0xFF5AC8FA),
                      Color(0xFF34C759),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(2.5),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  padding: const EdgeInsets.all(1.5),
                  child: avatarContent,
                ),
              )
            else
              avatarContent,

            // Live tag badge at bottom center
            if (isLive)
              Positioned(
                bottom: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF2D55),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

            // Online green indicator dot at bottom right
            if (isOnline)
              Positioned(
                right: 1,
                bottom: 1,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.onlineDot,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.2),
                  ),
                ),
              ),

            // Add (+) story button badge at bottom right
            if (hasAddBadge)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 13,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
