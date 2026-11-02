import 'package:flutter/material.dart';

/// Top bar with back button, "Higher or Lower ⓘ" pill, and round history button.
class HigherLowerHeaderWidget extends StatelessWidget {
  final int historyCount;
  final VoidCallback onBack;
  final VoidCallback onShowRules;
  final VoidCallback onShowHistory;

  const HigherLowerHeaderWidget({
    super.key,
    required this.historyCount,
    required this.onBack,
    required this.onShowRules,
    required this.onShowHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            tooltip: 'Back',
          ),

          // Title & Rules Pill
          GestureDetector(
            onTap: onShowRules,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.8),
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

          // History Count Button
          GestureDetector(
            onTap: onShowHistory,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.8),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.history_rounded,
                    color: Colors.white70,
                    size: 20,
                  ),
                  if (historyCount > 0)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
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

