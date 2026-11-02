import 'package:flutter/material.dart';
import '../../models/higher_lower/higher_lower_models.dart';

/// Primary action button at the bottom of the screen:
/// - "Start game ✦ 1"
/// - "Collect ⚡ 1.26"
/// - "Play again ✦ 1"
class HigherLowerActionButtonWidget extends StatelessWidget {
  final HigherLowerRoundState state;
  final double betAmount;
  final double potentialPayout;
  final HigherLowerCurrency currency;
  final int wins;
  final VoidCallback onStartGame;
  final VoidCallback onCollect;
  final VoidCallback onPlayAgain;

  const HigherLowerActionButtonWidget({
    super.key,
    required this.state,
    required this.betAmount,
    required this.potentialPayout,
    required this.currency,
    required this.wins,
    required this.onStartGame,
    required this.onCollect,
    required this.onPlayAgain,
  });

  @override
  Widget build(BuildContext context) {
    final currencySymbol = currency == HigherLowerCurrency.stars ? '⭐' : 'TON';

    Widget button;
    switch (state) {
      case HigherLowerRoundState.idle:
        button = _buildButton(
          title: 'Start game',
          accentText: currency == HigherLowerCurrency.stars
              ? '${betAmount.round()} ⭐'
              : '$betAmount TON',
          color: const Color(0xFF22C55E),
          textColor: Colors.white,
          onTap: onStartGame,
        );
        break;

      case HigherLowerRoundState.correct:
        button = _buildButton(
          title: 'Collect',
          accentText: '$potentialPayout $currencySymbol',
          color: const Color(0xFF22C55E),
          textColor: Colors.white,
          onTap: onCollect,
        );
        break;

      case HigherLowerRoundState.wrong:
        button = _buildButton(
          title: 'Play again',
          accentText: currency == HigherLowerCurrency.stars
              ? '${betAmount.round()} ⭐'
              : '$betAmount TON',
          color: const Color(0xFF22C55E),
          textColor: Colors.white,
          onTap: onPlayAgain,
        );
        break;

      case HigherLowerRoundState.collected:
        button = _buildButton(
          title: 'Play again',
          accentText: currency == HigherLowerCurrency.stars
              ? '${betAmount.round()} ⭐'
              : '$betAmount TON',
          color: const Color(0xFF22C55E),
          textColor: Colors.white,
          onTap: onPlayAgain,
        );
        break;

      case HigherLowerRoundState.playing:
        button = _buildButton(
          title: 'Collect',
          accentText: wins > 0 ? '$potentialPayout $currencySymbol' : null,
          color: wins > 0 ? const Color(0xFF22C55E) : const Color(0xFF282C37),
          textColor: wins > 0 ? Colors.white : Colors.white38,
          onTap: wins > 0 ? onCollect : () {},
        );
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          button,
          const SizedBox(height: 6),
          Text(
            'Wins: $wins',
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required String title,
    String? accentText,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: color != const Color(0xFF282C37)
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (accentText != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  accentText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

