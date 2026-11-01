import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:terna/models/territory_game/territory_models.dart';

/// CustomPainter rendering 460x460 virtual arena with watertight polygons,
/// ribbon trail, aiming chevron, glowing air hockey puck and camera zoom.
class TerritoryPainter extends CustomPainter {
  final List<WatertightPolygon> territories;
  final double puckX;
  final double puckY;
  final bool puckActive;
  final bool isPuckStopped;
  final List<TerritoryPoint> puckTrail;
  final bool isAiming;
  final double currentAimAngle;
  final double aimOpacity;
  final double cameraZoom;
  final double cameraPanX;
  final double cameraPanY;
  final String? winnerPlayerId;
  final bool isCelebrating;
  final Map<String, ImageInfo?>? avatarImages;

  TerritoryPainter({
    required this.territories,
    required this.puckX,
    required this.puckY,
    required this.puckActive,
    required this.isPuckStopped,
    required this.puckTrail,
    required this.isAiming,
    required this.currentAimAngle,
    required this.aimOpacity,
    required this.cameraZoom,
    required this.cameraPanX,
    required this.cameraPanY,
    this.winnerPlayerId,
    this.isCelebrating = false,
    this.avatarImages,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double W = 460.0;
    const double H = 460.0;
    const double cornerRadius = 38.0;

    // Scale canvas from virtual 460x460 space to actual widget display size
    final scaleX = size.width / W;
    final scaleY = size.height / H;

    canvas.save();
    canvas.scale(scaleX, scaleY);

    final arenaRRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, W, H),
      const Radius.circular(cornerRadius),
    );

    // Arena boundary clip
    canvas.save();
    canvas.clipRRect(arenaRRect);

    // Apply Camera Zoom & Pan Transform
    canvas.save();
    canvas.translate(W / 2, H / 2);
    canvas.scale(cameraZoom, cameraZoom);
    canvas.translate(-cameraPanX, -cameraPanY);

    // 1. Draw Territory Polygons
    final paintFill = Paint()..style = PaintingStyle.fill;
    for (final poly in territories) {
      final path = Path();
      if (poly.points.length >= 3) {
        path.moveTo(poly.points[0].x, poly.points[0].y);
        for (int i = 1; i < poly.points.length; i++) {
          path.lineTo(poly.points[i].x, poly.points[i].y);
        }
        path.close();
      } else {
        path.addRect(Rect.fromLTWH(poly.x, poly.y, poly.w, poly.h));
      }

      paintFill.color = poly.color;
      canvas.drawPath(path, paintFill);

      // Winner celebration pulse
      if (poly.playerId == winnerPlayerId && isCelebrating) {
        final pulsePaint = Paint()
          ..style = PaintingStyle.fill
          ..color = Colors.white.withValues(alpha: 0.25);
        canvas.drawPath(path, pulsePaint);
      }
    }

    // 2. Micro-dots pattern texture
    final dotPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    for (double dx = 10; dx < W; dx += 20) {
      for (double dy = 10; dy < H; dy += 20) {
        canvas.drawCircle(Offset(dx, dy), 1.2, dotPaint);
      }
    }

