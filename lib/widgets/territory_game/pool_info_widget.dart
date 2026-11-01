import 'package:flutter/material.dart';
import 'package:terna/models/territory_game/territory_models.dart';

/// Top header widget displaying game mode tabs, pool number, pot total, and countdown status
class PoolInfoWidget extends StatelessWidget {
  final CurrentRoundState roundState;
  final String activeTab;
  final ValueChanged<String> onTabChanged;

  const PoolInfoWidget({
    super.key,
    required this.roundState,
    required this.activeTab,
    required this.onTabChanged,
  });

  String _getStatusText() {
    switch (roundState.status) {
      case RoundStatus.waitingForPlayers:
        return 'Waiting for bets...';
      case RoundStatus.bettingOpen:
        final s = (roundState.timeRemainingMs / 1000).ceil();
        return 'Bets close in ${s}s';
      case RoundStatus.roundResolving:
        return '⚡ Selecting winner...';
      case RoundStatus.winnerCelebration:
        return '🏆 Round Complete!';
    }
  }

  @override
  Widget build(BuildContext context) {
    final secondsLeft = (roundState.timeRemainingMs / 1000).clamp(0, 15);
    final progress = (secondsLeft / 15.0).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Top Segmented Toggle: Current Game vs History
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF141724),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onTabChanged('current'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: activeTab == 'current'
                          ? const Color(0xFF2DD4BF).withValues(alpha: 0.18)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: activeTab == 'current'
                          ? Border.all(color: const Color(0xFF2DD4BF).withValues(alpha: 0.4))
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        'Current Game',
                        style: TextStyle(
                          color: activeTab == 'current'
                              ? const Color(0xFF2DD4BF)
                              : Colors.white.withValues(alpha: 0.6),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => onTabChanged('history'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: activeTab == 'history'
                          ? const Color(0xFF2DD4BF).withValues(alpha: 0.18)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: activeTab == 'history'
                          ? Border.all(color: const Color(0xFF2DD4BF).withValues(alpha: 0.4))
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        'History',
                        style: TextStyle(
                          color: activeTab == 'history'
                              ? const Color(0xFF2DD4BF)
                              : Colors.white.withValues(alpha: 0.6),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 2. Pool Info Card
        if (activeTab == 'current') ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF10131F),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left: Pool # & Pot Total
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Pool #${roundState.roundId}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.4)),
                          ),
                          child: const Text(
                            'STANDARD',
                            style: TextStyle(
                              color: Color(0xFFA5B4FC),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text(
                          'Pot: ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${roundState.totalPotTon.toStringAsFixed(2)} TON',
                          style: const TextStyle(
                            color: Color(0xFF2DD4BF),
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (roundState.totalPotStars > 0) ...[
                          const SizedBox(width: 6),
                          Text(
                            '+${roundState.totalPotStars} ⭐',
                            style: const TextStyle(
                              color: Color(0xFFFBBF24),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),

                // Right: Countdown Timer Status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: roundState.status == RoundStatus.bettingOpen
                        ? const Color(0xFFF97316).withValues(alpha: 0.15)
                        : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: roundState.status == RoundStatus.bettingOpen
                          ? const Color(0xFFF97316).withValues(alpha: 0.4)
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (roundState.status == RoundStatus.bettingOpen) ...[
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 2.2,
                            backgroundColor: Colors.white.withValues(alpha: 0.1),
                            valueColor: const AlwaysStoppedAnimation(Color(0xFFF97316)),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        _getStatusText(),
                        style: TextStyle(
                          color: roundState.status == RoundStatus.bettingOpen
                              ? const Color(0xFFFDBA74)
                              : Colors.white.withValues(alpha: 0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

