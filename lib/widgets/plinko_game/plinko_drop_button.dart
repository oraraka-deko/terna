import 'package:flutter/material.dart';
import '../../features/plinko_game/view_models/plinko_game_view_model.dart';
import '../../models/plinko_game/plinko_models.dart';

/// Big neon lime action button to drop balls into the Plinko pinboard.
class PlinkoDropButton extends StatelessWidget {
  final PlinkoGameViewModel viewModel;

  const PlinkoDropButton({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final currencySymbol = viewModel.currency == PlinkoCurrency.ton ? 'TON' : '⭐';
    final amountFormatted = viewModel.currency == PlinkoCurrency.ton
        ? viewModel.betAmount.toStringAsFixed(2)
        : viewModel.betAmount.toInt().toString();

    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: viewModel.isDropping ? null : () => viewModel.dropBall(),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFCCFF00),
          foregroundColor: Colors.black,
          elevation: 6,
          shadowColor: const Color(0xFFCCFF00).withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (viewModel.isDropping)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              )
            else
              const Icon(Icons.auto_awesome_rounded,
                  color: Colors.black, size: 18),
            const SizedBox(width: 8),
            Text(
              viewModel.isDropping
                  ? 'SUBMITTING BET...'
                  : 'DROP BALL ($amountFormatted $currencySymbol)',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
