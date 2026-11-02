import 'package:flutter/material.dart';
import '../../models/higher_lower/higher_lower_models.dart';

/// Dynamic status message banner matching screenshots:
/// - "Predict if the next card is higher or lower"
/// - "Correct! Collect or continue for more!"
/// - "Wrong! Try again!"
class HigherLowerStatusWidget extends StatelessWidget {
  final HigherLowerRoundState state;
  final double potentialPayout;
  final HigherLowerCurrency currency;

  const HigherLowerStatusWidget({
    super.key,
    required this.state,
    required this.potentialPayout,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final currencySymbol = currency == HigherLowerCurrency.stars ? '⭐' : 'TON';

    switch (state) {
      case HigherLowerRoundState.correct:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Correct!',
              style: TextStyle(
                color: Color(0xFF4ADE80),
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Collect $potentialPayout $currencySymbol or continue for more!',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );

      case HigherLowerRoundState.wrong:
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Wrong!',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.2,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Streak ended. Try again!',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );

      case HigherLowerRoundState.collected:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Collected!',
              style: TextStyle(
                color: Color(0xFFFBBF24),
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Won $potentialPayout $currencySymbol! Start another round.',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );

      case HigherLowerRoundState.idle:
      case HigherLowerRoundState.playing:
        return const Text(
          'Predict if the next card is higher or lower',
          style: TextStyle(
            color: Colors.white60,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        );
    }
  }
}

