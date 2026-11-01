import 'dart:math' as math;
import 'package:terna/models/bump_game/bump_models.dart';

class BumpPhysicsService {
  static const double arenaSize = 460.0;
  static const double pad = 16.0;
  static const double cornerRadius = 38.0;

  static double _hypot(double a, double b) => math.sqrt(a * a + b * b);

  /// Dynamically updates ball radius and mass based on relative odds / stake ratios
  /// - System bot alone starts at 35px (2.5x larger than before).
  /// - When players join, the largest stake gets the maximum radius (40px).
  /// - All other balls scale proportionally: Ri / Rmax ~ Vi / Vmax.
  /// - As larger players join, existing balls shrink proportionally to keep max size capped at 40px.
  static void updateBallMetrics(List<BumpPlayerBall> balls) {
    if (balls.isEmpty) return;

    if (balls.length == 1) {
      final single = balls.first;
      // System bot alone has large visible presence (~35px, 2.5x of previous 14px)
      single.targetRadius = 35.0;
      single.radius = 35.0;
      single.mass = 35.0 * 35.0;
      return;
    }

    // Find highest stake value across all participants
    final maxStake = balls.fold<double>(
      0.0,
      (max, b) => math.max(max, b.effectiveStars),
    );
    final safeMaxStake = maxStake > 0 ? maxStake : 1.0;

    const double minR = 16.0;
    const double maxR = 40.0;

    for (final b in balls) {
      final ratio = (b.effectiveStars / safeMaxStake).clamp(0.01, 1.0);
      // Proportional scaling: max stake gets maxR (40px), smaller stakes scale down smoothly
      final targetR = minR + (maxR - minR) * ratio;

      b.targetRadius = targetR;
      if (b.vx == 0 && b.vy == 0) {
        b.radius = targetR;
      } else {
        // Smooth transition during battle if stake changes
        b.radius += (targetR - b.radius) * 0.2;
      }
      b.mass = b.radius * b.radius;
    }
  }

  /// Positions participants safely INSIDE the arena perimeter
  /// Strictly guarantees balls never intersect or clip into the walls at start!
  static void arrangePerimeterBalls(List<BumpPlayerBall> balls) {
    const W = arenaSize;
    const H = arenaSize;

    final count = balls.length;
    if (count == 0) return;

    // Sort participants by stake descending so the biggest player gets prime placement
    balls.sort((a, b) => b.effectiveStars.compareTo(a.effectiveStars));

    if (count == 1) {
      final b = balls[0];
      b.x = W / 2;
      b.y = pad + b.radius + 24.0; // Ample clearance from top wall
      b.vx = 0;
      b.vy = 0;
      b.state = BallState.alive;
      return;
    }

    final maxR = balls.fold<double>(16.0, (m, b) => math.max(m, b.radius));
    // Safe perimeter clearance: wall pad + max ball radius + 14px margin
    final safePad = pad + maxR + 14.0;
    final innerW = W - safePad * 2;
    final innerH = H - safePad * 2;
    final totalPerim = (innerW + innerH) * 2;

    for (int i = 0; i < count; i++) {
      final b = balls[i];
      final distAlong = ((i + 0.5) / count) * totalPerim;

      if (distAlong < innerW) {
        // Top edge
        b.x = safePad + distAlong;
        b.y = safePad;
      } else if (distAlong < innerW + innerH) {
        // Right edge
        b.x = W - safePad;
        b.y = safePad + (distAlong - innerW);
      } else if (distAlong < innerW * 2 + innerH) {
        // Bottom edge
        b.x = W - safePad - (distAlong - (innerW + innerH));
        b.y = H - safePad;
      } else {
        // Left edge
        b.x = safePad;
        b.y = H - safePad - (distAlong - (innerW * 2 + innerH));
      }

      // Hard clamp within safe interior bounds
      b.x = b.x.clamp(pad + b.radius + 8.0, W - pad - b.radius - 8.0);
      b.y = b.y.clamp(pad + b.radius + 8.0, H - pad - b.radius - 8.0);

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
      final scatter = (random.nextDouble() - 0.5) * 0.65;
      final speed = 310.0 + random.nextDouble() * 90.0; // 310 to 400 px/s

      b.vx = math.cos(angleToCenter + scatter) * speed;
      b.vy = math.sin(angleToCenter + scatter) * speed;
      b.state = BallState.alive;
      b.exitElapsedMs = 0.0;
      b.exitOpacity = 1.0;
      b.exitScale = 1.0;
    }
  }

  /// Main physics simulation tick in Zero Gravity
  /// Lively elastic bounces (restitution 0.96 walls, 0.95 balls)
  /// Real-world corner lip collisions for open hazard gaps!
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

