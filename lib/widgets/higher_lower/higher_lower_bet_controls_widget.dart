import 'package:flutter/material.dart';
import '../../models/higher_lower/higher_lower_models.dart';

/// Betting input and max win preview matching screenshots:
/// [ Bet  ✦ 1 ]    [ Max win  ⚡ 20 Stars ]
class HigherLowerBetControlsWidget extends StatelessWidget {
  final double betAmount;
  final HigherLowerCurrency currency;
  final double maxWin;
  final bool isInteractive;
  final ValueChanged<double> onBetChanged;
  final ValueChanged<HigherLowerCurrency> onCurrencyChanged;

  const HigherLowerBetControlsWidget({
    super.key,
    required this.betAmount,
    required this.currency,
    required this.maxWin,
    required this.isInteractive,
    required this.onBetChanged,
    required this.onCurrencyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final currencySymbol = currency == HigherLowerCurrency.stars ? '⭐' : 'TON';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Bet Box
              Expanded(
                child: GestureDetector(
                  onTap: isInteractive ? () => _showBetModal(context) : null,
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B161B).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Bet',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              currency == HigherLowerCurrency.stars
                                  ? Icons.star_rounded
                                  : Icons.diamond_rounded,
                              size: 14,
                              color: currency == HigherLowerCurrency.stars
                                  ? const Color(0xFFFBBF24)
                                  : const Color(0xFF38BDF8),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              currency == HigherLowerCurrency.stars
                                  ? '${betAmount.round()}'
                                  : betAmount.toStringAsFixed(2),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (isInteractive) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_drop_down, color: Colors.white38, size: 16),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Max Win Box
              Expanded(
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B161B).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Max win',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.bolt_rounded, size: 14, color: Color(0xFF38BDF8)),
                          const SizedBox(width: 2),
                          Text(
                            '${maxWin.toStringAsFixed(currency == HigherLowerCurrency.stars ? 0 : 1)} $currencySymbol',
                            style: const TextStyle(
                              color: Color(0xFF38BDF8),
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Switch Wallet link
          if (isInteractive)
            GestureDetector(
              onTap: () {
                onCurrencyChanged(
                  currency == HigherLowerCurrency.stars
                      ? HigherLowerCurrency.ton
                      : HigherLowerCurrency.stars,
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Playing with ${currency == HigherLowerCurrency.stars ? "Stars" : "TON"} · switch wallet ↑',
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showBetModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161922),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Adjust Bet Amount',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  for (final amount in currency == HigherLowerCurrency.stars
                      ? [1.0, 5.0, 10.0, 25.0, 50.0]
                      : [0.1, 0.5, 1.0, 2.5, 5.0])
                    ChoiceChip(
                      label: Text(
                        currency == HigherLowerCurrency.stars ? '${amount.round()} ⭐' : '$amount TON',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      selected: betAmount == amount,
                      selectedColor: const Color(0xFF1E88E5),
                      backgroundColor: const Color(0xFF222634),
                      onSelected: (selected) {
                        if (selected) {
                          onBetChanged(amount);
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

