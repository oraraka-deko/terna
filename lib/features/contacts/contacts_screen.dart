import 'package:flutter/material.dart';
import 'package:terna/core/constants/app_assets.dart';
import 'package:terna/core/theme/app_colors.dart';
import 'package:terna/core/widgets/name_with_badges_row.dart';
import 'package:terna/core/widgets/story_avatar_widget.dart';

class ContactItemData {
  final String name;
  final String? avatarAsset;
  final String? initialLetter;
  final String status;
  final bool isOnline;
  final bool hasStoryRing;
  final bool hasStar;
  final String? giftBadge;
  final VoidCallback? onTap;

  const ContactItemData({
    required this.name,
    this.avatarAsset,
    this.initialLetter,
    required this.status,
    this.isOnline = false,
    this.hasStoryRing = false,
    this.hasStar = false,
    this.giftBadge,
    this.onTap,
  });
}

class ContactsScreen extends StatelessWidget {
  final ValueChanged<String>? onContactTap;
  final VoidCallback? onSortTap;
  final VoidCallback? onAddTap;

  const ContactsScreen({
    super.key,
    this.onContactTap,
    this.onSortTap,
    this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    final contacts = [
      ContactItemData(
        name: 'Penguin',
        avatarAsset: AppAssets.avatarPenguin,
        status: 'online',
        isOnline: true,
        hasStoryRing: true,
        giftBadge: AppAssets.giftSampleFrog,
        onTap: () => onContactTap?.call('Penguin'),
      ),
      ContactItemData(
        name: 'Dolphin',
        avatarAsset: AppAssets.avatarDolphin,
        status: 'online',
        isOnline: true,
        giftBadge: AppAssets.giftSampleBadge,
        onTap: () => onContactTap?.call('Dolphin'),
      ),
      ContactItemData(
        name: 'Dog',
        avatarAsset: AppAssets.avatarDog,
        status: 'last seen 3 minutes ago',
        onTap: () => onContactTap?.call('Dog'),
      ),
      ContactItemData(
        name: 'Cat',
        avatarAsset: AppAssets.avatarCat,
        status: 'last seen 4 minutes ago',
        onTap: () => onContactTap?.call('Cat'),
      ),
      ContactItemData(
        name: 'Elephant',
        initialLetter: 'E',
        status: 'last seen 15 minutes ago',
        onTap: () => onContactTap?.call('Elephant'),
      ),
      ContactItemData(
        name: 'Pepe',
        avatarAsset: AppAssets.avatarPepe,
        status: 'last seen 37 minutes ago',
        hasStar: true,
        onTap: () => onContactTap?.call('Pepe'),
      ),
      ContactItemData(
        name: 'Giraffe',
        avatarAsset: AppAssets.avatarTravelDuckParis,
        status: 'last seen 2 hours ago',
        onTap: () => onContactTap?.call('Giraffe'),
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Top App Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 56, left: 16, right: 16, bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Sort pill button
                  GestureDetector(
                    onTap: onSortTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Text(
                        'Sort',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),

                  // Center Title
                  const Text(
                    'Contacts',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),

                  // Right (+) Circular Button
                  GestureDetector(
                    onTap: onAddTap,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF2F2F7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 20,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Invite Friends Action Row
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 12),
                InkWell(
                  onTap: () {},
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_add_alt_outlined,
                            color: AppColors.primaryBlue,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Text(
                          'Invite Friends',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 70),
                  child: Divider(height: 1, color: Color(0xFFE5E5EA)),
                ),
              ],
            ),
          ),

          // Contacts List
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = contacts[index];
                return Column(
                  children: [
                    InkWell(
                      onTap: item.onTap,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            StoryAvatarWidget(
                              assetPath: item.avatarAsset,
                              initialLetter: item.initialLetter,
                              size: 46,
                              hasStory: item.hasStoryRing,
                              isOnline: item.isOnline,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  NameWithBadgesRow(
                                    title: item.name,
                                    hasStar: item.hasStar,
                                    giftBadgeAsset: item.giftBadge,
                                    titleStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    item.status,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                      color: item.isOnline
                                          ? AppColors.primaryBlue
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 76),
                      child: Divider(height: 1, color: Color(0xFFE5E5EA)),
                    ),
                  ],
                );
              },
              childCount: contacts.length,
            ),
          ),

          // Bottom padding to avoid floating bottom nav bar overlap
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }
}