    // High lively glide: minimal friction damping
    final airDamp = math.pow(0.9992, dt * 60.0).toDouble();

    // 1. Position Integration
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

      b.x += b.vx * dt;
      b.y += b.vy * dt;
      b.vx *= airDamp;
      b.vy *= airDamp;

      // Maintain lively fighting speed
      final spd = _hypot(b.vx, b.vy);
      if (spd < 140.0 && spd > 0.01) {
        final boost = 140.0 / spd;
        b.vx *= boost;
        b.vy *= boost;
      }
    }

    // 2. Ball-Ball Elastic Collisions (High restitution 0.95, momentum transfer)
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

          // Mass-weighted overlap resolution
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
            const restitution = 0.95; // Crisp snappy bounce
            final impulseMag = -(1.0 + restitution) * velAlongNormal / (1.0 / b1.mass + 1.0 / b2.mass);

            b1.vx += (impulseMag / b1.mass) * nx;
            b1.vy += (impulseMag / b1.mass) * ny;
            b2.vx -= (impulseMag / b2.mass) * nx;
            b2.vy -= (impulseMag / b2.mass) * ny;

            final intensity = (velAlongNormal / 380.0).clamp(0.2, 1.0);
            onBallBump(intensity);
          }
        }
      }
    }

    // 3. Wall Collisions, Open Gaps & Corner Lip Bouncing
    const wallRestitution = 0.96; // Lively arena hockey-grade rail bounce

    for (final b in aliveBalls) {
      // ---------------- TOP WALL ----------------
      if (b.y - b.radius < minY) {
        final hazard = hazards.where((h) => h.side == WallSide.top && h.status == EdgeHazardStatus.open).firstOrNull;
        if (hazard != null) {
          final p1x = hazard.startCoord;
          final p2x = hazard.endCoord;

          // Check corner lip 1 collision
          final d1 = _hypot(b.x - p1x, b.y - minY);
          if (d1 < b.radius && d1 > 0.001) {
            final nx = (b.x - p1x) / d1;
            final ny = (b.y - minY) / d1;
            b.x = p1x + nx * b.radius;
            b.y = minY + ny * b.radius;
            final dot = b.vx * nx + b.vy * ny;
            if (dot < 0) {
              b.vx -= (1.0 + wallRestitution) * dot * nx;
              b.vy -= (1.0 + wallRestitution) * dot * ny;
            }
            onWallBump(0.6);
            continue;
          }

          // Check corner lip 2 collision
          final d2 = _hypot(b.x - p2x, b.y - minY);
          if (d2 < b.radius && d2 > 0.001) {
            final nx = (b.x - p2x) / d2;
            final ny = (b.y - minY) / d2;
            b.x = p2x + nx * b.radius;
            b.y = minY + ny * b.radius;
            final dot = b.vx * nx + b.vy * ny;
            if (dot < 0) {
              b.vx -= (1.0 + wallRestitution) * dot * nx;
              b.vy -= (1.0 + wallRestitution) * dot * ny;
            }
            onWallBump(0.6);
            continue;
          }

          // In the open gap
          if (b.x >= p1x + 4.0 && b.x <= p2x - 4.0) {
            b.state = BallState.exiting;
            onEliminated(b);
            continue;
          }
        }

        // Solid wall or warning edge bounce
        b.y = minY + b.radius;
        b.vy = b.vy.abs() * wallRestitution;
        onWallBump((b.vy.abs() / 300.0).clamp(0.2, 1.0));
      }

      // ---------------- BOTTOM WALL ----------------
      if (b.y + b.radius > maxY) {
        final hazard = hazards.where((h) => h.side == WallSide.bottom && h.status == EdgeHazardStatus.open).firstOrNull;
        if (hazard != null) {
          final p1x = hazard.startCoord;
          final p2x = hazard.endCoord;

          // Lip 1
          final d1 = _hypot(b.x - p1x, b.y - maxY);
          if (d1 < b.radius && d1 > 0.001) {
            final nx = (b.x - p1x) / d1;
            final ny = (b.y - maxY) / d1;
            b.x = p1x + nx * b.radius;
            b.y = maxY + ny * b.radius;
            final dot = b.vx * nx + b.vy * ny;
            if (dot < 0) {
              b.vx -= (1.0 + wallRestitution) * dot * nx;
              b.vy -= (1.0 + wallRestitution) * dot * ny;
            }
            onWallBump(0.6);
            continue;
          }

          // Lip 2
          final d2 = _hypot(b.x - p2x, b.y - maxY);
          if (d2 < b.radius && d2 > 0.001) {
            final nx = (b.x - p2x) / d2;
            final ny = (b.y - maxY) / d2;
            b.x = p2x + nx * b.radius;
            b.y = maxY + ny * b.radius;
            final dot = b.vx * nx + b.vy * ny;
            if (dot < 0) {
              b.vx -= (1.0 + wallRestitution) * dot * nx;
              b.vy -= (1.0 + wallRestitution) * dot * ny;
            }
            onWallBump(0.6);
            continue;
          }

          // In the open gap
          if (b.x >= p1x + 4.0 && b.x <= p2x - 4.0) {
            b.state = BallState.exiting;
            onEliminated(b);
            continue;
          }
        }

        b.y = maxY - b.radius;
        b.vy = -b.vy.abs() * wallRestitution;
        onWallBump((b.vy.abs() / 300.0).clamp(0.2, 1.0));
      }

      // ---------------- LEFT WALL ----------------
      if (b.x - b.radius < minX) {
        final hazard = hazards.where((h) => h.side == WallSide.left && h.status == EdgeHazardStatus.open).firstOrNull;
        if (hazard != null) {
          final p1y = hazard.startCoord;
          final p2y = hazard.endCoord;

          // Lip 1
          final d1 = _hypot(b.x - minX, b.y - p1y);
          if (d1 < b.radius && d1 > 0.001) {
            final nx = (b.x - minX) / d1;
            final ny = (b.y - p1y) / d1;
            b.x = minX + nx * b.radius;
            b.y = p1y + ny * b.radius;
            final dot = b.vx * nx + b.vy * ny;
            if (dot < 0) {
              b.vx -= (1.0 + wallRestitution) * dot * nx;
              b.vy -= (1.0 + wallRestitution) * dot * ny;
            }
            onWallBump(0.6);
            continue;
          }

          // Lip 2
          final d2 = _hypot(b.x - minX, b.y - p2y);
          if (d2 < b.radius && d2 > 0.001) {
            final nx = (b.x - minX) / d2;
            final ny = (b.y - p2y) / d2;
            b.x = minX + nx * b.radius;
            b.y = p2y + ny * b.radius;
            final dot = b.vx * nx + b.vy * ny;
            if (dot < 0) {
              b.vx -= (1.0 + wallRestitution) * dot * nx;
              b.vy -= (1.0 + wallRestitution) * dot * ny;
            }
            onWallBump(0.6);
            continue;
          }

          // In open gap
          if (b.y >= p1y + 4.0 && b.y <= p2y - 4.0) {
            b.state = BallState.exiting;
            onEliminated(b);
            continue;
          }
        }

        b.x = minX + b.radius;
        b.vx = b.vx.abs() * wallRestitution;
        onWallBump((b.vx.abs() / 300.0).clamp(0.2, 1.0));
      }

      // ---------------- RIGHT WALL ----------------
      if (b.x + b.radius > maxX) {
        final hazard = hazards.where((h) => h.side == WallSide.right && h.status == EdgeHazardStatus.open).firstOrNull;
        if (hazard != null) {
          final p1y = hazard.startCoord;
          final p2y = hazard.endCoord;

          // Lip 1
          final d1 = _hypot(b.x - maxX, b.y - p1y);
          if (d1 < b.radius && d1 > 0.001) {
            final nx = (b.x - maxX) / d1;
            final ny = (b.y - p1y) / d1;
            b.x = maxX + nx * b.radius;
            b.y = p1y + ny * b.radius;
            final dot = b.vx * nx + b.vy * ny;
            if (dot < 0) {
              b.vx -= (1.0 + wallRestitution) * dot * nx;
              b.vy -= (1.0 + wallRestitution) * dot * ny;
            }
            onWallBump(0.6);
            continue;
          }

          // Lip 2
          final d2 = _hypot(b.x - maxX, b.y - p2y);
          if (d2 < b.radius && d2 > 0.001) {
            final nx = (b.x - maxX) / d2;
            final ny = (b.y - p2y) / d2;
            b.x = maxX + nx * b.radius;
            b.y = p2y + ny * b.radius;
            final dot = b.vx * nx + b.vy * ny;
            if (dot < 0) {
              b.vx -= (1.0 + wallRestitution) * dot * nx;
              b.vy -= (1.0 + wallRestitution) * dot * ny;
            }
            onWallBump(0.6);
            continue;
          }

          // In open gap
          if (b.y >= p1y + 4.0 && b.y <= p2y - 4.0) {
            b.state = BallState.exiting;
            onEliminated(b);
            continue;
          }
        }

        b.x = maxX - b.radius;
        b.vx = -b.vx.abs() * wallRestitution;
        onWallBump((b.vx.abs() / 300.0).clamp(0.2, 1.0));
      }
    }
  }
}
