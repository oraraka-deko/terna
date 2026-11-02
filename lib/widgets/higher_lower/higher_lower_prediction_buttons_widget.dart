import 'package:flutter/material.dart';
import '../../models/higher_lower/higher_lower_models.dart';

/// Prediction Call Buttons:
/// [ Higher  ×1.26 ]   [ (v) Lower  ×3.80 / (>|) Skip ]
class HigherLowerPredictionButtonsWidget extends StatelessWidget {
  final bool isInteractive;
  final bool canCallHigher;
  final bool canCallLower;
  final bool isEdgeCard;
  final double higherMultiplier;
  final double lowerMultiplier;
  final ValueChanged<PredictionType> onCall;

  const HigherLowerPredictionButtonsWidget({
    super.key,
    required this.isInteractive,
    required this.canCallHigher,
    required this.canCallLower,
    required this.isEdgeCard,
    required this.higherMultiplier,
    required this.lowerMultiplier,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // HIGHER Button
          Expanded(
            child: _buildPredictButton(
              title: 'Higher',
              subtitle: canCallHigher ? '×${higherMultiplier.toStringAsFixed(2)}' : '—',
              icon: Icons.keyboard_arrow_up_rounded,
              iconColor: const Color(0xFF22C55E),
              isEnabled: isInteractive && canCallHigher,
              onTap: () => onCall(PredictionType.higher),
            ),
          ),
          const SizedBox(width: 12),

          // LOWER or SKIP Button
          Expanded(
            child: _buildPredictButton(
              title: isEdgeCard && !canCallLower ? 'Skip' : 'Lower',
              subtitle: canCallLower
                  ? '×${lowerMultiplier.toStringAsFixed(2)}'
                  : (isEdgeCard ? '—' : '—'),
              icon: isEdgeCard && !canCallLower
                  ? Icons.skip_next_rounded
                  : Icons.keyboard_arrow_down_rounded,
              iconColor: const Color(0xFFEF4444),
              isEnabled: isInteractive && (canCallLower || isEdgeCard),
              onTap: () => onCall(
                isEdgeCard && !canCallLower ? PredictionType.skip : PredictionType.lower,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isEnabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isEnabled ? const Color(0xFFFFFBEB) : const Color(0xFF232634),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isEnabled
                ? Colors.white.withValues(alpha: 0.9)
                : Colors.white.withValues(alpha: 0.06),
            width: 1.5,
          ),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Circular icon badge
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isEnabled
                    ? iconColor.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 18,
                  color: isEnabled ? iconColor : Colors.white30,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Texts
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isEnabled ? const Color(0xFF1E293B) : Colors.white38,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isEnabled
                          ? (title == 'Higher'
                              ? const Color(0xFF15803D)
                              : const Color(0xFFB91C1C))
                          : Colors.white24,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

