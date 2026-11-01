import 'package:flutter/material.dart';
import '../../features/tower_game/view_models/tower_game_view_model.dart';
import '../../models/tower_game/tower_game_models.dart';
import 'tower_row_widget.dart';

/// 7-Tier Tower Climb Board (Top is row 6, Bottom is row 0).
class TowerBoardWidget extends StatelessWidget {
  final TowerGameViewModel viewModel;

  const TowerBoardWidget({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final multipliers = viewModel.difficulty.multipliers;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1322).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF1E293B),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: List.generate(7, (idx) {
          // Invert: top row is index 6, bottom row is index 0
          final rowIdx = 6 - idx;
          final isRowActive = viewModel.isPlaying && rowIdx == viewModel.currentRow;
          final isRowCompleted = rowIdx < viewModel.currentRow;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: TowerRowWidget(
              rowIndex: rowIdx,
              multiplier: multipliers[rowIdx],
              isRowActive: isRowActive,
              isRowCompleted: isRowCompleted,
              isProcessing: viewModel.isProcessing,
              tiles: viewModel.board[rowIdx],
              onTileTap: (colIdx) => viewModel.pickTile(rowIdx, colIdx),
            ),
          );
        }),
      ),
    );
  }
}

