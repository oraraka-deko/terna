import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:terna/core/constants/app_assets.dart';
import 'package:terna/core/theme/app_colors.dart';

class ChannelBroadcastScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onHeaderTap;

  const ChannelBroadcastScreen({
    super.key,
    this.onBack,
    this.onHeaderTap,
  });

  @override
  State<ChannelBroadcastScreen> createState() => _ChannelBroadcastScreenState();
}

class _ChannelBroadcastScreenState extends State<ChannelBroadcastScreen> {
  bool _isMuted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Subtle Channel Chat Wallpaper Background
          Positioned.fill(
            child: Container(
              color: const Color(0xFFE3EDD9),
              child: Opacity(
                opacity: 0.16,
                child: Image.asset(
                  AppAssets.patternParis,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),

          // 2. Broadcast Posts List
          Positioned.fill(
            child: ListView(
              padding: const EdgeInsets.only(top: 116, bottom: 95, left: 14, right: 14),
              children: [
                // Post 1: Media + Text + Reactions + Share
                _buildMediaPost(),

                const SizedBox(height: 14),

                // Centered Date Header Pill ("March 23")
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7A8B74).withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'March 23',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Post 2: Multi-paragraph broadcast text
                _buildTextBroadcastPost(),
              ],
            ),
          ),

          // 3. Floating Channel Header
          _buildFloatingChannelHeader(),

          // 4. Channel Bottom Bar (Comments/Gift, Mute, Search)
          _buildChannelBottomBar(),
        ],
      ),
    );
  }

  // Floating Channel Header
  Widget _buildFloatingChannelHeader() {
    return Positioned(
      top: 50,
      left: 14,
      right: 14,
      child: Row(
        children: [
          // Left back button with unread count (< 8)
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: GestureDetector(
                onTap: widget.onBack,
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.primaryBlue),
                      SizedBox(width: 4),
                      Text(
                        '8',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Center Pill: Pavel Durov + Gift + Verified + Subscribers
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: GestureDetector(
                  onTap: widget.onHeaderTap,
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Pavel Durov',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Image.asset(
                              AppAssets.giftSampleGold,
                              width: 14,
                              height: 14,
                              errorBuilder: (_, _, _) => const SizedBox.shrink(),
                            ),
                            const SizedBox(width: 3),
                            const Icon(
                              Icons.verified_rounded,
                              size: 14,
                              color: AppColors.primaryBlue,
                            ),
                          ],
                        ),
                        const Text(
                          '10,288,126 subscribers',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Right Circular Durov Avatar
          GestureDetector(
            onTap: widget.onHeaderTap,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF1C1C1E),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                AppAssets.avatarCallDuck,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Center(
                  child: Text('PD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Media Post 1
  Widget _buildMediaPost() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top screenshot image
                Container(
                  height: 190,
                  width: double.infinity,
                  color: const Color(0xFF1C1C1E),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        AppAssets.patternCatsInSpace,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.monetization_on_rounded, color: Colors.amber, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Telegram Ad Revenue Split',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Post Text
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Text(
                    'Starting today, channel owners can start receiving rewards for the ads shown in their channels. 50% of revenue goes directly to creators via the TON Blockchain! 🚀',
                    style: TextStyle(
                      fontSize: 14.5,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                ),

                // Reaction Pills Wrap
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildReactionPill(emoji: '⭐', count: '563', isHighlighted: true),
                      _buildReactionPill(emoji: '❤️', count: '312'),
                      _buildReactionPill(emoji: '🏆', count: '98'),
                      _buildReactionPill(emoji: '🔥', count: '65'),
                      _buildReactionPill(emoji: '😁', count: '51'),
                      _buildReactionPill(emoji: '🤡', count: '12'),
                    ],
                  ),
                ),

                // Footer (Views, Author, Timestamp)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Icon(Icons.remove_red_eye_outlined, size: 14, color: Color(0xFF8E8E93)),
                      const SizedBox(width: 4),
                      const Text(
                        '3,1M  Pavel Durov  9:41',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Detached Circular Share/Forward Button
        _buildForwardButton(),
      ],
    );
  }

  // Text Broadcast Post 2
  Widget _buildTextBroadcastPost() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Telegram has reached 950 million monthly active users! 🎆\n\nUp from 900M in the spring. We are on track to hit 1 BILLION this year. 💰\n\nThank you to everyone who chooses freedom, privacy, and seamless communication. The best is yet to come! 💪🙏',
                  style: TextStyle(
                    fontSize: 14.5,
                    color: AppColors.textPrimary,
                    height: 1.35,
                  ),
                ),

                const SizedBox(height: 10),

                // Reaction Pills Wrap
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildReactionPill(emoji: '🔥', count: '72K', isHighlighted: true),
                    _buildReactionPill(emoji: '❤️', count: '39,4K'),
                    _buildReactionPill(emoji: '🏆', count: '18,2K'),
                  ],
                ),

                const SizedBox(height: 8),

                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Icon(Icons.remove_red_eye_outlined, size: 14, color: Color(0xFF8E8E93)),
                    const SizedBox(width: 4),
                    const Text(
                      '1,6M  Pavel Durov  9:41',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 8),

        _buildForwardButton(),
      ],
    );
  }

  Widget _buildReactionPill({
    required String emoji,
    required String count,
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isHighlighted
            ? const Color(0xFFFFF1CC)
            : const Color(0xFFF0F5FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isHighlighted ? const Color(0xFFFFCC00) : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text(
            count,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: isHighlighted ? const Color(0xFF996500) : AppColors.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForwardButton() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
        Icons.reply_rounded,
        size: 20,
        color: AppColors.primaryBlue,
      ),
    );
  }

  // Channel Bottom Bar
  Widget _buildChannelBottomBar() {
    return Positioned(
      bottom: 24,
      left: 14,
      right: 14,
      child: Row(
        children: [
          // Left Pill: Comments + Gift
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.mode_comment_outlined, size: 20, color: Color(0xFF8E8E93)),
                    const SizedBox(width: 8),
                    Image.asset(
                      AppAssets.giftSampleGold,
                      width: 18,
                      height: 18,
                      errorBuilder: (_, _, _) => const Icon(Icons.card_giftcard, size: 18, color: Colors.amber),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Center Wide Glass Mute Button
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isMuted = !_isMuted;
                    });
                  },
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
                    ),
                    child: Text(
                      _isMuted ? 'Unmute' : 'Mute',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Right Circular Glass Search Button
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
                ),
                child: Center(
                  child: Image.asset(
                    AppAssets.symbolSearch,
                    width: 20,
                    height: 20,
                    errorBuilder: (_, _, _) => const Icon(Icons.search, size: 22, color: Color(0xFF8E8E93)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

