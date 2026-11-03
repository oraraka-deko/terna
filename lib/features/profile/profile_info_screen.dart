import 'package:flutter/material.dart';
import 'package:terna/core/constants/app_assets.dart';
import 'package:terna/core/theme/app_colors.dart';
import 'package:terna/core/widgets/story_avatar_widget.dart';
import '../../widgets/profile/profile_inventory_widget.dart';
import '../../widgets/profile/profile_stats_widget.dart';

enum ProfileType { personal, channel }

class ProfileInfoScreen extends StatefulWidget {
  final ProfileType type;
  final VoidCallback? onBack;
  final VoidCallback? onActionTap;

  const ProfileInfoScreen({
    super.key,
    this.type = ProfileType.personal,
    this.onBack,
    this.onActionTap,
  });

  @override
  State<ProfileInfoScreen> createState() => _ProfileInfoScreenState();
}

class _ProfileInfoScreenState extends State<ProfileInfoScreen> {
  int _selectedTabIndex = 0;

  bool get isPersonal => widget.type == ProfileType.personal;

  @override
  Widget build(BuildContext context) {
    final bgColor = isPersonal ? const Color(0xFFF2F2F7) : const Color(0xFF141416);
    final cardBgColor = isPersonal ? Colors.white : const Color(0xFF1C1C1E);
    final textPrimary = isPersonal ? Colors.black : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          // 1. Sliver App Bar with Themed Banner & Profile Avatar
          SliverAppBar(
            pinned: true,
            expandedHeight: isPersonal ? 330 : 290,
            backgroundColor: isPersonal ? const Color(0xFF4A90E2) : const Color(0xFF1C1C1E),
            leading: GestureDetector(
              onTap: widget.onBack,
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.white),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text('Edit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Header pattern
                  Opacity(
                    opacity: 0.18,
                    child: Image.asset(
                      isPersonal ? AppAssets.patternCatsInSpace : AppAssets.patternSeaLife,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),

                  // Profile Header Info
                  Positioned(
                    top: 80,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        // Avatar
                        StoryAvatarWidget(
                          assetPath: isPersonal ? AppAssets.avatarCat : AppAssets.avatarCallDuck,
                          size: 84,
                          hasStory: isPersonal,
                          isOnline: isPersonal,
                        ),

                        const SizedBox(height: 10),

                        // Title with Star / Verified
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isPersonal ? 'Cat' : 'Pavel Durov',
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 5),
                            if (isPersonal)
                              const Text('★', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold))
                            else ...[
                              Image.asset(AppAssets.giftSampleGold, width: 16, height: 16),
                              const SizedBox(width: 4),
                              const Icon(Icons.verified_rounded, color: Colors.white, size: 16),
                            ],
                          ],
                        ),

                        const SizedBox(height: 4),

                        // Subtitle
                        if (isPersonal)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                AppAssets.starLevel8,
                                width: 18,
                                height: 18,
                                errorBuilder: (_, _, _) => Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(4)),
                                  child: const Text('8', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'last seen just now',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            '10,288,126 subscribers',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),

                        const SizedBox(height: 14),

                        // Action Buttons Bar (Call, Video, Mute, Search, More)
                        _buildActionButtons(),
                      ],
                    ),
                  ),

                  // Bottom Music Bar on Cat Profile
                  if (isPersonal)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        color: Colors.black.withValues(alpha: 0.2),
                        child: const Row(
                          children: [
                            Icon(Icons.music_note_rounded, size: 18, color: Color(0xFF34C759)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'project x - halfadedd',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, size: 18, color: Colors.white70),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 2. Info Cards Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  if (isPersonal) ...[
                    // Cat Personal Channel Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardBgColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF3390EC),
                            ),
                            child: const Icon(Icons.link_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Cats's head 🔗",
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '17 173 subscribers',
                                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text('12', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Cat Details Card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: cardBgColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('+888 888 888', style: TextStyle(fontSize: 15, color: AppColors.primaryBlue)),
                          Text('Mobile', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          Divider(height: 16),
                          Text('@cat', style: TextStyle(fontSize: 15, color: AppColors.primaryBlue)),
                          Text('Username', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          Divider(height: 16),
                          Text('6 Jul', style: TextStyle(fontSize: 15, color: AppColors.textPrimary)),
                          Text('Birthday', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Durov Channel Info Card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: cardBgColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('https://t.me/durov', style: TextStyle(fontSize: 15, color: AppColors.primaryBlue)),
                          Text('share link', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          Divider(height: 18),
                          Text('Founder of Telegram.', style: TextStyle(fontSize: 14.5, color: Colors.white)),
                          Text('description', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Tab Segment Bar (Posts, Gifts, Media, Files/Links, Music)
                  _buildTabBar(textPrimary),
                ],
              ),
            ),
          ),

          // 3. Dynamic Tab Content (Stats on Posts, Showcase on Gifts, Media on Media)
          if (_selectedTabIndex == 0) ...[
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: ProfileStatsWidget(),
              ),
            ),
          ] else if (_selectedTabIndex == 1) ...[
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: ProfileInventoryWidget(),
              ),
            ),
          ],
          _buildMediaGrid(),

          const SliverToBoxAdapter(
            child: SizedBox(height: 60),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final actions = isPersonal
        ? [
            {'icon': Icons.phone, 'label': 'call'},
            {'icon': Icons.videocam, 'label': 'video'},
            {'icon': Icons.volume_off, 'label': 'mute'},
            {'icon': Icons.search, 'label': 'search'},
            {'icon': Icons.more_horiz, 'label': 'more'},
          ]
        : [
            {'icon': Icons.chat_bubble_outline_rounded, 'label': 'message'},
            {'icon': Icons.volume_off, 'label': 'mute'},
            {'icon': Icons.search, 'label': 'search'},
            {'icon': Icons.more_horiz, 'label': 'more'},
          ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: actions.map((act) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.24),
                  shape: BoxShape.circle,
                ),
                child: Icon(act['icon'] as IconData, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 4),
              Text(
                act['label'] as String,
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTabBar(Color textColor) {
    final tabs = isPersonal
        ? ['Posts', 'Gifts', 'Media', 'Links', 'Music']
        : ['Posts', 'Gifts', 'Media', 'Files', 'Music'];

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: isPersonal ? const Color(0xFFE5E5EA) : const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTabIndex = index;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isPersonal ? Colors.white : const Color(0xFF636366))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tabs[index],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isPersonal ? Colors.black : Colors.white,
                      ),
                    ),
                    if (!isPersonal && tabs[index] == 'Gifts') ...[
                      const SizedBox(width: 3),
                      Image.asset(AppAssets.giftSampleGold, width: 11, height: 11),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMediaGrid() {
    final crossAxisCount = isPersonal ? 2 : 3;
    final images = [
      AppAssets.patternParis,
      AppAssets.patternCatsInSpace,
      AppAssets.patternAnimals,
      AppAssets.patternSeaLife,
      AppAssets.patternStarWars,
      AppAssets.avatarTravelDuckParis,
    ];

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 3,
          mainAxisSpacing: 3,
          childAspectRatio: isPersonal ? 1.0 : 0.85,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final img = images[index % images.length];
            return Container(
              color: Colors.grey.shade800,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    img,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Center(
                      child: Icon(Icons.image, color: Colors.white54),
                    ),
                  ),
                  if (!isPersonal)
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_arrow_rounded, color: Colors.white, size: 12),
                            SizedBox(width: 2),
                            Text('0:16', style: TextStyle(color: Colors.white, fontSize: 9.5)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
          childCount: 6,
        ),
      ),
    );
  }
}
