import 'dart:math' as math;
import 'package:terna/models/bump_game/bump_models.dart';

class BumpPhysicsService {
  static const double arenaSize = 460.0;
  static const double pad = 16.0;
  static const double cornerRadius = 38.0;

  static double _hypot(double a, double b) => math.sqrt(a * a + b * b);

  /// Dynamically updates ball radius and mass based on share of total game assets pot
  static void updateBallMetrics(List<BumpPlayerBall> balls, double totalPot) {
    final effectivePot = totalPot > 0 ? totalPot : balls.fold<double>(0.0, (s, b) => s + b.betAmount);
    final potSafe = effectivePot > 0 ? effectivePot : 1.0;

    for (final b in balls) {
      if (b.isSystemBot) {
        // System bot core has fixed compact radius
        b.targetRadius = 14.0;
        b.radius = 14.0;
        b.mass = 196.0;
      } else {
        final share = (b.betAmount / potSafe).clamp(0.01, 1.0);
        // Responsive size: min 16px, max 38px based on odds
        final r = (16.0 + math.sqrt(share) * 22.0).clamp(16.0, 38.0);
        b.targetRadius = r;
        if (b.radius == 20.0 && b.vx == 0 && b.vy == 0) {
          b.radius = r;
        } else {
          // Smoothly interpolate radius to target
          b.radius += (b.targetRadius - b.radius) * 0.15;
        }
        b.mass = b.radius * b.radius;
      }
    }
  }

  /// Positions participants evenly along arena perimeter during Waiting / Countdown
  static void arrangePerimeterBalls(List<BumpPlayerBall> balls) {
    const W = arenaSize;
    const H = arenaSize;
    const perimeterPad = 48.0;
    const innerW = W - perimeterPad * 2;
    const innerH = H - perimeterPad * 2;
    const totalPerim = (innerW + innerH) * 2;

    final count = balls.length;
    if (count == 0) return;

    if (count == 1) {
      final b = balls[0];
      b.x = W / 2;
      b.y = perimeterPad + 10;
      b.vx = 0;
      b.vy = 0;
      b.state = BallState.alive;
      return;
    }

    for (int i = 0; i < count; i++) {
      final b = balls[i];
      if (b.isSystemBot && count > 1) {
        // System bot placed near top center
        b.x = W / 2;
        b.y = perimeterPad - 8;
        b.vx = 0;
        b.vy = 0;
        b.state = BallState.alive;
        continue;
      }

      final distAlong = ((i + 0.5) / count) * totalPerim;
      if (distAlong < innerW) {
        // Top edge
        b.x = perimeterPad + distAlong;
        b.y = perimeterPad;
      } else if (distAlong < innerW + innerH) {
        // Right edge
        b.x = W - perimeterPad;
        b.y = perimeterPad + (distAlong - innerW);
      } else if (distAlong < innerW * 2 + innerH) {
        // Bottom edge
        b.x = W - perimeterPad - (distAlong - (innerW + innerH));
        b.y = H - perimeterPad;
      } else {
        // Left edge
        b.x = perimeterPad;
        b.y = H - perimeterPad - (distAlong - (innerW * 2 + innerH));
      }
      b.vx = 0;
      b.vy = 0;
      b.state = BallState.alive;
      b.exitElapsedMs = 0;
      b.exitOpacity = 1.0;
      b.exitScale = 1.0;
    }
  }

  /// Launch push impulse toward center with slight angular scatter
  static void applyLaunchImpulse(List<BumpPlayerBall> balls) {
    final center = BumpVector(arenaSize / 2, arenaSize / 2);
    final random = math.Random();

    for (final b in balls) {
      if (b.state != BallState.alive) continue;
      final angleToCenter = math.atan2(center.y - b.y, center.x - b.x);
      final scatter = (random.nextDouble() - 0.5) * 0.75;
      final speed = 280.0 + random.nextDouble() * 80.0; // 280 to 360 px/s

      b.vx = math.cos(angleToCenter + scatter) * speed;
      b.vy = math.sin(angleToCenter + scatter) * speed;
      b.state = BallState.alive;
      b.exitElapsedMs = 0.0;
      b.exitOpacity = 1.0;
      b.exitScale = 1.0;
    }
  }

