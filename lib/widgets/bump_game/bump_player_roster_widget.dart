import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:terna/models/bump_game/bump_models.dart';
import 'package:terna/services/bump_game/bump_audio_service.dart';

/// Player roster listing participants, odds, ball sizes and live/eliminated status
class BumpPlayerRosterWidget extends StatefulWidget {
  final List<BumpPlayerBall> balls;
  final String serverSeedHash;
  final VoidCallback onOpenProvablyFair;

  const BumpPlayerRosterWidget({
    super.key,
    required this.balls,
    required this.serverSeedHash,
    required this.onOpenProvablyFair,
  });

  @override
  State<BumpPlayerRosterWidget> createState() => _BumpPlayerRosterWidgetState();
}

class _BumpPlayerRosterWidgetState extends State<BumpPlayerRosterWidget> {
  bool _copiedHash = false;
  bool _isExpanded = true;

  void _handleCopyHash() {
    BumpAudioService.playClick();
    Clipboard.setData(ClipboardData(text: widget.serverSeedHash));
    setState(() => _copiedHash = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copiedHash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sortedBalls = List<BumpPlayerBall>.from(widget.balls)
      ..sort((a, b) => b.betAmount.compareTo(a.betAmount));
    final totalBet = sortedBalls.fold<double>(0.0, (acc, b) => acc + b.betAmount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Provably Fair Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: widget.onOpenProvablyFair,
                child: Row(
                  children: [
                    const Icon(Icons.verified_user, color: Color(0xFF10B981), size: 16),
                    const SizedBox(width: 6),
                    const Text(
                      'PROVABLY FAIR',
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.serverSeedHash.length > 12
                          ? '${widget.serverSeedHash.substring(0, 6)}...${widget.serverSeedHash.substring(widget.serverSeedHash.length - 4)}'
                          : widget.serverSeedHash,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  _copiedHash ? Icons.check : Icons.copy,
                  size: 14,
                  color: _copiedHash ? const Color(0xFF10B981) : Colors.white.withValues(alpha: 0.5),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: _handleCopyHash,
                tooltip: 'Copy Seed Hash',
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // 2. Header with Expand Toggle
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Arena Fighters (${sortedBalls.length})',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(
                _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: Colors.white.withValues(alpha: 0.5),
                size: 20,
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // 3. Fighter List
        if (_isExpanded)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedBalls.length,
            separatorBuilder: (_, _) => const SizedBox(height: 4),
            itemBuilder: (context, idx) {
              final b = sortedBalls[idx];
              final sharePercent = totalBet > 0
                  ? ((b.betAmount / totalBet) * 100).toStringAsFixed(1)
                  : '0.0';

              final isAlive = b.state == BallState.alive;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF111422),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: b.isUser
                        ? const Color(0xFFC084FC).withValues(alpha: 0.4)
                        : Colors.white.withValues(alpha: 0.04),
                  ),
                ),
                child: Row(
                  children: [
                    // Color Tag Dot
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: b.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Avatar or Initials
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: b.color.withValues(alpha: 0.2),
                      backgroundImage: b.avatar.isNotEmpty ? AssetImage(b.avatar) : null,
                      child: b.avatar.isEmpty
                          ? Text(
                              b.displayName.replaceAll('@', '').isNotEmpty
                                  ? b.displayName.replaceAll('@', '')[0].toUpperCase()
                                  : 'F',
                              style: TextStyle(
                                color: b.color,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),

                    // Name & Badges
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              b.displayName,
                              style: TextStyle(
                                color: b.isUser
                                    ? const Color(0xFFC084FC)
                                    : (isAlive ? Colors.white : Colors.white.withValues(alpha: 0.4)),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                decoration: isAlive ? null : TextDecoration.lineThrough,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (b.isUser) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFC084FC).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'YOU',
                                style: TextStyle(
                                  color: Color(0xFFC084FC),
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                          if (b.isSystemBot) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF97316).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'CORE',
                                style: TextStyle(
                                  color: Color(0xFFF97316),
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Status Badge (ALIVE / OUT)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: isAlive
                            ? const Color(0xFF10B981).withValues(alpha: 0.15)
                            : const Color(0xFFEF4444).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isAlive ? 'ALIVE' : 'OUT',
                        style: TextStyle(
                          color: isAlive ? const Color(0xFF34D399) : const Color(0xFFF87171),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Bet Amount & Percentage
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          b.currency == 'ton'
                              ? '${b.betAmount.toStringAsFixed(2)} TON'
                              : '${b.betAmount.toInt()} ⭐',
                          style: TextStyle(
                            color: b.currency == 'ton'
                                ? const Color(0xFF2DD4BF)
                                : const Color(0xFFFBBF24),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$sharePercent% • r:${b.radius.toInt()}px',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

