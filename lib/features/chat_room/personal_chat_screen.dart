library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/story_avatar_widget.dart';
import '../../models/chat/chat_models.dart';
import '../../services/chat/chat_service.dart';
import '../../services/haptic.dart';
import '../../widgets/chat/chat_transfer_modal.dart';
import '../../widgets/chat/gamer_bio_modal.dart';
import '../../widgets/chat/report_message_modal.dart';

class PersonalChatScreen extends StatefulWidget {
  final String recipientId;
  final String recipientName;
  final String? recipientAvatar;
  final VoidCallback? onBack;
  final VoidCallback? onHeaderProfileTap;

  const PersonalChatScreen({
    super.key,
    this.recipientId = 'cat',
    this.recipientName = 'Cat',
    this.recipientAvatar,
    this.onBack,
    this.onHeaderProfileTap,
  });

  @override
  State<PersonalChatScreen> createState() => _PersonalChatScreenState();
}

class _PersonalChatScreenState extends State<PersonalChatScreen> {
  final _chatService = ChatService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  ChatMessage? _replyingTo;

  @override
  void initState() {
    super.initState();
    _chatService.fetchDirectMessages(widget.recipientId);
    _textController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
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

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _chatService.sendDirectMessage(
      recipientId: widget.recipientId,
      text: text,
      replyToId: _replyingTo?.id,
      replyText: _replyingTo?.text,
    );

    _textController.clear();
    setState(() => _replyingTo = null);
    HapticFeedbackService.lightImpact();
    _scrollToBottom();
  }

  void _sendDice() {
    _chatService.sendDirectMessage(
      recipientId: widget.recipientId,
      text: '🎲 Rolled a die!',
      isDice: true,
    );
    HapticFeedbackService.mediumImpact();
    _scrollToBottom();
  }

  void _openTransferModal() {
    ChatTransferModal.show(
      context: context,
      recipientId: widget.recipientId,
      recipientName: widget.recipientName,
      onTransferSuccess: (transfer) {
        _chatService.sendDirectMessage(
          recipientId: widget.recipientId,
          text: transfer.type == 'GIFT'
              ? '🎁 Sent you a ${transfer.giftName}!'
              : '💸 Transferred ${transfer.amount} ${transfer.type}!',
          transfer: transfer,
        );
        _scrollToBottom();
      },
    );
  }

