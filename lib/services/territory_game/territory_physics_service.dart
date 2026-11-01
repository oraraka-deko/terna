import 'dart:math' as math;
import 'package:terna/models/territory_game/territory_models.dart';
import 'package:terna/services/territory_game/territory_slicing_service.dart';

class TerritoryPhysicsService {
  static double _hypot(double a, double b) => math.sqrt(a * a + b * b);

  /// Pure 2D Air Hockey Native Physics Engine
  static AirHockeyTrajectory simulateAirHockeyFlight({
    required dynamic seed,
    required String winnerPlayerId,
    required List<WatertightPolygon> territories,
    double W = 460.0,
    double H = 460.0,
    double durationMs = 15500.0,
    PhysicsConfig config = const PhysicsConfig(),
  }) {
    final puckRadius = math.max(6.0, math.min(26.0, config.ballRadius));
    const bumperInset = 5.0;
    const cornerR = 38.0;
    final gravity = config.gravity;

    final minX = puckRadius + bumperInset;
    final maxX = W - puckRadius - bumperInset;
    final minY = puckRadius + bumperInset;
    final maxY = H - puckRadius - bumperInset;
    final cornerLimit = cornerR - puckRadius - bumperInset;

    final restitution = math.max(0.88, math.min(0.995, config.wallElasticityRestitution));
    final subTickRate = math.max(60, math.min(240, config.subTickRate));
    final dt = 1.0 / subTickRate;
    final stopThreshold = math.max(1.5, math.min(10.0, config.minVelocityStopThreshold));

    // Pseudorandom generator based on round seed
    int numSeed;
    if (seed is int) {
      numSeed = seed.abs();
    } else {
      numSeed = seed.toString().codeUnits.fold<int>(1, (acc, c) => (acc * 31 + c) & 0xffffff);
    }
    double pseudo = ((numSeed * 9301 + 49297) % 233280).toDouble();
    double rnd() {
      pseudo = (pseudo * 9301 + 49297) % 233280;
      return pseudo / 233280.0;
    }

    final targetPoly = territories.firstWhere(
      (t) => t.playerId == winnerPlayerId,
      orElse: () => territories.isNotEmpty ? territories.first : throw Exception('No territories'),
    );
    final maxSteps = ((durationMs / 1000.0) / dt).floor();

    final corners = [
      (cx: cornerR, cy: cornerR),
      (cx: W - cornerR, cy: cornerR),
      (cx: W - cornerR, cy: H - cornerR),
      (cx: cornerR, cy: H - cornerR),
    ];

    ({
      List<PhysicsPoint> points,
      List<WallHitEvent> wallHits,
      double finalX,
      double finalY,
      int wallHitsCount,
      double stopTime,
    }) simulateCandidate(
      double startAngle,
      double initialSpeed,
      double dampingFactor,
      double surfaceMu,
    ) {
      double x = W / 2;
      double y = H / 2;
      double vx = math.cos(startAngle) * initialSpeed;
      double vy = math.sin(startAngle) * initialSpeed;

      final List<PhysicsPoint> points = [];
      final List<WallHitEvent> wallHitEvents = [];
      points.add(PhysicsPoint(x: x, y: y, vx: vx, vy: vy, timeMs: 0));

      int wallHits = 0;
      double time = 0.0;
      double stopTime = durationMs;
      double lastBounceTime = -100.0;

      for (int step = 1; step <= maxSteps; step++) {
        time += dt * 1000.0;

        // 1. Continuous air-cushion exponential damping & optional subtle gravity
        final airDamp = math.pow(dampingFactor, dt * 60.0).toDouble();
        vx *= airDamp;
        vy = vy * airDamp + gravity * dt * 30.0;

        // 2. Subtle Coulomb table surface friction
        final currentSpeed = _hypot(vx, vy);
        if (currentSpeed > 0) {
          final coulombDecel = surfaceMu * dt;
          final newSpeed = math.max(0.0, currentSpeed - coulombDecel);
          final factor = newSpeed / currentSpeed;
          vx *= factor;
          vy *= factor;
        }

        // 3. Position integration
        x += vx * dt;
        y += vy * dt;

        bool isHit = false;
        double hitIntensity = 0.0;

        // Outer rail cushions
        if (x < minX) {
          final pen = minX - x;
          x = minX + pen * restitution;
          vx = -vx * restitution;
          isHit = true;
          hitIntensity = math.min(1.0, vx.abs() / 360.0);
        } else if (x > maxX) {
          final pen = x - maxX;
          x = maxX - pen * restitution;
          vx = -vx * restitution;
          isHit = true;
          hitIntensity = math.min(1.0, vx.abs() / 360.0);
        }

        if (y < minY) {
          final pen = minY - y;
          y = minY + pen * restitution;
          vy = -vy * restitution;
          isHit = true;
          hitIntensity = math.min(1.0, vy.abs() / 360.0);
        } else if (y > maxY) {
          final pen = y - maxY;
          y = maxY - pen * restitution;
          vy = -vy * restitution;
          isHit = true;
          hitIntensity = math.min(1.0, vy.abs() / 360.0);
        }

        // Rounded Corner reflections
        for (final c in corners) {
          final inQuadX = (c.cx == cornerR) ? (x < c.cx) : (x > c.cx);
          final inQuadY = (c.cy == cornerR) ? (y < c.cy) : (y > c.cy);
          if (inQuadX && inQuadY) {
            final dx = x - c.cx;
            final dy = y - c.cy;
            final dist = _hypot(dx, dy);
            if (dist > cornerLimit && dist > 0.001) {
              final nx = dx / dist;
              final ny = dy / dist;
              final over = dist - cornerLimit;
              x = c.cx + nx * (cornerLimit - over * 0.2);
              y = c.cy + ny * (cornerLimit - over * 0.2);
              final dot = vx * nx + vy * ny;
              if (dot > 0) {
                vx = (vx - 2 * dot * nx) * restitution;
                vy = (vy - 2 * dot * ny) * restitution;
                isHit = true;
                hitIntensity = math.min(1.0, _hypot(vx, vy) / 360.0);
              }
            }
          }
        }

        if (isHit) {
          wallHits++;
          if (time - lastBounceTime > 60.0) {
            lastBounceTime = time;
            wallHitEvents.add(WallHitEvent(
              timeMs: time.roundToDouble(),
              progress: time / durationMs,
              x: (x * 10).round() / 10.0,
              y: (y * 10).round() / 10.0,
              intensity: math.max(0.35, hitIntensity),
            ));
          }
        }

        final postSpeed = _hypot(vx, vy);
        final isStopped = postSpeed <= stopThreshold && step > 80;

        points.add(PhysicsPoint(
          x: (x * 10).round() / 10.0,
          y: (y * 10).round() / 10.0,
          vx: vx,
          vy: vy,
          isWallHit: isHit,
          wallIntensity: hitIntensity,
          timeMs: time,
          isStopped: isStopped,
        ));

        if (isStopped) {
          stopTime = time;
          while (step < maxSteps) {
            step++;
            time += dt * 1000.0;
            points.add(PhysicsPoint(
              x: (x * 10).round() / 10.0,
              y: (y * 10).round() / 10.0,
              vx: 0,
              vy: 0,
              timeMs: time,
              isStopped: true,
            ));
          }
          break;
        }
      }

      final finalPt = points.last;
      return (
        points: points,
        wallHits: wallHitEvents,
        finalX: finalPt.x,
        finalY: finalPt.y,
        wallHitsCount: wallHits,
        stopTime: stopTime,
      );
    }

    final impulseMin = math.min(config.initialImpulseMin, config.initialImpulseMax);
    final impulseSpan = math.max(50.0, (config.initialImpulseMax - config.initialImpulseMin).abs());

    List<PhysicsPoint> bestTrajectory = [];
    List<WallHitEvent> bestWallHits = [];
    double bestLaunchAngle = 0.0;
    double bestSpeed = config.initialImpulseMin;
    double bestStopTime = 0.0;
    bool foundValid = false;

    // Search Pass 1: Targeted candidate generation
    const maxAttempts = 600;
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final startAngle = rnd() * math.pi * 2;
      final initialSpeed = impulseMin + rnd() * impulseSpan;
      final dampingFactor = 0.993 + rnd() * 0.003;
      final surfaceMu = 4.0 + rnd() * 3.0;

      final res = simulateCandidate(startAngle, initialSpeed, dampingFactor, surfaceMu);
      final landedPoly = TerritorySlicingService.findPlayerAtPoint(res.finalX, res.finalY, territories);

      if (landedPoly != null &&
          landedPoly.playerId == winnerPlayerId &&
          res.wallHitsCount >= 8 &&
          res.stopTime >= 8000.0) {
        bestTrajectory = res.points;
        bestWallHits = res.wallHits;
        bestLaunchAngle = startAngle;
        bestSpeed = initialSpeed;
        bestStopTime = res.stopTime;
        foundValid = true;
        break;
      }
    }

