import 'package:flutter/material.dart';
import 'package:terna/models/bump_game/bump_models.dart';

/// Top header widget displaying game mode tabs, round ID, pot total, and countdown/battle status
class BumpPoolInfoWidget extends StatelessWidget {
  final int roundId;
  final BumpRoundStatus status;
  final double totalPotTon;
  final int totalPotStars;
  final int countdownMs;
  final String activeTab;
  final ValueChanged<String> onTabChanged;

  const BumpPoolInfoWidget({
    super.key,
    required this.roundId,
    required this.status,
    required this.totalPotTon,
    required this.totalPotStars,
    required this.countdownMs,
    required this.activeTab,
    required this.onTabChanged,
  });

  String _getStatusText() {
    switch (status) {
      case BumpRoundStatus.waitingForPlayers:
        return 'Waiting for players...';
      case BumpRoundStatus.countdown:
        final s = (countdownMs / 1000).ceil();
        return 'Battle in ${s}s';
      case BumpRoundStatus.battle:
        return '⚔️ BATTLE IN PROGRESS';
      case BumpRoundStatus.roundOver:
        return '🏆 ROUND COMPLETE';
    }
  }

  @override
  Widget build(BuildContext context) {
    final secondsLeft = (countdownMs / 1000).clamp(0, 20);
    final progress = (secondsLeft / 20.0).clamp(0.0, 1.0);

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
                // Left: Round # & Pot Total
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Round #$roundId',
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
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.4)),
                          ),
                          child: const Text(
                            'ARENA BUMP',
                            style: TextStyle(
                              color: Color(0xFFC084FC),
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
                          '${totalPotTon.toStringAsFixed(2)} TON',
                          style: const TextStyle(
                            color: Color(0xFF2DD4BF),
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (totalPotStars > 0) ...[
                          const SizedBox(width: 6),
                          Text(
                            '+$totalPotStars ⭐',
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

                // Right: Status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: status == BumpRoundStatus.countdown
                        ? const Color(0xFFF97316).withValues(alpha: 0.15)
                        : (status == BumpRoundStatus.battle
                            ? const Color(0xFFEF4444).withValues(alpha: 0.2)
                            : const Color(0xFF1E293B)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: status == BumpRoundStatus.countdown
                          ? const Color(0xFFF97316).withValues(alpha: 0.4)
                          : (status == BumpRoundStatus.battle
                              ? const Color(0xFFEF4444).withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.1)),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (status == BumpRoundStatus.countdown) ...[
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
                          color: status == BumpRoundStatus.countdown
                              ? const Color(0xFFFDBA74)
                              : (status == BumpRoundStatus.battle
                                  ? const Color(0xFFFCA5A5)
                                  : Colors.white.withValues(alpha: 0.8)),
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

