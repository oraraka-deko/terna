library;

import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/name_with_badges_row.dart';
import '../../core/widgets/story_avatar_widget.dart';
import '../../models/chat/chat_models.dart';
import '../../services/chat/chat_service.dart';
import '../../services/haptic.dart';
import '../../widgets/chat/chat_transfer_modal.dart';
import '../../widgets/chat/gamer_bio_modal.dart';

class ContactsScreen extends StatefulWidget {
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
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _chatService = ChatService();
  String _searchQuery = '';
  int _activeTab = 0; // 0: All Friends, 1: Requests

  void _openAddFriendDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Friend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your friend\'s Telegram @username or Arena Player ID to send a request.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '@username or ID',
                prefixIcon: const Icon(Icons.person_add_rounded, color: AppColors.primaryBlue),
                filled: true,
                fillColor: const Color(0xFFF2F2F7),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final val = textController.text.trim();
              if (val.isEmpty) return;
              Navigator.pop(ctx);
              HapticFeedbackService.lightImpact();
              final ok = await _chatService.sendFriendRequest(val);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok ? '✓ Friend request sent to $val!' : 'Already in contacts or invalid ID!'),
                    backgroundColor: ok ? const Color(0xFF10B981) : Colors.orangeAccent,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Send Request', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showContactMenu(FriendItem item) {
    HapticFeedbackService.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                StoryAvatarWidget(
                  assetPath: item.friendAvatar ?? AppAssets.avatarCat,
                  size: 46,
                  isOnline: item.isOnline,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.friendUsername, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(item.playStyle ?? 'Player', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primaryBlue),
              title: const Text('Open Direct Chat'),
              onTap: () {
                Navigator.pop(ctx);
                widget.onContactTap?.call(item.friendId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.military_tech_outlined, color: Colors.purple),
              title: const Text('View Gamer Bio & Stats'),
              onTap: () {
                Navigator.pop(ctx);
                GamerBioModal.show(
                  context: context,
                  userId: item.friendId,
                  defaultUsername: item.friendUsername,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.send_rounded, color: Color(0xFF10B981)),
              title: const Text('Send In-Chat Transfer (TON / Stars / Gift)'),
              onTap: () {
                Navigator.pop(ctx);
                ChatTransferModal.show(
                  context: context,
                  recipientId: item.friendId,
                  recipientName: item.friendUsername,
                  onTransferSuccess: (transfer) {
                    _chatService.sendDirectMessage(
                      recipientId: item.friendId,
                      text: transfer.type == 'GIFT'
                          ? '🎁 Sent you ${transfer.giftName}!'
                          : '💸 Sent you ${transfer.amount} ${transfer.type}!',
                      transfer: transfer,
                    );
                    widget.onContactTap?.call(item.friendId);
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_remove_outlined, color: Colors.redAccent),
              title: const Text('Remove Contact', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(ctx);
                _chatService.removeFriend(item.id);
                HapticFeedbackService.heavyImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Removed ${item.friendUsername} from contacts.')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ValueListenableBuilder<List<FriendItem>>(
        valueListenable: _chatService.friends,
        builder: (ctx, allFriends, _) {
          final acceptedFriends = allFriends.where((f) => f.status == FriendStatus.accepted).toList();
          final pendingRequests = allFriends.where((f) => f.status == FriendStatus.pending).toList();

          final filteredAccepted = acceptedFriends.where((f) {
            return _searchQuery.isEmpty || f.friendUsername.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();

          return CustomScrollView(
            slivers: [
              // Top Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 56, left: 16, right: 16, bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Sort pill button
                      GestureDetector(
                        onTap: widget.onSortTap,
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
                        onTap: _openAddFriendDialog,
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

              // Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3E3E8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      style: const TextStyle(fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Search contacts...',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                        prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 9),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    ),
                  ),
                ),
              ),

              // Segmented Tabs: All Friends vs Pending Requests
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: Center(child: Text('Friends (${acceptedFriends.length})')),
                          selected: _activeTab == 0,
                          selectedColor: AppColors.primaryBlue.withValues(alpha: 0.15),
                          backgroundColor: const Color(0xFFF2F2F7),
                          labelStyle: TextStyle(
                            color: _activeTab == 0 ? AppColors.primaryBlue : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          onSelected: (_) => setState(() => _activeTab = 0),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Requests'),
                                if (pendingRequests.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${pendingRequests.length}',
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          selected: _activeTab == 1,
                          selectedColor: AppColors.primaryBlue.withValues(alpha: 0.15),
                          backgroundColor: const Color(0xFFF2F2F7),
                          labelStyle: TextStyle(
                            color: _activeTab == 1 ? AppColors.primaryBlue : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          onSelected: (_) => setState(() => _activeTab = 1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Invite Friends Action Row (Only in All Friends tab)
              if (_activeTab == 0)
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      InkWell(
                        onTap: _openAddFriendDialog,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(shape: BoxShape.circle),
                                child: const Icon(Icons.person_add_alt_outlined, color: AppColors.primaryBlue, size: 26),
                              ),
                              const SizedBox(width: 14),
                              const Text(
                                'Add or Invite Friends',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
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

              // TAB 0: All Friends List
              if (_activeTab == 0)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = filteredAccepted[index];
                      return Column(
                        children: [
                          InkWell(
                            onTap: () {
                              if (widget.onContactTap != null) {
                                widget.onContactTap!(item.friendId);
                              } else {
                                _showContactMenu(item);
                              }
                            },
                            onLongPress: () => _showContactMenu(item),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                children: [
                                  StoryAvatarWidget(
                                    assetPath: item.friendAvatar ?? AppAssets.avatarCat,
                                    size: 46,
                                    hasStory: item.isOnline,
                                    isOnline: item.isOnline,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        NameWithBadgesRow(
                                          title: item.friendUsername,
                                          hasStar: item.friendId == 'pepe',
                                          titleStyle: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          item.isOnline ? 'online • ${item.playStyle ?? 'Player'}' : 'last seen recently',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w400,
                                            color: item.isOnline ? AppColors.primaryBlue : AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.more_vert_rounded, color: Colors.grey, size: 20),
                                    onPressed: () => _showContactMenu(item),
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
                    childCount: filteredAccepted.length,
                  ),
                ),

              // TAB 1: Pending Friend Requests
              if (_activeTab == 1)
                if (pendingRequests.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: Text('No pending friend requests', style: TextStyle(color: Colors.grey, fontSize: 14)),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final req = pendingRequests[index];
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(
                            children: [
                              StoryAvatarWidget(
                                assetPath: req.friendAvatar ?? AppAssets.avatarTravelDuckParis,
                                size: 44,
                                isOnline: req.isOnline,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(req.friendUsername, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    Text(req.playStyle ?? 'Player', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  _chatService.acceptFriendRequest(req.id);
                                  HapticFeedbackService.heavyImpact();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Accepted ${req.friendUsername}!')),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryBlue,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(60, 32),
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                ),
                                child: const Text('Accept', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 6),
                              OutlinedButton(
                                onPressed: () {
                                  _chatService.declineFriendRequest(req.id);
                                  HapticFeedbackService.lightImpact();
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.grey,
                                  minimumSize: const Size(60, 32),
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                ),
                                child: const Text('Decline', style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                        );
                      },
                      childCount: pendingRequests.length,
                    ),
                  ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          );
        },
      ),
    );
  }
}