    // 3. Seam Divider Lines (Crisp white strokes)
    final seamPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withValues(alpha: 0.25)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final poly in territories) {
      if (poly.points.length >= 3) {
        final path = Path();
        path.moveTo(poly.points[0].x, poly.points[0].y);
        for (int i = 1; i < poly.points.length; i++) {
          path.lineTo(poly.points[i].x, poly.points[i].y);
        }
        path.close();
        canvas.drawPath(path, seamPaint);
      }
    }

    // 4. Territory Avatar Badges at Pole of Inaccessibility
    for (final poly in territories) {
      if (poly.playerId == 'neutral') continue;
      _drawAvatarBadge(canvas, poly);
    }

    // 5. Ribbon Trail
    if (puckActive && !isAiming && puckTrail.length >= 2) {
      _drawRibbonTrail(canvas, puckTrail);
    }

    // 6. Air Hockey Puck
    final double displayPuckX = (puckActive || isCelebrating) ? puckX : W / 2;
    final double displayPuckY = (puckActive || isCelebrating) ? puckY : H / 2;
    _drawAirHockeyPuck(canvas, displayPuckX, displayPuckY, 12.0);

    // 7. Aiming Chevron Arrow
    if (isAiming) {
      _drawAimingChevron(canvas, displayPuckX, displayPuckY, currentAimAngle, aimOpacity);
    }

    canvas.restore(); // Restore camera transform
    canvas.restore(); // Restore arena clip

    // 8. Outer Bumper Rail Frame
    final bumperPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withValues(alpha: 0.16)
      ..strokeWidth = 5.0;
    final bumperRRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(2.5, 2.5, W - 5, H - 5),
      const Radius.circular(cornerRadius),
    );
    canvas.drawRRect(bumperRRect, bumperPaint);

    canvas.restore(); // Scale
  }

  void _drawAvatarBadge(Canvas canvas, WatertightPolygon poly) {
    final maxR = math.min(46.0, poly.maxRadius * 0.82);
    final r = math.max(20.0, math.min(maxR, 22.0 + math.sqrt(poly.winProbability) * 34.0));

    // Dark backing
    final bgPaint = Paint()
      ..color = const Color(0xBF0A0C12)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(poly.innerX, poly.innerY), r + 2.0, bgPaint);

    // Clip to circle for avatar or initials
    canvas.save();
    final badgeClip = Path()
      ..addOval(Rect.fromCircle(center: Offset(poly.innerX, poly.innerY), radius: r));
    canvas.clipPath(badgeClip);

    // Render initials or profile image
    final ImageInfo? imgInfo = avatarImages?[poly.avatar];
    if (imgInfo != null) {
      final img = imgInfo.image;
      paintImage(
        canvas: canvas,
        rect: Rect.fromCircle(center: Offset(poly.innerX, poly.innerY), radius: r),
        image: img,
        fit: BoxFit.cover,
      );
    } else {
      // Initials on gradient
      final gradPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.3),
          radius: 0.9,
          colors: [
            poly.color.withValues(alpha: 0.9),
            poly.color.withValues(alpha: 0.6),
            const Color(0xFF0F172A),
          ],
        ).createShader(Rect.fromCircle(center: Offset(poly.innerX, poly.innerY), radius: r));
      canvas.drawCircle(Offset(poly.innerX, poly.innerY), r, gradPaint);

      final initials = _getInitials(poly.username);
      final textPainter = TextPainter(
        text: TextSpan(
          text: initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: math.max(12.0, r * (initials.length > 1 ? 0.72 : 0.85)),
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(poly.innerX - textPainter.width / 2, poly.innerY - textPainter.height / 2),
      );
    }
    canvas.restore();

    // Crisp white border ring
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withValues(alpha: 0.95)
      ..strokeWidth = 2.5;
    canvas.drawCircle(Offset(poly.innerX, poly.innerY), r, borderPaint);
  }

  void _drawAirHockeyPuck(Canvas canvas, double x, double y, double radius) {
    final auraR = radius * 2.66;

    // Multi-stop white bloom aura
    final auraPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.95),
          Colors.white.withValues(alpha: 0.65),
          Colors.white.withValues(alpha: 0.25),
          Colors.white.withValues(alpha: 0.08),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.25, 0.55, 0.85, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(x, y), radius: auraR));
    canvas.drawCircle(Offset(x, y), auraR, auraPaint);

    // Bright white core disc
    final corePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, y), radius, corePaint);

    // Subtle inner depth ring
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0x99D7E6FF)
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset(x, y), radius * 0.54, ringPaint);
  }

  void _drawRibbonTrail(Canvas canvas, List<TerritoryPoint> trail) {
    final n = trail.length;
    for (int i = 0; i < n - 1; i++) {
      final frac = (i + 1) / (n - 1);
      final alpha = (frac * 0.75).clamp(0.0, 1.0);
      final width = 2.0 + (frac * 8.0);

      final trailPaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withValues(alpha: alpha)
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(trail[i].x, trail[i].y),
        Offset(trail[i + 1].x, trail[i + 1].y),
        trailPaint,
      );
    }
  }

  void _drawAimingChevron(
    Canvas canvas,
    double x,
    double y,
    double angleRad,
    double opacity,
  ) {
    if (opacity <= 0.01) return;

    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(angleRad);

    const arrowDist = 26.0;
    const arrowWidth = 14.0;
    const arrowHeight = 12.0;

    final chevronPath = Path()
      ..moveTo(arrowDist + arrowHeight, 0)
      ..lineTo(arrowDist, -arrowWidth / 2)
      ..lineTo(arrowDist + 3, 0)
      ..lineTo(arrowDist, arrowWidth / 2)
      ..close();

    final fillPaint = Paint()
      ..color = const Color(0xFFEAB308).withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = const Color(0xFFFACC15).withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(chevronPath, fillPaint);
    canvas.drawPath(chevronPath, strokePaint);

    // Guide dot trailing back to puck
    final dotPaint = Paint()
      ..color = const Color(0x99FACC15).withValues(alpha: opacity * 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(17, 0), 1.8, dotPaint);

    canvas.restore();
  }

  String _getInitials(String name) {
    final clean = name.replaceAll('@', '').trim();
    if (clean.isEmpty) return 'P';
    if (clean.length == 1) return clean.toUpperCase();
    return clean.substring(0, 2).toUpperCase();
  }

  @override
  bool shouldRepaint(covariant TerritoryPainter oldDelegate) {
    return oldDelegate.puckX != puckX ||
        oldDelegate.puckY != puckY ||
        oldDelegate.currentAimAngle != currentAimAngle ||
        oldDelegate.cameraZoom != cameraZoom ||
        oldDelegate.territories != territories ||
        oldDelegate.puckActive != puckActive ||
        oldDelegate.isAiming != isAiming;
  }
}

