import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:terna/models/territory_game/territory_models.dart';
import 'package:terna/services/territory_game/territory_audio_service.dart';

/// Player roster listing active bets and provably fair hash bar
class PlayerRosterWidget extends StatefulWidget {
  final List<PlayerBet> bets;
  final String serverSeedHash;
  final VoidCallback onOpenProvablyFair;

  const PlayerRosterWidget({
    super.key,
    required this.bets,
    required this.serverSeedHash,
    required this.onOpenProvablyFair,
  });

  @override
  State<PlayerRosterWidget> createState() => _PlayerRosterWidgetState();
}

class _PlayerRosterWidgetState extends State<PlayerRosterWidget> {
  bool _copiedHash = false;
  bool _isRosterExpanded = true;

  void _handleCopyHash() {
    TerritoryAudioService.playClick();
    Clipboard.setData(ClipboardData(text: widget.serverSeedHash));
    setState(() => _copiedHash = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copiedHash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sortedBets = List<PlayerBet>.from(widget.bets)
      ..sort((a, b) => b.totalBet.compareTo(a.totalBet));
    final totalWeight = sortedBets.fold<double>(0.0, (acc, b) => acc + b.totalBet);

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
                tooltip: 'Copy Pre-round Seed Hash',
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // 2. Active Players Header
        GestureDetector(
          onTap: () => setState(() => _isRosterExpanded = !_isRosterExpanded),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Players (${sortedBets.length})',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(
                _isRosterExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: Colors.white.withValues(alpha: 0.5),
                size: 20,
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // 3. Player List
        if (_isRosterExpanded)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedBets.length,
            separatorBuilder: (_, _) => const SizedBox(height: 4),
            itemBuilder: (context, idx) {
              final bet = sortedBets[idx];
              final percentage = totalWeight > 0
                  ? ((bet.totalBet / totalWeight) * 100).toStringAsFixed(1)
                  : '0.0';

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF111422),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: bet.playerId == 'current_user'
                        ? const Color(0xFF2DD4BF).withValues(alpha: 0.4)
                        : Colors.white.withValues(alpha: 0.04),
                  ),
                ),
                child: Row(
                  children: [
                    // Color tag dot
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: bet.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Avatar or Initials
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: bet.color.withValues(alpha: 0.2),
                      backgroundImage: bet.avatar.isNotEmpty ? AssetImage(bet.avatar) : null,
                      child: bet.avatar.isEmpty
                          ? Text(
                              bet.username.replaceAll('@', '').isNotEmpty
                                  ? bet.username.replaceAll('@', '')[0].toUpperCase()
                                  : 'P',
                              style: TextStyle(
                                color: bet.color,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),

                    // Username
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              bet.username,
                              style: TextStyle(
                                color: bet.playerId == 'current_user'
                                    ? const Color(0xFF2DD4BF)
                                    : Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (bet.playerId == 'current_user') ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2DD4BF).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'YOU',
                                style: TextStyle(
                                  color: Color(0xFF2DD4BF),
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Bet Amount & Percentage
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          bet.currency == 'ton'
                              ? '${bet.amount.toStringAsFixed(2)} TON'
                              : '${bet.amount.toInt()} ⭐',
                          style: TextStyle(
                            color: bet.currency == 'ton'
                                ? const Color(0xFF2DD4BF)
                                : const Color(0xFFFBBF24),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$percentage%',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
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
