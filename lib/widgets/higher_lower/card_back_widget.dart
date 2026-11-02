import 'package:flutter/material.dart';

/// Luxury face-down playing card back matching Image 3:
/// - Rich burgundy/maroon canvas
/// - Gold double border
/// - Diamond lattice cross-hatch texture
/// - Center gold star medallion
class CardBackWidget extends StatelessWidget {
  final double width;
  final double height;

  const CardBackWidget({
    super.key,
    this.width = 150,
    this.height = 215,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF4A101D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4AF37), width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Diamond lattice background pattern
            CustomPaint(
              size: Size(width, height),
              painter: _CardLatticePainter(),
            ),

            // Inner gold frame
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.7),
                  width: 1.5,
                ),
              ),
            ),

            // Center Gold Star Medallion
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [
                    Color(0xFFFDE047),
                    Color(0xFFEAB308),
                    Color(0xFF854D0E),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFFFFFBEB),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.star_rounded,
                  color: Color(0xFF78350F),
                  size: 34,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardLatticePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF701A2B).withValues(alpha: 0.5)
      ..strokeWidth = 1.0;

    const spacing = 12.0;

    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
      canvas.drawLine(
        Offset(i, size.height),
        Offset(i + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

