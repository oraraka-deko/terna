import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:terna/core/constants/app_assets.dart';
import 'package:terna/core/theme/app_colors.dart';
import '../../screens/wallet/wallet_screen.dart';
import 'debug_balance_adjustment_screen.dart';
import '../../widgets/chat/gamer_bio_modal.dart';
import '../../widgets/profile/profile_inventory_widget.dart';
import '../../widgets/profile/profile_stats_widget.dart';
import '../../core/widgets/safe_avatar_image.dart';
import '../../models/chat/chat_models.dart';
import '../../services/chat/chat_service.dart';
import '../../services/wallet/wallet_repository.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onQrTap;
  final VoidCallback? onEditTap;
  final VoidCallback? onMyProfileTap;
  final VoidCallback? onWalletTap;
  final VoidCallback? onSavedMessagesTap;

  const SettingsScreen({
    super.key,
    this.onQrTap,
    this.onEditTap,
    this.onMyProfileTap,
    this.onWalletTap,
    this.onSavedMessagesTap,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFF4),
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          ValueListenableBuilder<GamerBioData>(
            valueListenable: ChatService().userBio,
            builder: (ctx, bio, _) {
              final wallet = WalletRepository();
              final currentName = bio.username.isNotEmpty ? bio.username : wallet.username.value;
              final currentAvatar = (bio.avatar != null && bio.avatar!.isNotEmpty)
                  ? bio.avatar!
                  : wallet.avatar.value;

              return SliverPersistentHeader(
                pinned: true,
                delegate: _SettingsHeaderDelegate(
                  onQrTap: widget.onQrTap,
                  onEditTap: widget.onEditTap,
                  username: currentName,
                  avatar: currentAvatar,
                ),
              );
            },
          ),

          // Inset Grouped Settings Cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // Gaming Performance Stats Card (from area_game profile)
                  const ProfileStatsWidget(),

                  const SizedBox(height: 14),

                  // Inventory & Collectibles Showcase Box (from area_game profile)
                  const ProfileInventoryWidget(),

                  const SizedBox(height: 14),

                  // Gamer Bio & Play Style Row
                  _buildCard(
                    children: [
                      _buildRow(
                        leading: _buildSquircleIcon(
                          color: const Color(0xFF9C27B0),
                          icon: Icons.sports_esports_rounded,
                        ),
                        title: 'Gamer Bio & Play Style',
                        trailingText: 'Tactical Striker 🎯',
                        showChevron: true,
                        onTap: () {
                          GamerBioModal.show(
                            context: context,
                            userId: 'terna_player_me',
                            defaultUsername: '@terna_player',
                          );
                        },
                      ),
                    ],
                  ),

                  if (kDebugMode) ...[
                    const SizedBox(height: 14),
                    _buildCard(
                      children: [
                        _buildRow(
                          leading: _buildSquircleIcon(
                            color: const Color(0xFFAF52DE),
                            icon: Icons.admin_panel_settings_rounded,
                          ),
                          title: 'Developer balance adjustment',
                          showChevron: true,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const DebugBalanceAdjustmentScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 14),

                  // Card 1: Set Emoji Status & Change Profile Photo
                  _buildCard(
                    children: [
                      _buildRow(
                        leading: const Icon(Icons.sentiment_satisfied_alt_rounded, color: AppColors.primaryBlue, size: 24),
                        title: 'Set Emoji Status',
                        showDivider: true,
                      ),
                      _buildRow(
                        leading: const Icon(Icons.add_a_photo_outlined, color: AppColors.primaryBlue, size: 23),
                        title: 'Change Profile Photo',
                        showDivider: false,
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Card 2: Add Account
                  _buildCard(
                    children: [
                      _buildRow(
                        leading: const Icon(Icons.add, color: AppColors.primaryBlue, size: 26),
                        title: 'Add Account',
                        titleColor: AppColors.primaryBlue,
                        showDivider: false,
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Card 3: My Profile
                  _buildCard(
                    children: [
                      _buildRow(
                        leading: _buildSquircleIcon(
                          color: const Color(0xFFFF2D55),
                          icon: Icons.person_rounded,
                        ),
                        title: 'My Profile',
                        showChevron: true,
                        onTap: widget.onMyProfileTap,
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Card 4: Wallet
                  _buildCard(
                    children: [
                      _buildRow(
                        leading: _buildSquircleIcon(
                          color: const Color(0xFF007AFF),
                          icon: Icons.account_balance_wallet_rounded,
                        ),
                        title: 'Wallet & TON Assets',
                        showChevron: true,
                        onTap: widget.onWalletTap ?? () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const WalletScreen()),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Card 5: Saved Messages, Recent Calls, Devices, Chat Folders
                  _buildCard(
                    children: [
                      _buildRow(
                        leading: _buildSquircleIcon(
                          color: const Color(0xFF007AFF),
                          icon: Icons.bookmark_rounded,
                        ),
                        title: 'Saved Messages',
                        showChevron: true,
                        showDivider: true,
                        onTap: widget.onSavedMessagesTap,
                      ),
                      _buildRow(
                        leading: _buildSquircleIcon(
                          color: const Color(0xFF34C759),
                          icon: Icons.phone_rounded,
                        ),
                        title: 'Recent Calls',
                        showChevron: true,
                        showDivider: true,
                      ),
                      _buildRow(
                        leading: _buildSquircleIcon(
                          color: const Color(0xFFFF9500),
                          icon: Icons.devices_rounded,
                        ),
                        title: 'Devices',
                        trailingText: '3',
                        showChevron: true,
                        showDivider: true,
                      ),
                      _buildRow(
                        leading: _buildSquircleIcon(
                          color: const Color(0xFF5AC8FA),
                          icon: Icons.folder_rounded,
                        ),
                        title: 'Chat Folders',
                        showChevron: true,
                        showDivider: false,
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Card 6: Notifications and Sounds
                  _buildCard(
                    children: [
                      _buildRow(
                        leading: _buildSquircleIcon(
                          color: const Color(0xFFFF3B30),
                          icon: Icons.notifications_rounded,
                        ),
                        title: 'Notifications and Sounds',
                        showChevron: true,
                        showDivider: false,
                      ),
                    ],
                  ),

                  const SizedBox(height: 110),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildRow({
    required Widget leading,
    required String title,
    Color? titleColor,
    String? trailingText,
    bool showChevron = false,
    bool showDivider = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Row(
              children: [
                leading,
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: titleColor ?? AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                if (trailingText != null) ...[
                  Text(
                    trailingText,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                if (showChevron)
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: Color(0xFFC7C7CC),
                  ),
              ],
            ),
          ),
          if (showDivider)
            const Padding(
              padding: EdgeInsets.only(left: 58),
              child: Divider(height: 1, color: Color(0xFFE5E5EA)),
            ),
        ],
      ),
    );
  }

  Widget _buildSquircleIcon({required Color color, required IconData icon}) {
    return Container(
      width: 29,
      height: 29,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 18,
      ),
    );
  }
}

class _SettingsHeaderDelegate extends SliverPersistentHeaderDelegate {
  final VoidCallback? onQrTap;
  final VoidCallback? onEditTap;
  final String username;
  final String avatar;

  _SettingsHeaderDelegate({
    this.onQrTap,
    this.onEditTap,
    this.username = 'Player',
    this.avatar = '',
  });

  @override
  double get minExtent => 96.0;

  @override
  double get maxExtent => 260.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // 0.0 when fully expanded, 1.0 when fully collapsed
    final collapseRatio = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final isFullyCollapsed = collapseRatio > 0.85;

    return Container(
      color: isFullyCollapsed ? const Color(0xFFF2F2F7) : const Color(0xFF4A90E2),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Doodle Pattern
          if (!isFullyCollapsed)
            Opacity(
              opacity: (1.0 - collapseRatio).clamp(0.0, 0.45),
              child: Image.asset(
                AppAssets.patternSeaLife,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),

          // Action Buttons (QR code on Left, Edit on Right)
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top-left QR button
                GestureDetector(
                  onTap: onQrTap,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isFullyCollapsed
                          ? const Color(0xFFE5E5EA)
                          : Colors.black.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.qr_code_2_rounded,
                      size: 20,
                      color: isFullyCollapsed ? AppColors.textPrimary : Colors.white,
                    ),
                  ),
                ),

                // Scrolled-Up Collapsed Title
                if (isFullyCollapsed)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        username.isNotEmpty ? username : 'Player',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '★',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),

                // Top-right Edit button
                GestureDetector(
                  onTap: onEditTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isFullyCollapsed
                          ? const Color(0xFFE5E5EA)
                          : Colors.black.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      'Edit',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isFullyCollapsed ? AppColors.textPrimary : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Centered Dinosaur Avatar + Name & Subtitle (Normal state)
          if (!isFullyCollapsed)
            Positioned(
              bottom: 14,
              left: 0,
              right: 0,
              child: Opacity(
                opacity: (1.0 - (collapseRatio * 1.5)).clamp(0.0, 1.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Live User Avatar
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.15),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: SafeAvatarImage(
                        imageSource: avatar.isNotEmpty ? avatar : AppAssets.avatarTravelDuckParis,
                        size: 86,
                        shape: BoxShape.circle,
                        fallback: Image.asset(
                          AppAssets.avatarTravelDuckParis,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // User Name ★
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          username.isNotEmpty ? username : 'Player',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '★',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 3),

                    // Subtitle
                    Text(
                      '@${username.replaceAll("@", "")} • Terna Player',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SettingsHeaderDelegate oldDelegate) => false;
}
