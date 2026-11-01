import 'package:flutter/material.dart';
import '../../features/tower_game/view_models/tower_game_view_model.dart';
import '../../models/tower_game/tower_game_models.dart';
import '../../services/haptic.dart';

/// Top header bar for Tower Climb game matching original UI design.
class TowerHeaderBar extends StatelessWidget {
  final TowerGameViewModel viewModel;
  final VoidCallback onBack;

  const TowerHeaderBar({
    super.key,
    required this.viewModel,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isTon = viewModel.currency == TowerCurrency.ton;
    final balanceStr = isTon
        ? viewModel.tonBalance.toStringAsFixed(2)
        : viewModel.starsBalance.toString();

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
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF334155).withValues(alpha: 0.6),
                ),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),

        // Game Title
        const Text(
          'TOWER',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.5,
            fontFamily: 'monospace',
          ),
        ),

        // Balance Pill with currency toggle & plus indicator
        GestureDetector(
          onTap: () {
            if (!viewModel.isPlaying) {
              viewModel.setCurrency(
                isTon ? TowerCurrency.stars : TowerCurrency.ton,
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF334155).withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isTon ? '💎' : '⭐',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 4),
                Text(
                  balanceStr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Color(0xFF9333EA),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '+',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

