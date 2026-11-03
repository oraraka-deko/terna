import 'package:flutter/material.dart';
import '../../models/higher_lower/higher_lower_models.dart';

/// Prediction Call Buttons matching screenshots:
/// [ Higher        ]   [ (v) Lower      ]
/// [ ×1.26         ]   [ ×3.80 / Skip   ]
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
    final showSkip = isEdgeCard && !canCallLower;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // HIGHER Button (no leading icon, bold text + multiplier below)
          Expanded(
            child: _buildHigherButton(
              isEnabled: isInteractive && canCallHigher,
              multiplier: canCallHigher ? '×${higherMultiplier.toStringAsFixed(2)}' : '—',
              onTap: () => onCall(PredictionType.higher),
            ),
          ),
          const SizedBox(width: 12),

          // LOWER or SKIP Button (with circular icon badge)
          Expanded(
            child: _buildLowerOrSkipButton(
              isSkip: showSkip,
              isEnabled: isInteractive && (canCallLower || showSkip),
              subtitle: canCallLower ? '×${lowerMultiplier.toStringAsFixed(2)}' : '—',
              onTap: () => onCall(showSkip ? PredictionType.skip : PredictionType.lower),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHigherButton({
    required bool isEnabled,
    required String multiplier,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Higher',
              style: TextStyle(
                color: isEnabled ? const Color(0xFF1E293B) : Colors.white38,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              multiplier,
              style: TextStyle(
                color: isEnabled ? const Color(0xFF15803D) : Colors.white24,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLowerOrSkipButton({
    required bool isSkip,
    required bool isEnabled,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final title = isSkip ? 'Skip' : 'Lower';
    final badgeColor = isSkip ? const Color(0xFF3B82F6) : const Color(0xFFB91C1C);
    final badgeIcon = isSkip ? Icons.skip_next_rounded : Icons.keyboard_arrow_down_rounded;

    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
            // Circular icon badge matching screenshot
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: isEnabled ? badgeColor : Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  badgeIcon,
                  size: 17,
                  color: isEnabled ? Colors.white : Colors.white30,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Title & Subtitle column
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
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isEnabled ? badgeColor : Colors.white24,
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