  /// Main physics simulation tick in Zero Gravity
  static void updatePhysicsStep({
    required double dt,
    required List<BumpPlayerBall> balls,
    required List<EdgeHazard> hazards,
    required Function(double intensity) onBallBump,
    required Function(double intensity) onWallBump,
    required Function(BumpPlayerBall ball) onEliminated,
  }) {
    const minX = pad;
    const maxX = arenaSize - pad;
    const minY = pad;
    const maxY = arenaSize - pad;

    final airDamp = math.pow(0.9985, dt * 60.0).toDouble();

    // 1. Move balls and handle exiting animations
    for (final b in balls) {
      if (b.state == BallState.exiting) {
        b.x += b.vx * dt;
        b.y += b.vy * dt;
        b.exitElapsedMs += dt * 1000.0;
        final t = (b.exitElapsedMs / 600.0).clamp(0.0, 1.0);
        b.exitScale = 1.0 - t * 0.7;
        b.exitOpacity = 1.0 - t;
        if (b.exitElapsedMs >= 600.0) {
          b.state = BallState.eliminated;
        }
        continue;
      }

      if (b.state != BallState.alive) continue;

      // Zero-gravity glide integration
      b.x += b.vx * dt;
      b.y += b.vy * dt;
      b.vx *= airDamp;
      b.vy *= airDamp;

      // Maintain minimum exciting momentum
      final spd = _hypot(b.vx, b.vy);
      if (spd < 110.0 && spd > 0.01) {
        final boost = 110.0 / spd;
        b.vx *= boost;
        b.vy *= boost;
      }
    }

    // 2. Ball-Ball Elastic Collisions (Momentum conservation with mass weighting)
    final aliveBalls = balls.where((b) => b.state == BallState.alive).toList();
    for (int i = 0; i < aliveBalls.length; i++) {
      for (int j = i + 1; j < aliveBalls.length; j++) {
        final b1 = aliveBalls[i];
        final b2 = aliveBalls[j];

        final dx = b2.x - b1.x;
        final dy = b2.y - b1.y;
        final dist = _hypot(dx, dy);
        final minDist = b1.radius + b2.radius;

        if (dist < minDist && dist > 0.001) {
          final nx = dx / dist;
          final ny = dy / dist;
          final overlap = minDist - dist;

          // Mass-weighted position displacement
          final totalMass = b1.mass + b2.mass;
          final m1Ratio = b2.mass / totalMass;
          final m2Ratio = b1.mass / totalMass;

          b1.x -= nx * overlap * m1Ratio;
          b1.y -= ny * overlap * m1Ratio;
          b2.x += nx * overlap * m2Ratio;
          b2.y += ny * overlap * m2Ratio;

          // Relative velocity along collision normal
          final rvx = b1.vx - b2.vx;
          final rvy = b1.vy - b2.vy;
          final velAlongNormal = rvx * nx + rvy * ny;

          if (velAlongNormal > 0) {
            const restitution = 0.94;
            final impulseMag = -(1.0 + restitution) * velAlongNormal / (1.0 / b1.mass + 1.0 / b2.mass);

            b1.vx += (impulseMag / b1.mass) * nx;
            b1.vy += (impulseMag / b1.mass) * ny;
            b2.vx -= (impulseMag / b2.mass) * nx;
            b2.vy -= (impulseMag / b2.mass) * ny;

            final intensity = (velAlongNormal / 420.0).clamp(0.15, 1.0);
            onBallBump(intensity);
          }
        }
      }
    }

    // 3. Wall Collisions & Open Edge Hazards
    for (final b in aliveBalls) {
      // TOP WALL
      if (b.y - b.radius < minY) {
        if (_isThroughOpenHazard(WallSide.top, b.x, hazards)) {
          b.state = BallState.exiting;
          onEliminated(b);
        } else {
          b.y = minY + b.radius;
          b.vy = b.vy.abs() * 0.92;
          onWallBump((b.vy.abs() / 320.0).clamp(0.15, 1.0));
        }
      }

      // BOTTOM WALL
      if (b.y + b.radius > maxY) {
        if (_isThroughOpenHazard(WallSide.bottom, b.x, hazards)) {
          b.state = BallState.exiting;
          onEliminated(b);
        } else {
          b.y = maxY - b.radius;
          b.vy = -b.vy.abs() * 0.92;
          onWallBump((b.vy.abs() / 320.0).clamp(0.15, 1.0));
        }
      }

      // LEFT WALL
      if (b.x - b.radius < minX) {
        if (_isThroughOpenHazard(WallSide.left, b.y, hazards)) {
          b.state = BallState.exiting;
          onEliminated(b);
        } else {
          b.x = minX + b.radius;
          b.vx = b.vx.abs() * 0.92;
          onWallBump((b.vx.abs() / 320.0).clamp(0.15, 1.0));
        }
      }

      // RIGHT WALL
      if (b.x + b.radius > maxX) {
        if (_isThroughOpenHazard(WallSide.right, b.y, hazards)) {
          b.state = BallState.exiting;
          onEliminated(b);
        } else {
          b.x = maxX - b.radius;
          b.vx = -b.vx.abs() * 0.92;
          onWallBump((b.vx.abs() / 320.0).clamp(0.15, 1.0));
        }
      }
    }
  }

  /// Determines whether the ball coordinate aligns with an OPEN edge hazard
  static bool _isThroughOpenHazard(WallSide side, double coord, List<EdgeHazard> hazards) {
    for (final h in hazards) {
      if (h.side == side && h.status == EdgeHazardStatus.open) {
        if (coord >= h.startCoord && coord <= h.endCoord) {
          return true;
        }
      }
    }
    return false;
  }
}
