import 'package:flutter/material.dart';
import '../../features/upgrade_game/view_models/upgrade_game_view_model.dart';

/// Row with Big Lime Green "Spin" button + "Demo" toggle button.
class UpgradeActionButtons extends StatelessWidget {
  final UpgradeGameViewModel viewModel;

  const UpgradeActionButtons({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final canSpin = !viewModel.isSpinning &&
        viewModel.totalBetValue > 0 &&
        viewModel.isValidTarget;

    return Row(
      children: [
        // Spin Button
        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: canSpin ? () => viewModel.executeUpgrade() : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canSpin
                    ? const Color(0xFF8CC63F)
                    : const Color(0xFF8CC63F).withValues(alpha: 0.25),
                foregroundColor: Colors.black,
                disabledBackgroundColor: const Color(0xFF8CC63F).withValues(alpha: 0.15),
                disabledForegroundColor: Colors.black38,
                elevation: canSpin ? 6 : 0,
                shadowColor: const Color(0xFF8CC63F).withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(
                viewModel.isSpinning ? 'UPGRADING...' : 'SPIN',
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        // Demo Mode Toggle Button
        SizedBox(
          height: 52,
          child: OutlinedButton(
            onPressed: viewModel.isSpinning ? null : () => viewModel.toggleDemoMode(),
            style: OutlinedButton.styleFrom(
              backgroundColor: viewModel.isDemoMode
                  ? const Color(0xFF10B981).withValues(alpha: 0.2)
                  : const Color(0xFF1A1E2B),
              side: BorderSide(
                color: viewModel.isDemoMode
                    ? const Color(0xFF34D399)
                    : Colors.white.withValues(alpha: 0.12),
                width: 1.3,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 22),
            ),
            child: Text(
              'Demo',
              style: TextStyle(
                color: viewModel.isDemoMode ? const Color(0xFF6EE7B7) : Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

