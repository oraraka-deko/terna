import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:terna/models/bump_game/bump_models.dart';

/// CustomPainter rendering Arena Bump arena, crown watermark, dynamic balls,
/// pulsing red warning edges, and open hazard gaps.
class BumpPainter extends CustomPainter {
  final List<BumpPlayerBall> balls;
  final List<EdgeHazard> hazards;
  final BumpRoundStatus status;
  final BumpPlayerBall? winner;
  final Map<String, ImageInfo?>? avatarImages;
  final double animationTimeMs;

  BumpPainter({
    required this.balls,
    required this.hazards,
    required this.status,
    this.winner,
    this.avatarImages,
    required this.animationTimeMs,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double W = 460.0;
    const double H = 460.0;
    const double pad = 16.0;
    const double cornerRadius = 38.0;

    final scaleX = size.width / W;
    final scaleY = size.height / H;

    canvas.save();
    canvas.scale(scaleX, scaleY);

    final arenaRRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(pad, pad, W - pad * 2, H - pad * 2),
      const Radius.circular(cornerRadius),
    );

    // 1. Dark Arena Base
    final bgPaint = Paint()
      ..color = const Color(0xFF0C0D14)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(arenaRRect, bgPaint);

    // 2. Arena Clip for internal elements
    canvas.save();
    canvas.clipRRect(arenaRRect);

    // "WAITING" text if waiting for more players
    if (status == BumpRoundStatus.waitingForPlayers) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'WAITING',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.12),
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: 4.0,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset((W - textPainter.width) / 2, (H - textPainter.height) / 2),
      );
    }

    // 3. Render Player Balls
    for (final b in balls) {
      if (b.state == BallState.eliminated) continue;
      _drawPlayerBall(canvas, b);
    }

    canvas.restore(); // Restore arena clip

    // 4. Perimeter Walls with Glowing Gradients & Dynamic Hazards
    _drawPerimeterWalls(canvas, W, H, pad, cornerRadius);

    canvas.restore(); // Scale
  }

  /// Draws perimeter walls respecting open hazard gaps and blinking red warnings
  void _drawPerimeterWalls(
    Canvas canvas,
    double W,
    double H,
    double pad,
    double cornerRadius,
  ) {
    final minX = pad;
    final maxX = W - pad;
    final minY = pad;
    final maxY = H - pad;

    final isBlinkingRed = (animationTimeMs.toInt() ~/ 200) % 2 == 0;

    // Normal border paint with purple-to-cyan gradient
    final defaultPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF8B5CF6), // Purple / Violet at top
          Color(0xFF38BDF8), // Sky blue
          Color(0xFF2DD4BF), // Cyan / Teal at bottom
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, W, H));

    final warningPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..color = isBlinkingRed ? const Color(0xFFFF0033) : const Color(0xFF880011);

    // TOP WALL (left + cornerRadius to right - cornerRadius)
    _drawWallSegment(
      canvas: canvas,
      side: WallSide.top,
      p1: Offset(minX + cornerRadius, minY),
      p2: Offset(maxX - cornerRadius, minY),
      defaultPaint: defaultPaint,
      warningPaint: warningPaint,
    );

    // RIGHT WALL
    _drawWallSegment(
      canvas: canvas,
      side: WallSide.right,
      p1: Offset(maxX, minY + cornerRadius),
      p2: Offset(maxX, maxY - cornerRadius),
      defaultPaint: defaultPaint,
      warningPaint: warningPaint,
    );

    // BOTTOM WALL
    _drawWallSegment(
      canvas: canvas,
      side: WallSide.bottom,
      p1: Offset(maxX - cornerRadius, maxY),
      p2: Offset(minX + cornerRadius, maxY),
      defaultPaint: defaultPaint,
      warningPaint: warningPaint,
    );

    // LEFT WALL
    _drawWallSegment(
      canvas: canvas,
      side: WallSide.left,
      p1: Offset(minX, maxY - cornerRadius),
      p2: Offset(minX, minY + cornerRadius),
      defaultPaint: defaultPaint,
      warningPaint: warningPaint,
    );

    // 4 Chamfered / Rounded Corners
    _drawCornerArc(canvas, minX, minY, cornerRadius, math.pi, math.pi / 2, defaultPaint);
    _drawCornerArc(canvas, maxX - cornerRadius * 2, minY, cornerRadius, -math.pi / 2, math.pi / 2, defaultPaint);
    _drawCornerArc(canvas, maxX - cornerRadius * 2, maxY - cornerRadius * 2, cornerRadius, 0, math.pi / 2, defaultPaint);
    _drawCornerArc(canvas, minX, maxY - cornerRadius * 2, cornerRadius, math.pi / 2, math.pi / 2, defaultPaint);
  }

  void _drawWallSegment({
    required Canvas canvas,
    required WallSide side,
    required Offset p1,
    required Offset p2,
    required Paint defaultPaint,
    required Paint warningPaint,
  }) {
    final hazard = hazards.where((h) => h.side == side).firstOrNull;

    if (hazard == null || hazard.status == EdgeHazardStatus.closed) {
      canvas.drawLine(p1, p2, defaultPaint);
      return;
    }

    final isHorizontal = side == WallSide.top || side == WallSide.bottom;
    final start = hazard.startCoord;
    final end = hazard.endCoord;

    if (hazard.status == EdgeHazardStatus.warning) {
      // Still a solid wall! Draw default base and overlay bright blinking red on warning segment
      canvas.drawLine(p1, p2, defaultPaint);
      if (isHorizontal) {
        canvas.drawLine(Offset(start, p1.dy), Offset(end, p1.dy), warningPaint);
      } else {
        canvas.drawLine(Offset(p1.dx, start), Offset(p1.dx, end), warningPaint);
      }
    } else if (hazard.status == EdgeHazardStatus.open) {
      // OPEN GAP: Draw solid parts before and after the opening, omit opening!
      if (isHorizontal) {
        final leftBound = math.min(p1.dx, p2.dx);
        final rightBound = math.max(p1.dx, p2.dx);
        if (start > leftBound) {
          canvas.drawLine(Offset(leftBound, p1.dy), Offset(start, p1.dy), defaultPaint);
        }
        if (end < rightBound) {
          canvas.drawLine(Offset(end, p1.dy), Offset(rightBound, p1.dy), defaultPaint);
        }
        // Draw cyan end-cap dots at opening edges
        _drawEndCap(canvas, Offset(start, p1.dy));
        _drawEndCap(canvas, Offset(end, p1.dy));
      } else {
        final topBound = math.min(p1.dy, p2.dy);
        final botBound = math.max(p1.dy, p2.dy);
        if (start > topBound) {
          canvas.drawLine(Offset(p1.dx, topBound), Offset(p1.dx, start), defaultPaint);
        }
        if (end < botBound) {
          canvas.drawLine(Offset(p1.dx, end), Offset(p1.dx, botBound), defaultPaint);
        }
        _drawEndCap(canvas, Offset(p1.dx, start));
        _drawEndCap(canvas, Offset(p1.dx, end));
      }
    }
  }

  void _drawEndCap(Canvas canvas, Offset pt) {
    final capPaint = Paint()
      ..color = const Color(0xFF2DD4BF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pt, 3.5, capPaint);
  }

  void _drawCornerArc(
    Canvas canvas,
    double x,
    double y,
    double r,
    double startAngle,
    double sweepAngle,
    Paint paint,
  ) {
    canvas.drawArc(
      Rect.fromLTWH(x, y, r * 2, r * 2),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  /// Draws a player ball with circular avatar texture or initials and glowing ring
  void _drawPlayerBall(Canvas canvas, BumpPlayerBall b) {
    canvas.save();
    final r = b.radius * b.exitScale;
    final center = Offset(b.x, b.y);

    // 1. System Bot Player (Arena Core)
    if (b.isSystemBot) {
      final coreAura = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFF97316).withValues(alpha: 0.8 * b.exitOpacity),
            const Color(0xFFF97316).withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: r * 2.2));
      canvas.drawCircle(center, r * 2.2, coreAura);

      final corePaint = Paint()
        ..color = const Color(0xFFF97316).withValues(alpha: b.exitOpacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, r, corePaint);

      final coreBorder = Paint()
        ..color = Colors.white.withValues(alpha: 0.9 * b.exitOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(center, r, coreBorder);

      canvas.restore();
      return;
    }

    // 2. Normal Player Ball
    // Circular dark backing
    final bgPaint = Paint()
      ..color = const Color(0xFF0F121C).withValues(alpha: b.exitOpacity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, r, bgPaint);

    // Clip to circle for avatar or initials
    canvas.save();
    final clipPath = Path()..addOval(Rect.fromCircle(center: center, radius: r));
    canvas.clipPath(clipPath);

    final ImageInfo? imgInfo = avatarImages?[b.avatar];
    if (imgInfo != null && b.avatar.isNotEmpty) {
      paintImage(
        canvas: canvas,
        rect: Rect.fromCircle(center: center, radius: r),
        image: imgInfo.image,
        fit: BoxFit.cover,
        opacity: b.exitOpacity,
      );
    } else {
      // Initials on colored gradient
      final gradPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.3),
          radius: 0.9,
          colors: [
            b.color.withValues(alpha: 0.9 * b.exitOpacity),
            b.color.withValues(alpha: 0.5 * b.exitOpacity),
            const Color(0xFF090D1A).withValues(alpha: b.exitOpacity),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: r));
      canvas.drawCircle(center, r, gradPaint);

      final initials = _getInitials(b.username);
      final textPainter = TextPainter(
        text: TextSpan(
          text: initials,
          style: TextStyle(
            color: Colors.white.withValues(alpha: b.exitOpacity),
            fontSize: math.max(10.0, r * (initials.length > 1 ? 0.72 : 0.85)),
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
      );
    }
    canvas.restore();

    // Colored glowing border ring
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = b.color.withValues(alpha: b.exitOpacity)
      ..strokeWidth = math.max(2.0, r * 0.12);
    canvas.drawCircle(center, r, borderPaint);

    canvas.restore();
  }

  String _getInitials(String name) {
    final clean = name.replaceAll('@', '').trim();
    if (clean.isEmpty) return 'P';
    if (clean.length == 1) return clean.toUpperCase();
    return clean.substring(0, 2).toUpperCase();
  }

  @override
  bool shouldRepaint(covariant BumpPainter oldDelegate) {
    return true; // 60fps physics simulation
  }
}
