import 'package:flutter/material.dart';
import '../../models/tower_game/tower_game_models.dart';
import 'tower_tile_widget.dart';

/// One row of the Tower (multiplier pill + 5 tiles).
class TowerRowWidget extends StatelessWidget {
  final int rowIndex;
  final double multiplier;
  final bool isRowActive;
  final bool isRowCompleted;
  final bool isProcessing;
  final List<TowerTileState> tiles;
  final void Function(int colIndex) onTileTap;

  const TowerRowWidget({
    super.key,
    required this.rowIndex,
    required this.multiplier,
    required this.isRowActive,
    required this.isRowCompleted,
    required this.isProcessing,
    required this.tiles,
    required this.onTileTap,
  });

  @override
  Widget build(BuildContext context) {
    // Multiplier color gradient based on row elevation
    Color multTextColor;
    Color multBgColor;
    Color multBorderColor;

    if (isRowActive) {
      multTextColor = Colors.white;
      multBgColor = const Color(0xFF7C3AED);
      multBorderColor = const Color(0xFFA78BFA);
    } else if (isRowCompleted) {
      multTextColor = const Color(0xFF6EE7B7);
      multBgColor = const Color(0xFF065F46).withValues(alpha: 0.35);
      multBorderColor = const Color(0xFF059669).withValues(alpha: 0.4);
    } else if (rowIndex >= 5) {
      multTextColor = const Color(0xFFD8B4FE);
      multBgColor = const Color(0xFF3B0764).withValues(alpha: 0.4);
      multBorderColor = const Color(0xFFA855F7).withValues(alpha: 0.25);
    } else if (rowIndex >= 3) {
      multTextColor = const Color(0xFFA5B4FC);
      multBgColor = const Color(0xFF1E1B4B).withValues(alpha: 0.4);
      multBorderColor = const Color(0xFF6366F1).withValues(alpha: 0.25);
    } else if (rowIndex >= 1) {
      multTextColor = const Color(0xFF7DD3FC);
      multBgColor = const Color(0xFF082F49).withValues(alpha: 0.4);
      multBorderColor = const Color(0xFF0EA5E9).withValues(alpha: 0.25);
    } else {
      multTextColor = const Color(0xFF67E8F9);
      multBgColor = const Color(0xFF164E63).withValues(alpha: 0.4);
      multBorderColor = const Color(0xFF06B6D4).withValues(alpha: 0.25);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: isRowActive
            ? const Color(0xFF7C3AED).withValues(alpha: 0.12)
            : isRowCompleted
                ? const Color(0xFF1E293B).withValues(alpha: 0.4)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isRowActive
              ? const Color(0xFFA855F7).withValues(alpha: 0.4)
              : Colors.transparent,
          width: 1.2,
        ),
        boxShadow: isRowActive
            ? [
                BoxShadow(
                  color: const Color(0xFFA855F7).withValues(alpha: 0.2),
                  blurRadius: 10,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Row Multiplier Pill
          Container(
            width: 48,
            height: 38,
            decoration: BoxDecoration(
              color: multBgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: multBorderColor),
            ),
            alignment: Alignment.center,
            child: Text(
              'x${multiplier >= 10 ? multiplier.toStringAsFixed(1) : multiplier.toStringAsFixed(2)}',
              style: TextStyle(
                color: multTextColor,
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
              ),
            ),
          ),

          const SizedBox(width: 6),

          // 5 Tiles
          Expanded(
            child: Row(
              children: List.generate(5, (colIdx) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: TowerTileWidget(
                      tile: tiles[colIdx],
                      isRowActive: isRowActive,
                      isProcessing: isProcessing,
                      onTap: () => onTileTap(colIdx),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

