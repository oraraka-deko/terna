import 'dart:math';
import 'package:flutter/material.dart';

/// CustomPainter rendering the interactive Upgrade Wheel dial:
/// - Base dial disc
/// - Rotated sector overlay with glowing gold yellow gradient & boundary lines
/// - 60 perimeter radial ticks with dynamic contrast
/// - Inner track border
/// - Stationary 12 o'clock downward pointer
class WheelDialPainter extends CustomPainter {
  final double rotationDeg;
  final double winChancePercent;

  const WheelDialPainter({
    required this.rotationDeg,
    required this.winChancePercent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = min(cx, cy);

    final rOuter = radius * 0.92;
    final rInner = radius * 0.63;
    final center = Offset(cx, cy);

    // 1. Base Dial Disc Background
    final basePaint = Paint()
      ..color = const Color(0xFF12151E)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, rOuter, basePaint);

    final baseBorderPaint = Paint()
      ..color = const Color(0xFF1B1F2E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, rOuter, baseBorderPaint);

    // 2. Rotated Group (Dial Ticks and Winning Sector Overlay)
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate((rotationDeg * pi) / 180.0);

    final winAngleRad = (winChancePercent / 100.0) * (2 * pi);

    if (winChancePercent > 0.05) {
      // Golden yellow winning sector arc path
      final sectorPath = Path();
      const startAngle = -pi / 2; // 12 o'clock relative to rotating canvas

      sectorPath.arcTo(
        Rect.fromCircle(center: Offset.zero, radius: rOuter),
        startAngle,
        winAngleRad,
        false,
      );
      sectorPath.arcTo(
        Rect.fromCircle(center: Offset.zero, radius: rInner),
        startAngle + winAngleRad,
        -winAngleRad,
        false,
      );
      sectorPath.close();

      // Yellow glow shadow
      final glowPaint = Paint()
        ..color = const Color(0x66FACC15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
        ..style = PaintingStyle.fill;
      canvas.drawPath(sectorPath, glowPaint);

      // Gold yellow gradient fill
      final fillPaint = Paint()
        ..shader = const SweepGradient(
          startAngle: startAngle,
          endAngle: startAngle + (2 * pi),
          colors: [
            Color(0xFFFEF08A),
            Color(0xFFFACC15),
            Color(0xFFEAB308),
            Color(0xFFFEF08A),
          ],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: rOuter))
        ..style = PaintingStyle.fill;
      canvas.drawPath(sectorPath, fillPaint);

      // Sector border outline
      final sectorOutlinePaint = Paint()
        ..color = const Color(0xFFFDE047)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawPath(sectorPath, sectorOutlinePaint);

      // Radiating white edge line at 0 deg (12 o'clock)
      final edgeLinePaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(0, -rInner),
        Offset(0, -rOuter),
        edgeLinePaint,
      );

      // Radiating boundary line at win threshold
      if (winChancePercent < 99.8) {
        final boundaryAngle = startAngle + winAngleRad;
        canvas.drawLine(
          Offset(rInner * cos(boundaryAngle), rInner * sin(boundaryAngle)),
          Offset(rOuter * cos(boundaryAngle), rOuter * sin(boundaryAngle)),
          edgeLinePaint,
        );
      }
    }

    // 3. 60 Radial Dial Ticks around the perimeter
    for (var i = 0; i < 60; i++) {
      final tickAngleDeg = i * 6.0; // 360 / 60 = 6 deg
      final isMajor = i % 5 == 0;
      final tickLength = isMajor ? (radius * 0.10) : (radius * 0.055);
      final rStart = rOuter - tickLength;
      final rEnd = rOuter - 2.0;

      final tickAngleRad = (tickAngleDeg * pi / 180.0) - (pi / 2);
      final isInsideYellow = winChancePercent > 0 && tickAngleDeg < (winChancePercent * 3.6);

      final tickPaint = Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = isMajor ? 2.2 : 1.2
        ..color = isInsideYellow
            ? (isMajor ? const Color(0xFF11141E) : const Color(0x9911141E))
            : (isMajor ? Colors.white : Colors.white38);

      final p1 = Offset(rStart * cos(tickAngleRad), rStart * sin(tickAngleRad));
      final p2 = Offset(rEnd * cos(tickAngleRad), rEnd * sin(tickAngleRad));
      canvas.drawLine(p1, p2, tickPaint);
    }

    // 4. Inner Circular Track Border
    final innerTrackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset.zero, rInner, innerTrackPaint);

    canvas.restore();

    // 5. Stationary 12 o'clock Downward Triangle Pointer
    final pointerTop = cy - rOuter - 6.0;
    final pointerBottom = cy - rOuter + 14.0;
    final pointerPath = Path()
      ..moveTo(cx - 9, pointerTop)
      ..lineTo(cx + 9, pointerTop)
      ..lineTo(cx, pointerBottom)
      ..close();

    // Shadow
    canvas.drawShadow(pointerPath, Colors.black, 4.0, true);

    // White fill
    final pointerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawPath(pointerPath, pointerPaint);

    // Dark stroke
    final pointerStroke = Paint()
      ..color = const Color(0xFF0E111A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(pointerPath, pointerStroke);
  }

  @override
  bool shouldRepaint(covariant WheelDialPainter oldDelegate) {
    return oldDelegate.rotationDeg != rotationDeg ||
        oldDelegate.winChancePercent != winChancePercent;
  }
}

