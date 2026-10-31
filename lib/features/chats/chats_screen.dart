import 'package:flutter/material.dart';
import 'package:terna/core/constants/app_assets.dart';
import 'package:terna/core/theme/app_colors.dart';
import 'package:terna/core/widgets/name_with_badges_row.dart';
import 'package:terna/core/widgets/story_avatar_widget.dart';

class ChatListItemData {
  final String id;
  final String title;
  final String? subtitle;
  final String? senderName;
  final String time;
  final String? avatarAsset;
  final bool isPinned;
  final bool hasStar;
  final bool isVerified;
  final bool isMuted;
  final bool isLive;
  final bool hasStoryRing;
  final bool isOnline;
  final int unreadCount;
  final bool isUnreadMuted;
  final bool hasReadChecks;
  final String? giftBadge;
  final bool isWallet;
  final bool isSavedMessages;
  final String? previewImage;

  const ChatListItemData({
    required this.id,
    required this.title,
    this.subtitle,
    this.senderName,
    required this.time,
    this.avatarAsset,
    this.isPinned = false,
    this.hasStar = false,
    this.isVerified = false,
    this.isMuted = false,
    this.isLive = false,
    this.hasStoryRing = false,
    this.isOnline = false,
    this.unreadCount = 0,
    this.isUnreadMuted = false,
    this.hasReadChecks = false,
    this.giftBadge,
    this.isWallet = false,
    this.isSavedMessages = false,
    this.previewImage,
  });
}

class ChatsScreen extends StatefulWidget {
  final ValueChanged<ChatListItemData>? onChatTap;
  final ValueChanged<String>? onAvatarTap;
  final VoidCallback? onEditTap;
  final VoidCallback? onComposeTap;

  const ChatsScreen({
    super.key,
    this.onChatTap,
    this.onAvatarTap,
    this.onEditTap,
    this.onComposeTap,
  });

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  bool _isStoriesExpanded = false;
  int _selectedFolderIndex = 0;

  final List<String> _folders = ['All', 'Groups 6', 'WORK 2', 'Bots'];

