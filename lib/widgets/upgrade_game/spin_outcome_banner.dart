import 'package:flutter/material.dart';
import '../../models/upgrade_game/upgrade_game_models.dart';

/// Banner presenting the result of an upgrade attempt.
class SpinOutcomeBanner extends StatelessWidget {
  final UpgradeSpinResult result;

  const SpinOutcomeBanner({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final won = result.won;

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: won
            ? const Color(0xFF064E3B).withValues(alpha: 0.6)
            : const Color(0xFF450A0A).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: won
              ? const Color(0xFF10B981).withValues(alpha: 0.5)
              : const Color(0xFFEF4444).withValues(alpha: 0.45),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: won
                ? const Color(0xFF10B981).withValues(alpha: 0.2)
                : const Color(0xFFEF4444).withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: won
                  ? const Color(0xFF10B981).withValues(alpha: 0.2)
                  : const Color(0xFFEF4444).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: won
                    ? const Color(0xFF10B981).withValues(alpha: 0.4)
                    : const Color(0xFFEF4444).withValues(alpha: 0.4),
              ),
            ),
            child: Icon(
              won ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: won ? const Color(0xFF34D399) : const Color(0xFFF87171),
              size: 24,
            ),
          ),

          const SizedBox(width: 12),

          // Message
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  won ? 'UPGRADE SUCCESSFUL!' : 'UPGRADE FAILED',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  won
                      ? 'Acquired ${result.grantedGift?.name ?? 'Telegram Gift'}! Added to inventory.'
                      : 'Bet items were absorbed by the arena vault.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          // Roll Percentile
          Text(
            'Roll: ${result.rollPercentile.toStringAsFixed(1)}%',
            style: const TextStyle(
              color: Colors.white54,
              fontFamily: 'monospace',
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

