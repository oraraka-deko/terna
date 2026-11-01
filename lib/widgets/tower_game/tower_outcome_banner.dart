import 'package:flutter/material.dart';
import '../../models/tower_game/tower_game_models.dart';

/// Alert banner showing win / loss outcome.
class TowerOutcomeBanner extends StatelessWidget {
  final TowerOutcome outcome;

  const TowerOutcomeBanner({
    super.key,
    required this.outcome,
  });

  @override
  Widget build(BuildContext context) {
    final currencySymbol = outcome.currency == TowerCurrency.ton ? 'TON' : '⭐';
    final amountFormatted = outcome.currency == TowerCurrency.ton
        ? outcome.amount.toStringAsFixed(2)
        : outcome.amount.toInt().toString();

    if (!outcome.won) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF43F5E).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFF43F5E).withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Color(0xFFFB7185), size: 18),
                SizedBox(width: 8),
                Text(
                  'Trap Triggered! Run busted.',
                  style: TextStyle(
                    color: Color(0xFFFDA4AF),
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Text(
              '-$amountFormatted $currencySymbol',
              style: const TextStyle(
                color: Color(0xFFFB7185),
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(outcome.isGrandWin ? '🏆' : '🎉', style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                outcome.isGrandWin ? 'Tower Conquered!' : 'Payout Cashed Out!',
                style: const TextStyle(
                  color: Color(0xFFA7F3D0),
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Text(
            '+$amountFormatted $currencySymbol',
            style: const TextStyle(
              color: Color(0xFF6EE7B7),
              fontFamily: 'monospace',
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