    // Search Pass 2: Relax bounds if needed
    if (!foundValid) {
      for (int attempt = 0; attempt < 400; attempt++) {
        final startAngle = rnd() * math.pi * 2;
        final initialSpeed = impulseMin + rnd() * impulseSpan;
        const dampingFactor = 0.994;
        const surfaceMu = 5.0;

        final res = simulateCandidate(startAngle, initialSpeed, dampingFactor, surfaceMu);
        final landedPoly = TerritorySlicingService.findPlayerAtPoint(res.finalX, res.finalY, territories);

        if (landedPoly != null && landedPoly.playerId == winnerPlayerId) {
          bestTrajectory = res.points;
          bestWallHits = res.wallHits;
          bestLaunchAngle = startAngle;
          bestSpeed = initialSpeed;
          bestStopTime = res.stopTime;
          foundValid = true;
          break;
        }
      }
    }

    // Fallback: If still not found, construct direct glide to target innerX, innerY
    if (!foundValid || bestTrajectory.isEmpty) {
      final directAngle = math.atan2(targetPoly.innerY - H / 2, targetPoly.innerX - W / 2);
      final directSpeed = impulseMin * 0.7;
      final res = simulateCandidate(directAngle, directSpeed, 0.991, 6.0);
      bestTrajectory = res.points;
      bestWallHits = res.wallHits;
      bestLaunchAngle = directAngle;
      bestSpeed = directSpeed;
      bestStopTime = res.stopTime;
    }

