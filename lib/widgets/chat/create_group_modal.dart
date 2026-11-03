library;

import 'package:flutter/material.dart';
import '../../services/chat/chat_service.dart';
import '../../services/haptic.dart';

class CreateGroupModal extends StatefulWidget {
  final VoidCallback? onGroupCreated;

  const CreateGroupModal({super.key, this.onGroupCreated});

  static Future<void> show(BuildContext context, {VoidCallback? onGroupCreated}) {
    return showDialog(
      context: context,
      builder: (ctx) => CreateGroupModal(onGroupCreated: onGroupCreated),
    );
  }

  @override
  State<CreateGroupModal> createState() => _CreateGroupModalState();
}

class _CreateGroupModalState extends State<CreateGroupModal> {
  final _chatService = ChatService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  String _selectedIcon = '💬';
  bool _isPrivate = false;

  final List<String> _iconChoices = const [
    '💬', '🔥', '🏆', '💎', '⚔️', '🐋', '🎮', '⚡', '🚀', '🛡️', '👑', '🎯'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _handleCreate() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name!'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    _chatService.createGroup(
      name: name,
      description: _descController.text.trim(),
      icon: _selectedIcon,
      isPrivate: _isPrivate,
    );

    HapticFeedbackService.heavyImpact();
    Navigator.pop(context);
    widget.onGroupCreated?.call();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✓ Group "$name" created successfully!'), backgroundColor: const Color(0xFF10B981)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF131722),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF2DD4BF), width: 1.5),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2DD4BF).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(_selectedIcon, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          const Text('New Chat Group', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Group Icon', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _iconChoices.map((icon) {
                final isSel = _selectedIcon == icon;
                return InkWell(
                  onTap: () => setState(() => _selectedIcon = icon),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFF2DD4BF).withValues(alpha: 0.25) : const Color(0xFF0C101A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isSel ? const Color(0xFF2DD4BF) : Colors.white12),
                    ),
                    child: Center(child: Text(icon, style: const TextStyle(fontSize: 18))),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),
            const Text('Group Name', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'e.g. Terna Whale Syndicate',
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: const Color(0xFF0C101A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),

            const SizedBox(height: 14),
            const Text('Description (Optional)', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _descController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'What is this channel about?',
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: const Color(0xFF0C101A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),

            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Private Group', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('Invite only access', style: TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
                Switch(
                  value: _isPrivate,
                  activeTrackColor: const Color(0xFF2DD4BF),
                  onChanged: (val) => setState(() => _isPrivate = val),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: _handleCreate,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2DD4BF),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Create Group', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
