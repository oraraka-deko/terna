import 'package:flutter/material.dart';
import '../../features/tower_game/view_models/tower_game_view_model.dart';
import '../../models/tower_game/tower_game_models.dart';

/// Primary Play / Cash Out button placed directly below the tower board.
class TowerActionButton extends StatelessWidget {
  final TowerGameViewModel viewModel;

  const TowerActionButton({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final currencySymbol = viewModel.currency == TowerCurrency.ton ? 'TON' : '⭐';

    if (!viewModel.isPlaying) {
      return SizedBox(
        height: 50,
        child: ElevatedButton(
          onPressed: viewModel.isProcessing ? null : () => viewModel.startGame(),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7C3AED),
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFF7C3AED).withValues(alpha: 0.3),
            elevation: 6,
            shadowColor: const Color(0xFF7C3AED).withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: Text(
            viewModel.isProcessing ? 'STARTING RUN...' : 'PLAY',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
      );
    }

    final canCashOut = viewModel.currentRow > 0 && !viewModel.isProcessing;

    if (!canCashOut) {
      return Container(
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        alignment: Alignment.center,
        child: const Text(
          'PICK LEVEL 1 TILE',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
      );
    }

    // Cash Out Button with golden-amber gradient
    return Container(
      height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFBBF24), Color(0xFFF97316), Color(0xFFF59E0B)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => viewModel.cashOut(),
          borderRadius: BorderRadius.circular(18),
          child: Center(
            child: Text(
              'CASH OUT ${viewModel.cashoutValue} $currencySymbol (${viewModel.currentMultiplier.toStringAsFixed(2)}×)',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

