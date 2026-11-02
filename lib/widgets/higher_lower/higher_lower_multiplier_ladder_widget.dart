import 'package:flutter/material.dart';

/// Floating ladder pills to the right of the active card:
/// - [^ ×Higher]
/// - [Now ×Current]
/// - [v ×Lower / Skip]
class HigherLowerMultiplierLadderWidget extends StatelessWidget {
  final double higherMultiplier;
  final double currentMultiplier;
  final double lowerMultiplier;
  final bool canCallHigher;
  final bool canCallLower;
  final bool isEdgeCard;

  const HigherLowerMultiplierLadderWidget({
    super.key,
    required this.higherMultiplier,
    required this.currentMultiplier,
    required this.lowerMultiplier,
    required this.canCallHigher,
    required this.canCallLower,
    this.isEdgeCard = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Pill: Higher projected multiplier
        _buildPill(
          icon: Icons.keyboard_arrow_up_rounded,
          text: canCallHigher ? '×${higherMultiplier.toStringAsFixed(2)}' : '—',
          isGold: false,
        ),
        const SizedBox(height: 6),

        // Middle Pill: Current active multiplier ("Now")
        _buildPill(
          prefix: 'Now',
          text: '×${currentMultiplier.toStringAsFixed(2)}',
          isGold: true,
        ),
        const SizedBox(height: 6),

        // Bottom Pill: Lower projected multiplier
        _buildPill(
          icon: Icons.keyboard_arrow_down_rounded,
          text: canCallLower
              ? '×${lowerMultiplier.toStringAsFixed(2)}'
              : (isEdgeCard ? 'Skip' : '—'),
          isGold: false,
        ),
      ],
    );
  }

  Widget _buildPill({
    IconData? icon,
    String? prefix,
    required String text,
    required bool isGold,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isGold
            ? const Color(0xFFEAB308)
            : const Color(0xFF1E212D).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isGold
              ? const Color(0xFFFEF08A)
              : Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isGold
                ? const Color(0xFFEAB308).withValues(alpha: 0.4)
                : Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: isGold ? Colors.black87 : Colors.white70,
            ),
            const SizedBox(width: 2),
          ],
          if (prefix != null) ...[
            Text(
              prefix,
              style: TextStyle(
                color: isGold ? Colors.black87 : Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: isGold ? Colors.black : Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

