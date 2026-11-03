library;

import 'dart:ui';
import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../models/chat/chat_models.dart';
import '../../services/chat/chat_service.dart';
import '../../services/haptic.dart';
import '../../widgets/chat/create_group_modal.dart';
import '../../widgets/chat/report_message_modal.dart';

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
  final _chatService = ChatService();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isMuted = false;
  bool _showChatInput = false;

  @override
  void initState() {
    super.initState();
    _chatService.refreshChatData();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendGlobalMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    _chatService.sendGlobalMessage(text: text);
    _inputController.clear();
    HapticFeedbackService.lightImpact();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _openCreateGroup() {
    CreateGroupModal.show(context);
  }

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

          // 2. Broadcast Posts & Global Messages Stream
          Positioned.fill(
            child: ValueListenableBuilder<List<ChatMessage>>(
              valueListenable: _chatService.globalMessages,
              builder: (ctx, globalMsgs, _) {
                return ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(top: 116, bottom: 110, left: 14, right: 14),
                  children: [
                    // Official Pinned Broadcast Post
                    _buildPinnedMediaPost(),

                    const SizedBox(height: 14),

                    // Centered Date Header Pill ("Today")
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7A8B74).withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          'GLOBAL LIVE CHAT & ANNOUNCEMENTS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Dynamic Global Live Messages
                    ...globalMsgs.map((msg) => _buildGlobalMessageCard(msg)),
                  ],
                );
              },
            ),
          ),

          // 3. Floating Channel Header
          _buildFloatingChannelHeader(),

          // 4. Channel Bottom Bar or Active Chat Input Bar
          if (_showChatInput) _buildActiveInputBar() else _buildChannelBottomBar(),
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
          // Left back button
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: GestureDetector(
                onTap: widget.onBack ?? () => Navigator.maybePop(context),
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
                      Text('Chats', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Center Pill: Pavel Durov & Online subscribers
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
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            ),
                            const SizedBox(width: 4),
                            Image.asset(
                              AppAssets.giftSampleGold,
                              width: 14,
                              height: 14,
                              errorBuilder: (_, _, _) => const SizedBox.shrink(),
                            ),
                            const SizedBox(width: 3),
                            const Icon(Icons.verified_rounded, size: 14, color: AppColors.primaryBlue),
                          ],
                        ),
                        ValueListenableBuilder<int>(
                          valueListenable: _chatService.onlineCount,
                          builder: (ctx, count, _) => Text(
                            '$count online • 10,288k subscribers',
                            style: const TextStyle(fontSize: 10.5, color: AppColors.primaryBlue, fontWeight: FontWeight.w500),
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

          // Right Button: Create Group / Topic 👥+
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: GestureDetector(
                onTap: _openCreateGroup,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
                  ),
                  child: const Center(
                    child: Icon(Icons.group_add_rounded, size: 20, color: AppColors.primaryBlue),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Official Pinned Broadcast Media Post
  Widget _buildPinnedMediaPost() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            AppAssets.patternParis,
            width: double.infinity,
            height: 220,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              height: 160,
              color: const Color(0xFF2DD4BF).withValues(alpha: 0.2),
              child: const Center(child: Icon(Icons.photo_library_rounded, size: 40, color: Color(0xFF2DD4BF))),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🚀 Terna MiniApp 2.0 Live Rollout\n\nFull on-chain TON Connect deposits, Telegram Stars integration, and Provably Fair arcade games are now online for all users.',
                  style: TextStyle(fontSize: 14.5, height: 1.4, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Wrap(
                      spacing: 6,
                      children: [
                        _buildReactionPill('🔥', 842),
                        _buildReactionPill('❤️', 619),
                        _buildReactionPill('🚀', 512),
                      ],
                    ),
                    const Text('18:04', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalMessageCard(ChatMessage msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: msg.isOutgoing ? const Color(0xFFE1FFC7) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      msg.senderAvatar ?? AppAssets.avatarCat,
                      width: 24,
                      height: 24,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(Icons.person, size: 24),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    msg.senderName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryBlue),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.more_horiz_rounded, size: 18, color: Colors.grey),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  ReportMessageModal.show(context, messageId: msg.id, senderName: msg.senderName);
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(msg.text, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.35)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Wrap(
                spacing: 6,
                children: [
                  _buildInteractiveReaction(msg.id, '🔥', msg.reactions['🔥'] ?? 0),
                  _buildInteractiveReaction(msg.id, '❤️', msg.reactions['❤️'] ?? 0),
                  _buildInteractiveReaction(msg.id, '👏', msg.reactions['👏'] ?? 0),
                  _buildInteractiveReaction(msg.id, '🚀', msg.reactions['🚀'] ?? 0),
                ],
              ),
              Text(msg.time, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveReaction(String msgId, String emoji, int count) {
    return InkWell(
      onTap: () {
        _chatService.toggleReaction(msgId, emoji, isGlobal: true);
        HapticFeedbackService.lightImpact();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: count > 0 ? const Color(0xFFF2F2F7) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text('$count', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReactionPill(String emoji, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text('$count', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }

  // Active Bottom Text Input Bar
  Widget _buildActiveInputBar() {
    return Positioned(
      bottom: 24,
      left: 14,
      right: 14,
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
                  ),
                  child: TextField(
                    controller: _inputController,
                    autofocus: true,
                    onSubmitted: (_) => _sendGlobalMessage(),
                    decoration: InputDecoration(
                      hintText: 'Join the global live discussion...',
                      hintStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                        onPressed: () => setState(() => _showChatInput = false),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: GestureDetector(
                onTap: _sendGlobalMessage,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.arrow_upward_rounded, size: 24, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
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
          // Left Pill: Comments / Live Chat toggle
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: GestureDetector(
                onTap: () => setState(() => _showChatInput = true),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.mode_comment_outlined, size: 20, color: AppColors.primaryBlue),
                      SizedBox(width: 8),
                      Text('Chat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryBlue)),
                    ],
                  ),
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
                    setState(() => _isMuted = !_isMuted);
                    HapticFeedbackService.selection();
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
                      _isMuted ? 'Unmute Channel' : 'Mute Notifications',
                      style: const TextStyle(
                        fontSize: 15,
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

          // Right Button: Create Group
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: GestureDetector(
                onTap: _openCreateGroup,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
                  ),
                  child: const Center(
                    child: Icon(Icons.add, size: 24, color: AppColors.primaryBlue),
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