  void _openAttachmentMenu() {
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
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF2DD4BF),
                child: Icon(Icons.send_rounded, color: Colors.black, size: 20),
              ),
              title: const Text('Send In-Chat Transfer', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Send TON, Telegram Stars, or Collectible Gifts', style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                _openTransferModal();
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFF9800),
                child: Text('🎲', style: TextStyle(fontSize: 20)),
              ),
              title: const Text('Roll 3D Dice', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Provably fair animated dice roll', style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                _sendDice();
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF9C27B0),
                child: Icon(Icons.military_tech_rounded, color: Colors.white, size: 20),
              ),
              title: const Text('View Gamer Bio', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Inspect battle stats, win rate & playstyle', style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                GamerBioModal.show(
                  context: context,
                  userId: widget.recipientId,
                  defaultUsername: widget.recipientName,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageContextMenu(ChatMessage msg) {
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
            // Emoji reaction row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['❤️', '🔥', '👍', '👏', '🎁', '🚀', '🤑', '🤣'].map((emoji) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _chatService.toggleReaction(msg.id, emoji, recipientId: widget.recipientId);
                        HapticFeedbackService.lightImpact();
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F2F7),
                          shape: BoxShape.circle,
                        ),
                        child: Text(emoji, style: const TextStyle(fontSize: 22)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 24),
            ListTile(
              leading: const Icon(Icons.reply_rounded, color: AppColors.primaryBlue),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _replyingTo = msg);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_rounded, color: Colors.grey),
              title: const Text('Copy Text'),
              onTap: () {
                Navigator.pop(ctx);
                Clipboard.setData(ClipboardData(text: msg.text));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard!')));
              },
            ),
            ListTile(
              leading: const Icon(Icons.report_problem_outlined, color: Colors.redAccent),
              title: const Text('Report Message', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(ctx);
                ReportMessageModal.show(context, messageId: msg.id, senderName: msg.senderName);
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
      body: Stack(
        children: [
          // 1. Background Pattern
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE4F0D5), Color(0xFFCBE2B8)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Opacity(
                opacity: 0.18,
                child: Image.asset(
                  AppAssets.patternCatsInSpace,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),

          // 2. Dynamic Messages Stream
          Positioned.fill(
            child: ValueListenableBuilder<Map<String, List<ChatMessage>>>(
              valueListenable: _chatService.directMessages,
              builder: (ctx, allDms, _) {
                final msgs = allDms[widget.recipientId] ?? [];

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(top: 120, bottom: 120, left: 14, right: 14),
                  itemCount: msgs.length,
                  itemBuilder: (ctx, idx) {
                    final msg = msgs[idx];
                    return _buildMessageItem(msg);
                  },
                );
              },
            ),
          ),

          // 3. Floating Glass Top Header
          _buildFloatingTopBar(),

          // 4. Floating Glass Bottom Input Bar with Reply Banner
          _buildFloatingInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageItem(ChatMessage msg) {
    return GestureDetector(
      onLongPress: () => _showMessageContextMenu(msg),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: msg.isOutgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (msg.transfer != null)
              _buildTransferCard(msg)
            else if (msg.isDice)
              _buildDiceBubble(msg)
            else if (msg.isVideoNote)
              _buildVideoNoteBubble(msg)
            else
              _buildTextBubble(msg),

            // Reactions row
            if (msg.reactions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Wrap(
                  spacing: 4,
                  children: msg.reactions.entries.map((entry) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: Text('${entry.key} ${entry.value}', style: const TextStyle(fontSize: 11)),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextBubble(ChatMessage msg) {
    final isOut = msg.isOutgoing;
    return Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.76),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isOut ? const Color(0xFFE1FFC7) : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isOut ? 16 : 4),
          bottomRight: Radius.circular(isOut ? 4 : 16),
        ),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (msg.replyText != null)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.only(left: 8),
              decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: AppColors.primaryBlue, width: 3)),
              ),
              child: Text(
                msg.replyText!,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          Text(msg.text, style: const TextStyle(fontSize: 15, color: Colors.black87)),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(msg.time, style: const TextStyle(fontSize: 11, color: Colors.black38)),
              if (isOut) ...[
                const SizedBox(width: 4),
                const Icon(Icons.done_all_rounded, size: 14, color: Color(0xFF5E8B4E)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransferCard(ChatMessage msg) {
    final transfer = msg.transfer!;
    final isOut = msg.isOutgoing;
    final isTon = transfer.type == 'TON';
    final isStars = transfer.type == 'STARS';

    return Container(
      width: 260,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isStars
              ? [const Color(0xFF2C2010), const Color(0xFF1B140B)]
              : isTon
                  ? [const Color(0xFF0F2B26), const Color(0xFF0A1C19)]
                  : [const Color(0xFF2E1065), const Color(0xFF160830)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isStars
              ? const Color(0xFFFFB800)
              : isTon
                  ? const Color(0xFF2DD4BF)
                  : const Color(0xFFA855F7),
          width: 1.5,
        ),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isStars
                      ? Icons.star_rounded
                      : isTon
                          ? Icons.diamond_outlined
                          : Icons.card_giftcard_rounded,
                  color: isStars
                      ? const Color(0xFFFFB800)
                      : isTon
                          ? const Color(0xFF2DD4BF)
                          : const Color(0xFFC084FC),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                isOut ? 'TRANSFER SENT' : 'TRANSFER RECEIVED',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (transfer.type == 'GIFT') ...[
            Center(
              child: Image.asset(
                transfer.giftAsset ?? 'assets/telegram/gifts/webp/gift_5170145012310081615.webp',
                width: 64,
                height: 64,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(Icons.card_giftcard, size: 50, color: Colors.amber),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                transfer.giftName ?? 'Telegram Gift',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ] else ...[
            Text(
              '${transfer.amount} ${transfer.type}',
              style: TextStyle(
                color: isStars ? const Color(0xFFFFB800) : const Color(0xFF2DD4BF),
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              isOut ? 'Transferred to ${widget.recipientName}' : 'Received from ${widget.recipientName}',
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 12),
                    SizedBox(width: 4),
                    Text('Confirmed', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Text(msg.time, style: const TextStyle(color: Colors.white38, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiceBubble(ChatMessage msg) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Center(
        child: Text('🎲', style: const TextStyle(fontSize: 60)),
      ),
    );
  }

  Widget _buildVideoNoteBubble(ChatMessage msg) {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(AppAssets.avatarCat, fit: BoxFit.cover),
    );
  }

  Widget _buildFloatingTopBar() {
    return Positioned(
      top: 50,
      left: 14,
      right: 14,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
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
                    children: [
                      Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.primaryBlue),
                      SizedBox(width: 4),
                      Text('Chats', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // User Profile Info
          Expanded(
            child: GestureDetector(
              onTap: () {
                GamerBioModal.show(
                  context: context,
                  userId: widget.recipientId,
                  defaultUsername: widget.recipientName,
                );
              },
              child: Center(
                child: Column(
                  children: [
                    Text(
                      widget.recipientName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const Text('online • tap for bio', style: TextStyle(fontSize: 11, color: AppColors.primaryBlue)),
                  ],
                ),
              ),
            ),
          ),

          // Avatar
          GestureDetector(
            onTap: widget.onHeaderProfileTap ??
                () {
                  GamerBioModal.show(
                    context: context,
                    userId: widget.recipientId,
                    defaultUsername: widget.recipientName,
                  );
                },
            child: StoryAvatarWidget(
              assetPath: widget.recipientAvatar ?? AppAssets.avatarCat,
              size: 40,
              isOnline: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingInputBar() {
    final hasText = _textController.text.trim().isNotEmpty;

    return Positioned(
      bottom: 24,
      left: 14,
      right: 14,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyingTo != null)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Row(
                children: [
                  const Icon(Icons.reply_rounded, color: AppColors.primaryBlue, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Replying to ${_replyingTo!.senderName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primaryBlue)),
                        Text(_replyingTo!.text, style: const TextStyle(fontSize: 12, color: Colors.black54), maxLines: 1),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 16, color: Colors.grey),
                    onPressed: () => setState(() => _replyingTo = null),
                  ),
                ],
              ),
            ),

          Row(
            children: [
              // Left Attachment Button 📎
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: GestureDetector(
                    onTap: _openAttachmentMenu,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
                      ),
                      child: const Icon(Icons.attach_file_rounded, size: 24, color: Color(0xFF8E8E93)),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Text Field
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
                      ),
                      child: TextField(
                        controller: _textController,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: const InputDecoration(
                          hintText: 'Message',
                          hintStyle: TextStyle(color: Color(0xFF8E8E93), fontSize: 15),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Right Button (Send or Mic)
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: GestureDetector(
                    onTap: hasText ? _sendMessage : _sendDice,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: hasText ? AppColors.primaryBlue : Colors.white.withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
                      ),
                      child: Icon(
                        hasText ? Icons.arrow_upward_rounded : Icons.casino_rounded,
                        size: 24,
                        color: hasText ? Colors.white : const Color(0xFF8E8E93),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
