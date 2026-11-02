import 'package:flutter/material.dart';
import '../../models/higher_lower/higher_lower_models.dart';
import 'card_item_widget.dart';

/// Modal dialog showing round history and drawn card sequence.
class HigherLowerHistoryDialog extends StatelessWidget {
  final List<HigherLowerRoundHistory> history;
  final List<PlayingCard> currentRoundDrawn;

  const HigherLowerHistoryDialog({
    super.key,
    required this.history,
    required this.currentRoundDrawn,
  });

  static Future<void> show(
    BuildContext context, {
    required List<HigherLowerRoundHistory> history,
    required List<PlayingCard> currentRoundDrawn,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141722),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => HigherLowerHistoryDialog(
        history: history,
        currentRoundDrawn: currentRoundDrawn,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Round History',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white60),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Current Round Drawn Cards
          if (currentRoundDrawn.isNotEmpty) ...[
            const Text(
              'Current Round Drawn Cards',
              style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 70,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: currentRoundDrawn.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final card = currentRoundDrawn[index];
                  return SizedBox(
                    width: 48,
                    height: 70,
                    child: CardItemWidget(card: card, width: 48, height: 70),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white10),
            const SizedBox(height: 8),
          ],

          const Text(
            'Past Rounds',
            style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: history.isEmpty
                ? const Center(
                    child: Text(
                      'No past rounds yet. Start playing!',
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                  )
                : ListView.separated(
                    itemCount: history.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = history[index];
                      final isWon = item.isCashOut;
                      final symbol = item.currency == HigherLowerCurrency.stars ? '⭐' : 'TON';

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B1E2B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isWon
                                    ? const Color(0xFF22C55E).withValues(alpha: 0.15)
                                    : const Color(0xFFEF4444).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  isWon ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                  color: isWon ? const Color(0xFF4ADE80) : const Color(0xFFF87171),
                                  size: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isWon ? 'Won ×${item.finalMultiplier.toStringAsFixed(2)}' : 'Busted',
                                    style: TextStyle(
                                      color: isWon ? const Color(0xFF4ADE80) : Colors.white70,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    '${item.totalWins} wins · Bet: ${item.betAmount} $symbol',
                                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              isWon ? '+${item.payoutAmount} $symbol' : '-${item.betAmount} $symbol',
                              style: TextStyle(
                                color: isWon ? const Color(0xFF4ADE80) : const Color(0xFFF87171),
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