    final finalPt = bestTrajectory.isNotEmpty ? bestTrajectory.last : PhysicsPoint(x: targetPoly.innerX, y: targetPoly.innerY, vx: 0, vy: 0, timeMs: durationMs);

    return AirHockeyTrajectory(
      points: bestTrajectory,
      wallHits: bestWallHits,
      finalX: finalPt.x,
      finalY: finalPt.y,
      winnerPlayerId: winnerPlayerId,
      totalDurationMs: durationMs,
      wallHitsCount: bestWallHits.length,
      launchAngle: bestLaunchAngle,
      initialSpeed: bestSpeed,
      stopTimeMs: bestStopTime > 0 ? bestStopTime : durationMs * 0.75,
    );
  }

  /// Hermite cubic velocity-aware interpolation for sub-frame glide
  static ({double x, double y, double vx, double vy, bool isStopped, double speed}) sampleTrajectory(
    AirHockeyTrajectory trajectory,
    double progress,
  ) {
    final pts = trajectory.points;
    if (pts.isEmpty) {
      return (x: 230.0, y: 230.0, vx: 0.0, vy: 0.0, isStopped: false, speed: 0.0);
    }

    final clamped = progress.clamp(0.0, 1.0);
    if (clamped <= 0.0) {
      final p0 = pts[0];
      return (
        x: p0.x,
        y: p0.y,
        vx: p0.vx,
        vy: p0.vy,
        isStopped: false,
        speed: _hypot(p0.vx, p0.vy),
      );
    }

    final rawIdx = clamped * (pts.length - 1);
    final idx = math.min(pts.length - 1, rawIdx.floor());
    final nextIdx = math.min(pts.length - 1, idx + 1);
    final t = rawIdx - idx;

    final p0 = pts[idx];
    final p1 = pts[nextIdx];

    if (p0.isStopped && p1.isStopped) {
      return (x: p1.x, y: p1.y, vx: 0.0, vy: 0.0, isStopped: true, speed: 0.0);
    }

    // Hermite cubic interpolation
    final t2 = t * t;
    final t3 = t2 * t;
    final h00 = 2 * t3 - 3 * t2 + 1;
    final h10 = t3 - 2 * t2 + t;
    final h01 = -2 * t3 + 3 * t2;
    final h11 = t3 - t2;

    final dt = math.max(0.001, (p1.timeMs - p0.timeMs) / 1000.0);
    final m0x = p0.vx * dt;
    final m0y = p0.vy * dt;
    final m1x = p1.vx * dt;
    final m1y = p1.vy * dt;

    final curX = h00 * p0.x + h10 * m0x + h01 * p1.x + h11 * m1x;
    final curY = h00 * p0.y + h10 * m0y + h01 * p1.y + h11 * m1y;

    final interpVx = (1 - t) * p0.vx + t * p1.vx;
    final interpVy = (1 - t) * p0.vy + t * p1.vy;

    return (
      x: curX,
      y: curY,
      vx: interpVx,
      vy: interpVy,
      isStopped: p1.isStopped && t > 0.9,
      speed: _hypot(interpVx, interpVy),
    );
  }
}
