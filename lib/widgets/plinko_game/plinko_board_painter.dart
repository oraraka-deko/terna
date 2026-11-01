import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/plinko_game/plinko_models.dart';

/// CustomPainter rendering the complete Arcade Plinko Pinboard,
/// including glowing pegs, shockwaves, bucket capsules, drop chute, and active balls with trails.
class PlinkoBoardPainter extends CustomPainter {
  final List<PlinkoPeg> pegs;
  final List<PlinkoBucket> buckets;
  final List<PlinkoBall> balls;

  const PlinkoBoardPainter({
    required this.pegs,
    required this.buckets,
    required this.balls,
  });

  static const double baseWidth = 380.0;
  static const double baseHeight = 470.0;

  @override
  void paint(Canvas canvas, Size size) {
    // Scale canvas to match target size while preserving 380x470 coordinate space
    final scaleX = size.width / baseWidth;
    final scaleY = size.height / baseHeight;

    canvas.save();
    canvas.scale(scaleX, scaleY);

    // 1. Arcade Glass Vignette & High-Tech Pinboard Background
    final bgPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0.0, -0.1),
        radius: 1.1,
        colors: [
          Color(0xFF151928),
          Color(0xFF0B0E18),
          Color(0xFF05070D),
        ],
        stops: [0.0, 0.65, 1.0],
      ).createShader(const Rect.fromLTWH(0, 0, baseWidth, baseHeight));
    canvas.drawRect(const Rect.fromLTWH(0, 0, baseWidth, baseHeight), bgPaint);

    // Subtle cyber grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1.0;
    for (double x = 20; x < baseWidth; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, baseHeight), gridPaint);
    }

    // Outer side bumper rails
    final bumperPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(const Rect.fromLTWH(10, 10, baseWidth - 20, baseHeight - 20), bumperPaint);

    // Angled pyramid containment guide rails
    final guideRailPaint = Paint()
      ..color = const Color(0x73CCFF00)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(152, 40), const Offset(16, baseHeight - 52), guideRailPaint);
    canvas.drawLine(const Offset(228, 40), const Offset(364, baseHeight - 52), guideRailPaint);

    // 2. Drop Chute at Top
    const chuteX = baseWidth / 2.0;
    final chutePath = Path()
      ..moveTo(chuteX - 20, 12)
      ..lineTo(chuteX + 20, 12)
      ..lineTo(chuteX + 11, 40)
      ..lineTo(chuteX - 11, 40)
      ..close();

    final chuteFill = Paint()..color = Colors.black.withValues(alpha: 0.5);
    canvas.drawPath(chutePath, chuteFill);

    final chuteStroke = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x40CCFF00), Color(0xD9CCFF00)],
      ).createShader(const Rect.fromLTWH(chuteX - 22, 10, 44, 35))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(chutePath, chuteStroke);

    // Top indicator dot
    final dotPaint = Paint()..color = const Color(0xFFCCFF00);
    canvas.drawCircle(const Offset(chuteX, 42), 3.0, dotPaint);

    // 3. Pegs with Metallic highlights & Shockwave Rings
    for (final peg in pegs) {
      final center = Offset(peg.x, peg.y);

      if (peg.hit > 0.0) {
        // Shockwave ripple ring
        final rippleRadius = peg.r + ((1.0 - peg.hit) * 10.0);
        final ripplePaint = Paint()
          ..color = Color.fromRGBO(204, 255, 0, peg.hit * 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawCircle(center, rippleRadius, ripplePaint);

        // Glowing hit pinhead
        final hitGlow = Paint()
          ..color = const Color(0xFFCCFF00)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawCircle(center, peg.r + 1.0, hitGlow);

        final hitFill = Paint()..color = const Color(0xFFCCFF00);
        canvas.drawCircle(center, peg.r, hitFill);
      } else {
        // Metallic specular pinhead
        final pinPaint = Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.2, -0.2),
            radius: 0.9,
            colors: const [
              Color(0xFFFFFFFF),
              Color(0xFFD1D5DB),
              Color(0xFF4B5563),
            ],
            stops: const [0.0, 0.4, 1.0],
          ).createShader(Rect.fromCircle(center: center, radius: peg.r));
        canvas.drawCircle(center, peg.r, pinPaint);
      }
    }

    // 4. Multiplier Bucket Capsules at Bottom
    const bucketY = baseHeight - 52.0;
    const bucketH = 38.0;

    for (final bucket in buckets) {
      final bounce = bucket.hitCount > 0 ? (sin(bucket.hitCount * pi) * 4.0) : 0.0;
      final curY = bucketY - bounce;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(bucket.x + 1.5, curY, bucket.w - 3.0, bucketH),
        const Radius.circular(7.0),
      );

      if (bucket.hitCount > 0.0) {
        final glowPaint = Paint()
          ..color = bucket.glowColor
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
        canvas.drawRRect(rect, glowPaint);
      }

      // Capsule gradient fill
      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bucket.color, const Color(0xFF0E111D)],
        ).createShader(Rect.fromLTWH(bucket.x, curY, bucket.w, bucketH));
      canvas.drawRRect(rect, fillPaint);

      // Border outline
      final borderPaint = Paint()
        ..color = bucket.hitCount > 0.0 ? Colors.white : bucket.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = bucket.hitCount > 0.0 ? 2.0 : 1.2;
      canvas.drawRRect(rect, borderPaint);

      // Multiplier Text
      final textSpan = TextSpan(
        text: bucket.multiplier >= 100
            ? bucket.multiplier.toStringAsFixed(0)
            : '${bucket.multiplier}×',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10.0,
          fontWeight: FontWeight.bold,
          fontFamily: 'sans-serif',
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: bucket.w);

      textPainter.paint(
        canvas,
        Offset(
          bucket.x + (bucket.w - textPainter.width) / 2.0,
          curY + (bucketH - textPainter.height) / 2.0,
        ),
      );
    }

    // 5. Active Balls with Trails
    for (final ball in balls) {
      if (ball.settled) continue;

      // Draw energetic trail
      for (final t in ball.trail) {
        final trailPaint = Paint()
          ..color = Color.fromRGBO(204, 255, 0, (t.alpha * 0.35).clamp(0.0, 1.0));
        canvas.drawCircle(Offset(t.x, t.y), ball.r * 0.7, trailPaint);
      }

      final ballCenter = Offset(ball.x, ball.y);

      // Glow blur
      final glowPaint = Paint()
        ..color = const Color(0x99CCFF00)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(ballCenter, ball.r + 2.0, glowPaint);

      // 3D Glowing sphere ball gradient
      final ballPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.3),
          radius: 0.9,
          colors: const [
            Color(0xFFFFFFFF),
            Color(0xFFCCFF00),
            Color(0xFF84CC16),
          ],
          stops: const [0.0, 0.35, 1.0],
        ).createShader(Rect.fromCircle(center: ballCenter, radius: ball.r));

      canvas.drawCircle(ballCenter, ball.r, ballPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PlinkoBoardPainter oldDelegate) => true;
}

