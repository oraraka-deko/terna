import 'dart:convert';
import 'dart:math' as math;
import 'package:crypto/crypto.dart';
import 'package:terna/models/territory_game/territory_models.dart';
import 'package:terna/services/territory_game/territory_slicing_service.dart';

class TerritoryPhysicsService {
  static double _hypot(double a, double b) => math.sqrt(a * a + b * b);

  static String deriveRoundSeed(String serverSeed, int roundId) {
    return Hmac(sha256, utf8.encode(serverSeed))
        .convert(utf8.encode('territory_round_$roundId'))
        .toString();
  }

  /// Pure 2D Air Hockey Native Physics Engine
  static AirHockeyTrajectory simulateAirHockeyFlight({
    required String seed,
    required List<WatertightPolygon> territories,
    double W = 460.0,
    double H = 460.0,
    double durationMs = 15500.0,
    PhysicsConfig config = const PhysicsConfig(),
  }) {
    if (territories.isEmpty) {
      throw ArgumentError.value(territories, 'territories', 'At least one territory is required.');
    }

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
    const subTickRate = 60;
    const dt = 1.0 / subTickRate;
    final stopThreshold = math.max(1.5, math.min(10.0, config.minVelocityStopThreshold));

    final seedBytes = sha256.convert(utf8.encode(seed.toString())).bytes;
    var randomState = 0;
    for (var i = 0; i < 4; i++) {
      randomState = (randomState << 8) | seedBytes[i];
    }
    randomState &= 0xffffffff;
    if (randomState == 0) randomState = 0x6d2b79f5;

    int nextUint32() {
      var value = randomState;
      value ^= (value << 13) & 0xffffffff;
      value ^= value >> 17;
      value ^= (value << 5) & 0xffffffff;
      randomState = value & 0xffffffff;
      return randomState;
    }

    double rnd() {
      return nextUint32() / 0x100000000;
    }

    final maxSteps = ((durationMs / 1000.0) / dt).floor();
    final impulseMin = math.min(config.initialImpulseMin, config.initialImpulseMax);
    final impulseSpan = math.max(50.0, (config.initialImpulseMax - config.initialImpulseMin).abs());
    final startAngle = rnd() * math.pi * 2;
    final initialSpeed = impulseMin + rnd() * impulseSpan;
    final dampingFactor = 0.993 + rnd() * 0.003;
    final surfaceMu = 4.0 + rnd() * 3.0;
    double quantize(double value) => (value * 100).round() / 100.0;

    final corners = [
      (cx: cornerR, cy: cornerR),
      (cx: W - cornerR, cy: cornerR),
      (cx: W - cornerR, cy: H - cornerR),
      (cx: cornerR, cy: H - cornerR),
    ];

    var x = quantize(W / 2);
    var y = quantize(H / 2);
    var vx = quantize(math.cos(startAngle) * initialSpeed);
    var vy = quantize(math.sin(startAngle) * initialSpeed);
    final points = <PhysicsPoint>[
      PhysicsPoint(x: x, y: y, vx: vx, vy: vy, timeMs: 0),
    ];
    final wallHitEvents = <WallHitEvent>[];
    var wallHitsCount = 0;
    var stopTime = durationMs;
    var lastBounceTime = -100.0;

    for (var step = 1; step <= maxSteps; step++) {
      final time = step * 1000.0 / subTickRate;

      vx = quantize(vx * dampingFactor);
      vy = quantize(vy * dampingFactor + gravity * dt * 30.0);

      final currentSpeed = _hypot(vx, vy);
      if (currentSpeed > 0) {
        final coulombDecel = surfaceMu * dt;
        final newSpeed = math.max(0.0, currentSpeed - coulombDecel);
        final factor = newSpeed / currentSpeed;
        vx = quantize(vx * factor);
        vy = quantize(vy * factor);
      }

      x = quantize(x + vx * dt);
      y = quantize(y + vy * dt);

      var isHit = false;
      var hitIntensity = 0.0;

      if (x < minX) {
        final penetration = minX - x;
        x = quantize(minX + penetration * restitution);
        vx = quantize(-vx * restitution);
        isHit = true;
        hitIntensity = math.min(1.0, vx.abs() / 360.0);
      } else if (x > maxX) {
        final penetration = x - maxX;
        x = quantize(maxX - penetration * restitution);
        vx = quantize(-vx * restitution);
        isHit = true;
        hitIntensity = math.min(1.0, vx.abs() / 360.0);
      }

      if (y < minY) {
        final penetration = minY - y;
        y = quantize(minY + penetration * restitution);
        vy = quantize(-vy * restitution);
        isHit = true;
        hitIntensity = math.min(1.0, vy.abs() / 360.0);
      } else if (y > maxY) {
        final penetration = y - maxY;
        y = quantize(maxY - penetration * restitution);
        vy = quantize(-vy * restitution);
        isHit = true;
        hitIntensity = math.min(1.0, vy.abs() / 360.0);
      }

      for (final corner in corners) {
        final inQuadX = corner.cx == cornerR ? x < corner.cx : x > corner.cx;
        final inQuadY = corner.cy == cornerR ? y < corner.cy : y > corner.cy;
        if (inQuadX && inQuadY) {
          final dx = x - corner.cx;
          final dy = y - corner.cy;
          final distance = _hypot(dx, dy);
          if (distance > cornerLimit && distance > 0.001) {
            final nx = dx / distance;
            final ny = dy / distance;
            final over = distance - cornerLimit;
            x = quantize(corner.cx + nx * (cornerLimit - over * 0.2));
            y = quantize(corner.cy + ny * (cornerLimit - over * 0.2));
            final dot = vx * nx + vy * ny;
            if (dot > 0) {
              vx = quantize((vx - 2 * dot * nx) * restitution);
              vy = quantize((vy - 2 * dot * ny) * restitution);
              isHit = true;
              hitIntensity = math.min(1.0, _hypot(vx, vy) / 360.0);
            }
          }
        }
      }

      if (isHit) {
        wallHitsCount++;
        if (time - lastBounceTime > 60.0) {
          lastBounceTime = time;
          wallHitEvents.add(WallHitEvent(
            timeMs: time.roundToDouble(),
            progress: time / durationMs,
            x: x,
            y: y,
            intensity: math.max(0.35, hitIntensity),
          ));
        }
      }

      final isStopped = _hypot(vx, vy) <= stopThreshold && step > 80;
      points.add(PhysicsPoint(
        x: x,
        y: y,
        vx: vx,
        vy: vy,
        isWallHit: isHit,
        wallIntensity: hitIntensity,
        timeMs: time,
        isStopped: isStopped,
      ));

      if (isStopped) {
        stopTime = time;
        for (var remainingStep = step + 1; remainingStep <= maxSteps; remainingStep++) {
          points.add(PhysicsPoint(
            x: x,
            y: y,
            vx: 0,
            vy: 0,
            timeMs: remainingStep * 1000.0 / subTickRate,
            isStopped: true,
          ));
        }
        break;
      }
    }

    final finalPt = points.last;
    final landedTerritory = TerritorySlicingService.findPlayerAtPoint(
      finalPt.x,
      finalPt.y,
      territories,
    );
    if (landedTerritory == null) {
      throw StateError('The simulated puck stopped outside all territories.');
    }

    return AirHockeyTrajectory(
      points: points,
      wallHits: wallHitEvents,
      finalX: finalPt.x,
      finalY: finalPt.y,
      winnerPlayerId: landedTerritory.playerId,
      totalDurationMs: durationMs,
      wallHitsCount: wallHitsCount,
      launchAngle: startAngle,
      initialSpeed: initialSpeed,
      stopTimeMs: stopTime,
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
