import 'package:flutter/material.dart';
import '../../models/tower_game/tower_game_models.dart';

/// Single tile component for Tower Climb game board.
class TowerTileWidget extends StatelessWidget {
  final TowerTileState tile;
  final bool isRowActive;
  final bool isProcessing;
  final VoidCallback onTap;

  const TowerTileWidget({
    super.key,
    required this.tile,
    required this.isRowActive,
    required this.isProcessing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final canTap = isRowActive && !isProcessing && tile.status == TowerTileStatus.hidden;

    BoxDecoration decoration;
    Widget content;

    switch (tile.status) {
      case TowerTileStatus.safe:
        decoration = BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF34D399),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.25),
              blurRadius: 6,
            ),
          ],
        );
        content = const Text('💎', style: TextStyle(fontSize: 16));
        break;

      case TowerTileStatus.trap:
        if (tile.isPicked) {
          decoration = BoxDecoration(
            color: const Color(0xFFEF4444),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFF87171),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEF4444).withValues(alpha: 0.5),
                blurRadius: 8,
              ),
            ],
          );
        } else {
          decoration = BoxDecoration(
            color: const Color(0xFF450A0A).withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFEF4444).withValues(alpha: 0.3),
            ),
          );
        }
        content = const Text('💀', style: TextStyle(fontSize: 16));
        break;

      case TowerTileStatus.hidden:
        if (isRowActive) {
          decoration = BoxDecoration(
            color: const Color(0xFF1A2238),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFA855F7).withValues(alpha: 0.45),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFA855F7).withValues(alpha: 0.2),
                blurRadius: 6,
              ),
            ],
          );
          content = const Text(
            '?',
            style: TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 13,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          );
        } else {
          decoration = BoxDecoration(
            color: const Color(0xFF151C30).withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF1E293B),
            ),
          );
          content = const Text(
            '?',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          );
        }
        break;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canTap ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 42,
          decoration: decoration,
          child: Center(child: content),
        ),
      ),
    );
  }
}

