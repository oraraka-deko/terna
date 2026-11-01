import 'package:flutter/material.dart';

/// 2D Vector for physics simulation
class BumpVector {
  double x;
  double y;

  BumpVector(this.x, this.y);

  BumpVector copy() => BumpVector(x, y);

  double get lengthSquared => x * x + y * y;
  double get length => x == 0 && y == 0 ? 0 : (x * x + y * y > 0 ? (x * x + y * y) : 0);

  Map<String, dynamic> toJson() => {'x': x, 'y': y};
  factory BumpVector.fromJson(Map<String, dynamic> json) => BumpVector(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
      );
}

/// Ball status in arena
enum BallState {
  alive,
  exiting,
  eliminated,
}

/// A player ball in Arena Bump
class BumpPlayerBall {
  final String id;
  final String username;
  final String? firstName;
  final String avatar;
  final Color color;
  final bool isUser;
  final bool isSystemBot;
  double betAmount;
  final String currency; // 'ton' or 'stars'
  final bool isPlaceholder;

  // Dynamic physics variables
  double x;
  double y;
  double vx;
  double vy;
  double radius;
  double targetRadius;
  double mass;
  BallState state;
  double exitOpacity;
  double exitScale;
  double exitElapsedMs;

  BumpPlayerBall({
    required this.id,
    required this.username,
    this.firstName,
    required this.avatar,
    required this.color,
    this.isUser = false,
    this.isSystemBot = false,
    required this.betAmount,
    required this.currency,
    this.x = 230.0,
    this.y = 230.0,
    this.vx = 0.0,
    this.vy = 0.0,
    this.radius = 20.0,
    this.targetRadius = 20.0,
    this.mass = 400.0,
    this.state = BallState.alive,
    this.exitOpacity = 1.0,
    this.exitScale = 1.0,
    this.exitElapsedMs = 0.0,
    // PLACEHOLDER: simulated player flag
    this.isPlaceholder = false,
  });

  BumpPlayerBall copy() {
    return BumpPlayerBall(
      id: id,
      username: username,
      firstName: firstName,
      avatar: avatar,
      color: color,
      isUser: isUser,
      isSystemBot: isSystemBot,
      betAmount: betAmount,
      currency: currency,
      x: x,
      y: y,
      vx: vx,
      vy: vy,
      radius: radius,
      targetRadius: targetRadius,
      mass: mass,
      state: state,
      exitOpacity: exitOpacity,
      exitScale: exitScale,
      exitElapsedMs: exitElapsedMs,
      isPlaceholder: isPlaceholder,
    );
  }

  String get displayName {
    if (isSystemBot) return 'Arena Core';
    if (isUser) return '@You';
    if (username.isNotEmpty) return username.startsWith('@') ? username : '@$username';
    if (firstName != null && firstName!.isNotEmpty) return firstName!;
    return 'Player $id';
  }
}

/// Hazard edge status
enum EdgeHazardStatus {
  closed,
  warning, // blinking red warning (still solid!)
  open,    // open gap (balls can exit!)
}

/// Which perimeter wall segment
enum WallSide {
  top,
  right,
  bottom,
  left,
}

/// Dynamic edge segment hazard
class EdgeHazard {
  final WallSide side;
  final double startCoord; // e.g. x1 or y1 along the edge
  final double endCoord;   // e.g. x2 or y2 along the edge
  EdgeHazardStatus status;
  double remainingTimeMs;
  final double totalWarningTimeMs;
  final double totalOpenTimeMs;

  EdgeHazard({
    required this.side,
    required this.startCoord,
    required this.endCoord,
    this.status = EdgeHazardStatus.closed,
    this.remainingTimeMs = 0.0,
    this.totalWarningTimeMs = 2800.0,
    this.totalOpenTimeMs = 6500.0,
  });

  EdgeHazard copy() {
    return EdgeHazard(
      side: side,
      startCoord: startCoord,
      endCoord: endCoord,
      status: status,
      remainingTimeMs: remainingTimeMs,
      totalWarningTimeMs: totalWarningTimeMs,
      totalOpenTimeMs: totalOpenTimeMs,
    );
  }
}

/// Game lifecycle phase
enum BumpRoundStatus {
  waitingForPlayers, // only system bot or 1 player
  countdown,         // >= 2 players, 15s timer
  battle,            // balls push to center, fight & edge hazards open
  roundOver,         // winner determined & celebration
}

/// Single recorded frame for video replay
class BumpReplayFrame {
  final double timeMs;
  final List<({double x, double y, double radius, BallState state, double opacity})> ballStates;
  final List<({WallSide side, double start, double end, EdgeHazardStatus status})> hazards;

  const BumpReplayFrame({
    required this.timeMs,
    required this.ballStates,
    required this.hazards,
  });
}

/// Historical round record for past battle replay
class BumpRoundHistory {
  final int roundId;
  final BumpPlayerBall winner;
  final List<BumpPlayerBall> participants;
  final double totalPotTon;
  final int totalPotStars;
  final List<BumpReplayFrame> replayFrames;
  final String serverSeedHash;
  final String revealedServerSeed;
  final DateTime timestamp;
  final bool isPlaceholder;

  const BumpRoundHistory({
    required this.roundId,
    required this.winner,
    required this.participants,
    required this.totalPotTon,
    required this.totalPotStars,
    this.replayFrames = const [],
    required this.serverSeedHash,
    required this.revealedServerSeed,
    required this.timestamp,
    // PLACEHOLDER: demo history round
    this.isPlaceholder = true,
  });
}
