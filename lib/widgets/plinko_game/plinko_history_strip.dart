import 'package:flutter/material.dart';
import '../../models/plinko_game/plinko_models.dart';

/// Horizontal scrolling strip displaying recent landing multiplier hits.
class PlinkoHistoryStrip extends StatelessWidget {
  final List<PlinkoWinRecord> recentMultipliers;

  const PlinkoHistoryStrip({
    super.key,
    required this.recentMultipliers,
  });

  @override
  Widget build(BuildContext context) {
    if (recentMultipliers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Icon(Icons.history_rounded, color: Color(0xFF22D3EE), size: 14),
          const SizedBox(width: 4),
          const Text(
            'HITS:',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: recentMultipliers.map((rec) {
                  return Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: rec.color,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: rec.color.withValues(alpha: 0.35),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Text(
                      '${rec.multiplier >= 100 ? rec.multiplier.toStringAsFixed(0) : rec.multiplier}×',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

