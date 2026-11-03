import 'package:flutter/material.dart';

/// Top bar matching screenshots:
/// - Left: [ 4 v ] pill showing remaining deck cards with dropdown arrow
/// - Center: [ 🎴 Higher or Lower ⓘ ] title and rules pill
/// - Right: ( ⟲ count ) circular drawn history button
class HigherLowerHeaderWidget extends StatelessWidget {
  final int deckCount;
  final int historyCount;
  final VoidCallback onBack;
  final VoidCallback onShowRules;
  final VoidCallback onShowHistory;
  final VoidCallback? onShowDeckStats;

  const HigherLowerHeaderWidget({
    super.key,
    this.deckCount = 51,
    required this.historyCount,
    required this.onBack,
    required this.onShowRules,
    required this.onShowHistory,
    this.onShowDeckStats,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Deck count dropdown pill [ 4 v ]
          GestureDetector(
            onTap: onShowDeckStats ?? onBack,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF1B2234),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$deckCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.white54,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),

          // Center: Title & Rules Pill [ 🎴 Higher or Lower ⓘ ]
          GestureDetector(
            onTap: onShowRules,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1B2234),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.style_rounded,
                    color: Color(0xFF4ADE80),
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Higher or Lower',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.info_outline_rounded,
                    color: Colors.white54,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),

          // Right: ( ⟲ count ) Circular History Button
          GestureDetector(
            onTap: onShowHistory,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF1B2234),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.replay_rounded,
                    color: Colors.white70,
                    size: 18,
                  ),
                  if (historyCount > 0)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: const BoxDecoration(
                          color: Color(0xFF38BDF8),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$historyCount',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
