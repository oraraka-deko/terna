import 'package:flutter/material.dart';
import '../../features/plinko_game/view_models/plinko_game_view_model.dart';
import '../../models/plinko_game/plinko_models.dart';
import 'plinko_board_painter.dart';

/// Main interactive Plinko pinboard canvas frame with overlays.
class PlinkoBoardWidget extends StatelessWidget {
  final PlinkoGameViewModel viewModel;

  const PlinkoBoardWidget({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final currencySymbol = viewModel.currency == PlinkoCurrency.ton ? 'TON' : '⭐';

    return AspectRatio(
      aspectRatio: 380.0 / 470.0,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF070913),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF06B6D4).withValues(alpha: 0.15),
              blurRadius: 16,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.7),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // 1. Canvas Pinboard
            Positioned.fill(
              child: CustomPaint(
                painter: PlinkoBoardPainter(
                  pegs: viewModel.pegs,
                  buckets: viewModel.buckets,
                  balls: viewModel.balls,
                ),
              ),
            ),

            // 2. Active In-Flight Balls Badge
            if (viewModel.activeBallsCount > 0)
              Positioned(
                top: 10,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF22D3EE),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${viewModel.activeBallsCount} active',
                        style: const TextStyle(
                          color: Color(0xFF67E8F9),
                          fontSize: 9.5,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // 3. Live Multiplier Win Notification Toast
            if (viewModel.lastWin != null)
              Positioned(
                top: 10,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFCCFF00).withValues(alpha: 0.5),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Landed ',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 10,
                            fontFamily: 'monospace',
                          ),
                        ),
                        Text(
                          '${viewModel.lastWin!.multiplier}× ',
                          style: const TextStyle(
                            color: Color(0xFFCCFF00),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace',
                          ),
                        ),
                        Text(
                          '(+${viewModel.lastWin!.payout} $currencySymbol)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

