import 'package:flutter/material.dart';
import 'package:terna/models/bump_game/bump_models.dart';

/// History tab displaying past Arena Bump rounds with video replay button
class BumpHistoryTab extends StatelessWidget {
  final List<BumpRoundHistory> historyRecords;
  final Function(BumpRoundHistory record) onWatchReplay;
  final VoidCallback onBackToGame;

  const BumpHistoryTab({
    super.key,
    required this.historyRecords,
    required this.onWatchReplay,
    required this.onBackToGame,
  });

  @override
  Widget build(BuildContext context) {
    if (historyRecords.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'No completed rounds yet.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: historyRecords.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, idx) {
            final record = historyRecords[idx];
            final winner = record.winner;

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF10131F),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  // Winner Avatar with Star
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: winner.color.withValues(alpha: 0.2),
                        backgroundImage:
                            winner.avatar.isNotEmpty ? AssetImage(winner.avatar) : null,
                        child: winner.avatar.isEmpty
                            ? Text(
                                winner.displayName.replaceAll('@', '').isNotEmpty
                                    ? winner.displayName.replaceAll('@', '')[0].toUpperCase()
                                    : 'W',
                                style: TextStyle(
                                  color: winner.color,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const Positioned(
                        top: -4,
                        right: -4,
                        child: Icon(Icons.emoji_events, color: Color(0xFFFBBF24), size: 14),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),

                  // Winner Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              winner.displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2DD4BF).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'CHAMPION',
                                style: TextStyle(
                                  color: Color(0xFF2DD4BF),
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Round #${record.roundId} • Pot: ${record.totalPotTon > 0 ? "${record.totalPotTon.toStringAsFixed(2)} TON" : "${record.totalPotStars} ⭐"} • ${record.participants.length} players',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Watch Replay Action
                  ElevatedButton.icon(
                    onPressed: () => onWatchReplay(record),
                    icon: const Icon(Icons.play_arrow, size: 14, color: Colors.black),
                    label: const Text(
                      'Replay',
                      style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2DD4BF),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
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

