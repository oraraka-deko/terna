import 'package:flutter/material.dart';
import 'package:terna/models/sun_or_moon/coin_side.dart';

class ResultBanner extends StatelessWidget {
  final bool? won;
  final CoinSide? outcome;
  final int betAmount;
  final bool isFlipping;

  const ResultBanner({
    super.key,
    required this.won,
    required this.outcome,
    required this.betAmount,
    required this.isFlipping,
  });

  @override
  Widget build(BuildContext context) {
    if (isFlipping) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF231942).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFB388FF).withValues(alpha: 0.3),
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFD54F), size: 18),
            SizedBox(width: 8),
            Text(
              'The cosmos is choosing...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    }

    if (won == null || outcome == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'Pick Sun or Moon and flip to test your fortune!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    final isWin = won == true;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isWin
            ? const Color(0xFF1B4332).withValues(alpha: 0.9)
            : const Color(0xFF4A1521).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isWin ? const Color(0xFF52B788) : const Color(0xFFE63946),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isWin ? const Color(0xFF52B788) : const Color(0xFFE63946))
                .withValues(alpha: 0.4),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isWin ? Icons.celebration_rounded : Icons.lock_rounded,
            color: isWin ? const Color(0xFF69F0AE) : const Color(0xFFFF5252),
            size: 22,
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isWin
                    ? 'WIN! 2X PAYOUT (+ \$$betAmount)'
                    : 'LOST! \$$betAmount LOCKED BY SYSTEM',
                style: TextStyle(
                  color: isWin ? const Color(0xFF69F0AE) : const Color(0xFFFF8A80),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'Landed on ${outcome!.emoji} ${outcome!.displayName.toUpperCase()}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
