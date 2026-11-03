library;

import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';
import '../../models/chat/chat_models.dart';
import '../../services/chat/chat_service.dart';
import '../../services/haptic.dart';

class GamerBioModal extends StatefulWidget {
  final String userId;
  final String defaultUsername;

  const GamerBioModal({
    super.key,
    required this.userId,
    this.defaultUsername = 'Player',
  });

  static Future<void> show({
    required BuildContext context,
    required String userId,
    String defaultUsername = 'Player',
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GamerBioModal(
        userId: userId,
        defaultUsername: defaultUsername,
      ),
    );
  }

  @override
  State<GamerBioModal> createState() => _GamerBioModalState();
}

class _GamerBioModalState extends State<GamerBioModal> {
  final _chatService = ChatService();
  late GamerBioData _bio;
  bool _isEditing = false;

  late TextEditingController _aboutController;
  late String _selectedPlayStyle;
  late String _selectedReaction;

  final List<String> _playStylePresets = const [
    'Tactical Striker 🎯',
    'High Roller Whale 🐋',
    'Relic Hunter 💎',
    'Aggressive Rusher ⚡',
    'Lucky Gambler 🎲',
    'Zen Defender 🛡️',
  ];

  final List<String> _reactionPresets = const [
    'Always ready for a rematch! 🔥',
    'GG WP! No hard feelings 🤝',
    'Never back down, never surrender ⚔️',
    'Winner takes all! 🏆',
    'Calculating next round odds... 🧠',
    'Pure luck or pure skill? You decide 😎',
  ];

  @override
  void initState() {
    super.initState();
    _bio = _chatService.getGamerBio(widget.userId, defaultName: widget.defaultUsername);
    _aboutController = TextEditingController(text: _bio.aboutMe);
    _selectedPlayStyle = _bio.playStyle;
    _selectedReaction = _bio.postMatchReaction;
  }

  @override
  void dispose() {
    _aboutController.dispose();
    super.dispose();
  }

  bool get _isSelf => widget.userId == _chatService.currentUserId;

  void _saveBio() {
    _chatService.updateBio(
      playStyle: _selectedPlayStyle,
      favoriteCharacter: _bio.favoriteCharacter,
      postMatchReaction: _selectedReaction,
      aboutMe: _aboutController.text.trim(),
    );
    setState(() {
      _bio = _chatService.getGamerBio(widget.userId);
      _isEditing = false;
    });
    HapticFeedbackService.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✓ Gamer Bio updated!'), backgroundColor: Color(0xFF10B981)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return Container(
      constraints: BoxConstraints(maxHeight: media.size.height * 0.88),
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF0F141F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Color(0xFF2DD4BF), width: 1.5)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    _bio.avatar ?? AppAssets.avatarCat,
                    width: 54,
                    height: 54,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 54,
                      height: 54,
                      color: const Color(0xFF1E2433),
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _bio.username,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.verified_rounded, color: Color(0xFF0098EA), size: 16),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _bio.playStyle,
                        style: const TextStyle(color: Color(0xFF2DD4BF), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                if (_isSelf)
                  IconButton(
                    icon: Icon(_isEditing ? Icons.check_circle_rounded : Icons.edit_note_rounded, color: const Color(0xFF2DD4BF)),
                    onPressed: () {
                      if (_isEditing) {
                        _saveBio();
                      } else {
                        setState(() => _isEditing = true);
                      }
                    },
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Performance Statistics Grid
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF131826),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.emoji_events_rounded, color: Color(0xFFFFB800), size: 18),
                          SizedBox(width: 8),
                          Text('BATTLE PERFORMANCE', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2DD4BF).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${_bio.winRate}% Win Rate',
                          style: const TextStyle(color: Color(0xFF2DD4BF), fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatBox('Battles', '${_bio.roundsPlayed}', Colors.white),
                      _buildStatBox('Victories', '${_bio.roundsWon}', const Color(0xFF10B981)),
                      _buildStatBox('Wagered', '\$${_bio.totalWagered.toInt()}', const Color(0xFFFFB800)),
                      _buildStatBox('Best Win', '\$${_bio.biggestWin.toInt()}', const Color(0xFF0098EA)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Bio Details & Settings
            if (_isEditing) ...[
              const Text('Play Style Preset', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _playStylePresets.map((style) {
                  final isSel = _selectedPlayStyle == style;
                  return ChoiceChip(
                    label: Text(style, style: TextStyle(color: isSel ? Colors.black : Colors.white70, fontSize: 11)),
                    selected: isSel,
                    selectedColor: const Color(0xFF2DD4BF),
                    backgroundColor: const Color(0xFF131826),
                    onSelected: (_) => setState(() => _selectedPlayStyle = style),
                  );
                }).toList(),
              ),

              const SizedBox(height: 14),

              const Text('Post-Match Rematch Reaction', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _reactionPresets.map((rx) {
                  final isSel = _selectedReaction == rx;
                  return ChoiceChip(
                    label: Text(rx, style: TextStyle(color: isSel ? Colors.black : Colors.white70, fontSize: 11)),
                    selected: isSel,
                    selectedColor: const Color(0xFF2DD4BF),
                    backgroundColor: const Color(0xFF131826),
                    onSelected: (_) => setState(() => _selectedReaction = rx),
                  );
                }).toList(),
              ),

              const SizedBox(height: 14),

              const Text('About Me', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: _aboutController,
                maxLines: 2,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF131826),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),

              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: _saveBio,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2DD4BF),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ] else ...[
              _buildInfoRow('Post-Match Reaction', _bio.postMatchReaction, Icons.local_fire_department_rounded, Colors.orangeAccent),
              const SizedBox(height: 8),
              _buildInfoRow('Favorite Character', _bio.favoriteCharacter, Icons.sports_esports_rounded, const Color(0xFFC084FC)),
              const SizedBox(height: 8),
              _buildInfoRow('About Player', _bio.aboutMe, Icons.info_outline_rounded, Colors.white60),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String title, String val, Color valColor) {
    return Column(
      children: [
        Text(val, style: TextStyle(color: valColor, fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 2),
        Text(title, style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF131826),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

