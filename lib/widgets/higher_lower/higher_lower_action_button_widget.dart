import 'package:flutter/material.dart';
import '../../models/higher_lower/higher_lower_models.dart';

/// Primary action button at the bottom of the screen matching screenshots:
/// - "Start game  ✦ 1"
/// - "Collect  ⚡ 1.26"
/// - "Play again  ✦ 1"
/// With bottom footer: "Wins: 0" (left) and "Playing with Stars · switch wallet ↑" (center).
class HigherLowerActionButtonWidget extends StatelessWidget {
  final HigherLowerRoundState state;
  final double betAmount;
  final double potentialPayout;
  final HigherLowerCurrency currency;
  final int wins;
  final VoidCallback onStartGame;
  final VoidCallback onCollect;
  final VoidCallback onPlayAgain;
  final VoidCallback? onSwitchWallet;

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
    this.onSwitchWallet,
  });

  @override
  Widget build(BuildContext context) {
    Widget button;
    switch (state) {
      case HigherLowerRoundState.idle:
        button = _buildButton(
          title: 'Start game',
          accentIcon: currency == HigherLowerCurrency.stars ? '✦' : '💎',
          accentText: currency == HigherLowerCurrency.stars
              ? '${betAmount.round()}'
              : '$betAmount TON',
          color: const Color(0xFF22C55E),
          textColor: Colors.white,
          onTap: onStartGame,
        );
        break;

      case HigherLowerRoundState.correct:
        button = _buildButton(
          title: 'Collect',
          accentIcon: currency == HigherLowerCurrency.stars ? '⚡' : '💎',
          accentText: currency == HigherLowerCurrency.stars
              ? '${potentialPayout.round()}'
              : '$potentialPayout TON',
          color: const Color(0xFF22C55E),
          textColor: Colors.white,
          onTap: onCollect,
        );
        break;

      case HigherLowerRoundState.wrong:
        button = _buildButton(
          title: 'Play again',
          accentIcon: currency == HigherLowerCurrency.stars ? '✦' : '💎',
          accentText: currency == HigherLowerCurrency.stars
              ? '${betAmount.round()}'
              : '$betAmount TON',
          color: const Color(0xFF22C55E),
          textColor: Colors.white,
          onTap: onPlayAgain,
        );
        break;

      case HigherLowerRoundState.collected:
        button = _buildButton(
          title: 'Play again',
          accentIcon: currency == HigherLowerCurrency.stars ? '✦' : '💎',
          accentText: currency == HigherLowerCurrency.stars
              ? '${betAmount.round()}'
              : '$betAmount TON',
          color: const Color(0xFF22C55E),
          textColor: Colors.white,
          onTap: onPlayAgain,
        );
        break;

      case HigherLowerRoundState.playing:
        button = _buildButton(
          title: 'Collect',
          accentIcon: wins > 0 ? (currency == HigherLowerCurrency.stars ? '⚡' : '💎') : null,
          accentText: wins > 0
              ? (currency == HigherLowerCurrency.stars
                  ? '${potentialPayout.round()}'
                  : '$potentialPayout TON')
              : null,
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
          const SizedBox(height: 8),

          // Bottom footer row matching screenshots
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Wins: $wins',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                GestureDetector(
                  onTap: onSwitchWallet,
                  child: Text(
                    'Playing with ${currency == HigherLowerCurrency.stars ? "Stars" : "TON"} · switch wallet ↑',
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 32), // balance spacer
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required String title,
    String? accentIcon,
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
              if (accentIcon != null) ...[
                Text(
                  accentIcon,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFFDE047),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                accentText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
