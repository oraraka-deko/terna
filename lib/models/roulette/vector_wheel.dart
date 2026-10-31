import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:terna/models/roulette/roulette_pocket.dart';

class RouletteWheelPainter extends CustomPainter {
  final double rotationAngle; // Radians of wheel rotation
  final List<RoulettePocket> pockets;
  final double ballAngle; // Radians of ball rotation
  final double ballRadiusFactor; // 0.0 (center) to 1.0 (outer rim border)
  final String? highlightedPocket; // Label of pocket to highlight (when resting)
  final double highlightPulse; // Animation value for pulsing highlight (0.0 to 1.0)

  RouletteWheelPainter({
    required this.rotationAngle,
    required this.pockets,
    required this.ballAngle,
    required this.ballRadiusFactor,
    this.highlightedPocket,
    this.highlightPulse = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) / 2;
    
    // Radii ratios
    final woodRimRadius = maxRadius;
    final outerGoldBorder = woodRimRadius * 0.94;
    final wheelBaseRadius = outerGoldBorder * 0.95;
    final pocketOuterRadius = wheelBaseRadius * 0.96;
    final pocketInnerRadius = pocketOuterRadius * 0.70;
    final trackRadius = (pocketOuterRadius + woodRimRadius * 0.94) / 2;
    final centerHubRadius = pocketInnerRadius * 0.65;
    final centerConeRadius = centerHubRadius * 0.40;

    final arcAngle = (2 * math.pi) / pockets.length;

    // 1. Draw Mahogany Outer Rim & Wood Ring
    final woodPaint = Paint()
      ..shader = const SweepGradient(
        colors: [
          Color(0xFF3D1E0B),
          Color(0xFF5A2E12),
          Color(0xFF2C1406),
          Color(0xFF5A2E12),
          Color(0xFF3D1E0B),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: woodRimRadius));
    canvas.drawCircle(center, woodRimRadius, woodPaint);

    // Outer Gold Rim Trim
    final goldBorderPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFDF00), Color(0xFFD4AF37), Color(0xFF996515)],
      ).createShader(Rect.fromCircle(center: center, radius: outerGoldBorder))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawCircle(center, outerGoldBorder, goldBorderPaint);

    // Inner Track Felt Base (Dark Metallic Green/Black)
    final feltTrackPaint = Paint()
      ..color = const Color(0xFF102615)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, wheelBaseRadius, feltTrackPaint);

    // Draw Brass Track Deflectors (8 Metal Pins along the outer track)
    for (int i = 0; i < 8; i++) {
      final pinAngle = (i * math.pi / 4);
      final pinOffset = Offset(
        center.dx + math.cos(pinAngle) * trackRadius,
        center.dy + math.sin(pinAngle) * trackRadius,
      );
      final pinPaint = Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFFFF099), Color(0xFFB38F00)],
        ).createShader(Rect.fromCircle(center: pinOffset, radius: 4));
      canvas.drawCircle(pinOffset, 4, pinPaint);
    }

    // --- WHEEL ROTATION GROUP ---
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotationAngle);

    // 2. Draw Wheel Pocket Sectors & Dividers
    for (int i = 0; i < pockets.length; i++) {
      final pocket = pockets[i];
      final startAngle = i * arcAngle - (arcAngle / 2) - (math.pi / 2);
      final isHighlighted = highlightedPocket != null && pocket.label == highlightedPocket;

      Color pocketColor;
      switch (pocket.color) {
        case PocketColor.green:
          pocketColor = const Color(0xFF008837);
          break;
        case PocketColor.red:
          pocketColor = const Color(0xFFD31A1A);
          break;
        case PocketColor.black:
          pocketColor = const Color(0xFF1A1A1A);
          break;
      }

      final sectorPaint = Paint()..style = PaintingStyle.fill;

      if (isHighlighted && highlightPulse > 0) {
        sectorPaint.color = Color.lerp(pocketColor, const Color(0xFFFFD700), highlightPulse * 0.8)!;
      } else {
        sectorPaint.color = pocketColor;
      }

      final sectorPath = Path()
        ..moveTo(0, 0)
        ..arcTo(
          Rect.fromCircle(center: Offset.zero, radius: pocketOuterRadius),
          startAngle,
          arcAngle,
          false,
        )
        ..close();

      canvas.drawPath(sectorPath, sectorPaint);

      // Silver metal separators between pockets
      final borderPaint = Paint()
        ..color = const Color(0xFFCCCCCC)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;
      canvas.drawPath(sectorPath, borderPaint);

      // Radial Pocket Labels
      canvas.save();
      final textAngle = startAngle + (arcAngle / 2);
      canvas.rotate(textAngle + math.pi / 2);

      final textSpan = TextSpan(
        text: pocket.label,
        style: TextStyle(
          color: isHighlighted ? const Color(0xFFFFD700) : Colors.white,
          fontSize: pockets.length > 30 ? 10 : 12,
          fontWeight: FontWeight.bold,
          shadows: isHighlighted
              ? [const Shadow(color: Colors.amber, blurRadius: 6)]
              : [const Shadow(color: Colors.black, blurRadius: 2)],
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -pocketOuterRadius + (pocketOuterRadius - pocketInnerRadius) / 4),
      );
      canvas.restore();
    }

    // 3. Inner Pocket Rim Line & Center Silver Plate
    final innerRimPaint = Paint()
      ..color = const Color(0xFFD4AF37)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(Offset.zero, pocketInnerRadius, innerRimPaint);

    final innerPlatePaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFE6E6E6), Color(0xFF888888), Color(0xFF444444)],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: pocketInnerRadius));
    canvas.drawCircle(Offset.zero, pocketInnerRadius, innerPlatePaint);

    // 4. Center Golden Brass Turret Hub
    final hubPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFF2A3), Color(0xFFD4AF37), Color(0xFF805A00)],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: centerHubRadius));
    canvas.drawCircle(Offset.zero, centerHubRadius, hubPaint);

    // Center Metallic Cone Handles (Roulette Turret Handles)
    final conePaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFFB39200)],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: centerConeRadius));
    canvas.drawCircle(Offset.zero, centerConeRadius, conePaint);

    // Cross Handle Arms (Brass handles)
    final handlePaint = Paint()
      ..color = const Color(0xFFD4AF37)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(-centerHubRadius * 0.8, 0), Offset(centerHubRadius * 0.8, 0), handlePaint);
    canvas.drawLine(Offset(0, -centerHubRadius * 0.8), Offset(0, centerHubRadius * 0.8), handlePaint);

    canvas.restore(); // Restore from rotation

    // --- ANIMATED ROULETTE BALL ---
    if (ballRadiusFactor > 0.0) {
      final ballDist = pocketInnerRadius + (pocketOuterRadius - pocketInnerRadius) * ballRadiusFactor;
      final ballPos = Offset(
        center.dx + math.cos(ballAngle) * ballDist,
        center.dy + math.sin(ballAngle) * ballDist,
      );

      // Ball Shadow
      final shadowPaint = Paint()
        ..color = Colors.black45
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(ballPos + const Offset(2, 2), 6.5, shadowPaint);

      // Pure Ivory White Sphere with 3D Specular Highlight
      final ballPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.3),
          radius: 0.8,
          colors: const [Color(0xFFFFFFFF), Color(0xFFEEEEEE), Color(0xFFB0B0B0)],
        ).createShader(Rect.fromCircle(center: ballPos, radius: 6.5));
      canvas.drawCircle(ballPos, 6.5, ballPaint);
    }

    // --- TOP WINNING POINTER MARKER (12 o'clock Diamond Pointer) ---
    final pointerTop = Offset(center.dx, center.dy - woodRimRadius + 2);
    final pointerPath = Path()
      ..moveTo(pointerTop.dx, pointerTop.dy + 16) // Bottom tip pointing down
      ..lineTo(pointerTop.dx - 9, pointerTop.dy)
      ..lineTo(pointerTop.dx, pointerTop.dy - 6)
      ..lineTo(pointerTop.dx + 9, pointerTop.dy)
      ..close();

    final pointerPaint = Paint()
      ..shader = RadialGradient(
        colors: const [Color(0xFFFFF099), Color(0xFFFFD700), Color(0xFF996515)],
      ).createShader(pointerPath.getBounds());
    
    // Shadow for pointer
    canvas.drawPath(pointerPath.shift(const Offset(0, 2)), Paint()..color = Colors.black54);
    canvas.drawPath(pointerPath, pointerPaint);
    canvas.drawPath(pointerPath, Paint()..color = Colors.amberAccent..style = PaintingStyle.stroke..strokeWidth = 1.0);
  }

  @override
  bool shouldRepaint(covariant RouletteWheelPainter oldDelegate) =>
      oldDelegate.rotationAngle != rotationAngle ||
      oldDelegate.ballAngle != ballAngle ||
      oldDelegate.ballRadiusFactor != ballRadiusFactor ||
      oldDelegate.highlightedPocket != highlightedPocket ||
      oldDelegate.highlightPulse != highlightPulse;
}