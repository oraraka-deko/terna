import 'package:flutter/material.dart';

/// "How to Play" Modal Dialog matching Image 3 left panel.
class HigherLowerRulesDialog extends StatelessWidget {
  const HigherLowerRulesDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => const HigherLowerRulesDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF161B26),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Top card icons banner
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFD97706), width: 1.5),
                  ),
                  child: const Center(
                    child: Text('K♦', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 38,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A101D),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
                  ),
                  child: const Center(
                    child: Icon(Icons.star_rounded, color: Color(0xFFEAB308), size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'To win',
                style: TextStyle(
                  color: Color(0xFF4ADE80),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 8),

            const Text(
              'Call the next card right',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Keep calling to multiply your win',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white60,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 18),
            const Divider(color: Colors.white10),
            const SizedBox(height: 12),

            // Rules Bullet points
            _buildRuleItem(
              icon: Icons.trending_up_rounded,
              title: 'Higher or lower',
              desc: 'Each call shows the exact multiplier it pays based on probability.',
            ),
            const SizedBox(height: 10),
            _buildRuleItem(
              icon: Icons.payments_rounded,
              title: 'Collect anytime',
              desc: 'Collect anytime after a right call or continue building your streak.',
            ),
            const SizedBox(height: 10),
            _buildRuleItem(
              icon: Icons.skip_next_rounded,
              title: 'Skip edge cards',
              desc: 'Dealt an Ace or 2? Use Skip to cycle to a fresh card without risk.',
            ),

            const SizedBox(height: 20),

            // Dismiss Button
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  'Got it',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleItem({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Center(child: Icon(icon, color: const Color(0xFF38BDF8), size: 18)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(color: Colors.white60, fontSize: 11, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

