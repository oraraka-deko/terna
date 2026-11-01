import 'package:flutter/material.dart';
import '../../features/plinko_game/view_models/plinko_game_view_model.dart';
import '../../models/plinko_game/plinko_models.dart';
import '../../services/haptic.dart';

/// Top header bar for Plinko with Games back button, Currency switcher, and Risk selector.
class PlinkoHeaderBar extends StatelessWidget {
  final PlinkoGameViewModel viewModel;
  final VoidCallback onBack;

  const PlinkoHeaderBar({
    super.key,
    required this.viewModel,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Back Button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedbackService.tap();
              onBack();
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 13),
                  SizedBox(width: 4),
                  Text(
                    'Games',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        Row(
          children: [
            // Currency Switcher
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  _buildCurrencyBtn(
                    label: '💎 TON',
                    currency: PlinkoCurrency.ton,
                    activeColor: const Color(0xFF06B6D4),
                  ),
                  _buildCurrencyBtn(
                    label: '⭐ Stars',
                    currency: PlinkoCurrency.stars,
                    activeColor: const Color(0xFFFBBF24),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 6),

            // Risk Level Selector
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: PlinkoRisk.values.map((r) {
                  final isActive = viewModel.risk == r;

                  return GestureDetector(
                    onTap: () => viewModel.setRisk(r),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive ? r.activeColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        r.label,
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.white38,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCurrencyBtn({
    required String label,
    required PlinkoCurrency currency,
    required Color activeColor,
  }) {
    final isActive = viewModel.currency == currency;

    return GestureDetector(
      onTap: () => viewModel.setCurrency(currency),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.black : Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