  @override
  Widget build(BuildContext context) {
    final chatItems = [
      const ChatListItemData(
        id: 'saved_messages',
        title: 'Saved Messages',
        subtitle: 'IMG_420.png',
        time: 'Fri',
        isPinned: true,
        isSavedMessages: true,
      ),
      const ChatListItemData(
        id: 'cat',
        title: 'Cat',
        subtitle: 'Pepe says hi.',
        time: '9:41',
        avatarAsset: AppAssets.avatarCat,
        isPinned: true,
        hasStar: true,
        hasStoryRing: true,
        isOnline: true,
        hasReadChecks: true,
      ),
      const ChatListItemData(
        id: 'pepe',
        title: 'Pepe',
        subtitle: 'Say hello to Cat.',
        time: '9:41',
        avatarAsset: AppAssets.avatarPepe,
        hasStoryRing: true,
        giftBadge: AppAssets.statusOther,
        unreadCount: 1,
      ),
      const ChatListItemData(
        id: '16bit_team',
        title: '16Bit Team',
        subtitle: '16Bit Team started a Live Stream',
        time: '9:41',
        avatarAsset: AppAssets.avatarTravelDuckParis,
        isLive: true,
        isMuted: true,
        unreadCount: 1,
        isUnreadMuted: true,
      ),
      const ChatListItemData(
        id: 'digital_nomads',
        title: 'Digital Nomads',
        senderName: 'Pepe',
        subtitle: 'We just reached 2,500 members! WOO!',
        time: '9:22',
        avatarAsset: AppAssets.avatarDino,
        isMuted: true,
      ),
      const ChatListItemData(
        id: 'dog',
        title: 'Dog',
        subtitle: 'Table for four, 2 PM be there',
        time: '9:12',
        avatarAsset: AppAssets.avatarDog,
        hasStoryRing: true,
        giftBadge: AppAssets.giftSampleBadge,
      ),
      const ChatListItemData(
        id: 'penguin',
        title: 'Penguin',
        subtitle: 'Check these out!',
        time: '8:28',
        avatarAsset: AppAssets.avatarPenguin,
        unreadCount: 1,
      ),
      const ChatListItemData(
        id: 'wallet',
        title: 'Wallet',
        subtitle: 'Welcome to Crypto Wallet!\n...',
        time: '8:12',
        isWallet: true,
        isVerified: true,
        hasReadChecks: true,
        unreadCount: 1,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Top Navigation Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 56, left: 16, right: 16, bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left "Edit" pill button
                  GestureDetector(
                    onTap: widget.onEditTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),

                  // Center Stories / Chats Title (interactive toggle)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      setState(() {
                        _isStoriesExpanded = !_isStoriesExpanded;
                      });
                    },
                    child: _isStoriesExpanded
                        ? _buildExpandedTitle()
                        : _buildCollapsedStoriesTitle(),
                  ),

                  // Right Combined Action Pill (Add Story + Compose)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isStoriesExpanded = !_isStoriesExpanded;
                            });
                          },
                          child: const Icon(
                            Icons.add_circle_outline_rounded,
                            size: 20,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: widget.onComposeTap,
                          child: const Icon(
                            Icons.edit_square,
                            size: 19,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanded Story Tray (State B)
          if (_isStoriesExpanded)
            SliverToBoxAdapter(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 98,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  children: [
                    _buildStoryTrayItem(
                      name: 'My Story',
                      asset: AppAssets.avatarDino,
                      hasAddBadge: true,
                    ),
                    _buildStoryTrayItem(
                      name: '16Bit Team',
                      asset: AppAssets.avatarTravelDuckParis,
                      isLive: true,
                    ),
                    _buildStoryTrayItem(
                      name: 'Dog',
                      asset: AppAssets.avatarDog,
                      hasRing: true,
                    ),
                    _buildStoryTrayItem(
                      name: 'Pepe',
                      asset: AppAssets.avatarPepe,
                      hasRing: true,
                    ),
                    _buildStoryTrayItem(
                      name: 'Cat',
                      asset: AppAssets.avatarCat,
                      hasRing: true,
                    ),
                  ],
                ),
              ),
            ),

          // Folder Filter Pill Bar
          SliverToBoxAdapter(
            child: Container(
              height: 38,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                color: const Color(0xFFEFEFF4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: List.generate(_folders.length, (index) {
                  final isSelected = _selectedFolderIndex == index;
                  final folderTitle = _folders[index];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedFolderIndex = index;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  )
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: _buildFolderLabel(folderTitle, isSelected),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          // Chats List View
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = chatItems[index];
                return _buildChatRow(item);
              },
              childCount: chatItems.length,
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  // Collapsed Header Center (3 overlapping mini avatars + "Chats ★")
  Widget _buildCollapsedStoriesTitle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 48,
          height: 26,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                child: StoryAvatarWidget(
                  assetPath: AppAssets.avatarTravelDuckParis,
                  size: 24,
                  isLive: true,
                ),
              ),
              Positioned(
                left: 12,
                child: StoryAvatarWidget(
                  assetPath: AppAssets.avatarDog,
                  size: 24,
                  hasStory: true,
                ),
              ),
              Positioned(
                left: 24,
                child: StoryAvatarWidget(
                  assetPath: AppAssets.avatarPepe,
                  size: 24,
                  hasStory: true,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        const Text(
          'Chats',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(width: 3),
        const Text(
          '★',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlue,
          ),
        ),
      ],
    );
  }

  // Expanded Header Center ("Chats ★")
  Widget _buildExpandedTitle() {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Chats',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        SizedBox(width: 3),
        Text(
          '★',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlue,
          ),
        ),
      ],
    );
  }

  // Single Story item in expanded tray
  Widget _buildStoryTrayItem({
    required String name,
    required String asset,
    bool hasAddBadge = false,
    bool isLive = false,
    bool hasRing = false,
  }) {
    return Container(
      width: 68,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          StoryAvatarWidget(
            assetPath: asset,
            size: 56,
            hasAddBadge: hasAddBadge,
            isLive: isLive,
            hasStory: hasRing,
            onTap: () => widget.onAvatarTap?.call(name),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // Folder tab label with badge styling
  Widget _buildFolderLabel(String title, bool isSelected) {
    if (title.contains('Groups')) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Groups',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0xFFD1D1D6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '6',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      );
    } else if (title.contains('WORK')) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'WORK',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '2',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      );
    }
    return Text(
      title,
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        color: AppColors.textPrimary,
      ),
    );
  }

  // Chat row widget
  Widget _buildChatRow(ChatListItemData item) {
    return Container(
      color: item.isPinned ? AppColors.pinnedTint : Colors.white,
      child: Column(
        children: [
          InkWell(
            onTap: () => widget.onChatTap?.call(item),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar
                  if (item.isSavedMessages)
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF5AC8FA), Color(0xFF007AFF)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: const Icon(
                        Icons.bookmark_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    )
                  else if (item.isWallet)
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF3390EC),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    )
                  else
                    StoryAvatarWidget(
                      assetPath: item.avatarAsset,
                      size: 52,
                      hasStory: item.hasStoryRing,
                      isLive: item.isLive,
                      isOnline: item.isOnline,
                      onTap: () => widget.onAvatarTap?.call(item.title),
                    ),

                  const SizedBox(width: 12),

                  // Chat Title + Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            NameWithBadgesRow(
                              title: item.title,
                              hasStar: item.hasStar,
                              isVerified: item.isVerified,
                              isMuted: item.isMuted,
                              giftBadgeAsset: item.giftBadge,
                              titleStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),

                            // Time + Read Checks
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (item.hasReadChecks) ...[
                                  const Icon(
                                    Icons.done_all_rounded,
                                    size: 15,
                                    color: AppColors.primaryBlue,
                                  ),
                                  const SizedBox(width: 3),
                                ],
                                Text(
                                  item.time,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 3),

                        // Subtitle & Trailing Action / Badges
                        Row(
                          children: [
                            Expanded(
                              child: item.isSavedMessages
                                  ? Row(
                                      children: [
                                        Container(
                                          width: 16,
                                          height: 16,
                                          margin: const EdgeInsets.only(right: 5),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade400,
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                          child: const Icon(Icons.image, size: 12, color: Colors.white),
                                        ),
                                        Text(
                                          item.subtitle ?? '',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (item.senderName != null)
                                          Text(
                                            item.senderName!,
                                            style: const TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        Text(
                                          item.subtitle ?? '',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),

                            // Pinned pin icon or Unread Badge or Wallet OPEN button
                            if (item.isPinned) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.push_pin,
                                size: 15,
                                color: Color(0xFFC7C7CC),
                              ),
                            ],

                            if (item.isWallet) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'OPEN',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],

                            if (item.unreadCount > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: item.isUnreadMuted
                                      ? const Color(0xFFC7C7CC)
                                      : AppColors.primaryBlue,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${item.unreadCount}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.only(left: 78),
            child: Divider(height: 1, color: Color(0xFFE5E5EA)),
          ),
        ],
      ),
    );
  }
}

