import 'package:flutter/material.dart';

/// 2D Point in table arena virtual coordinates (460x460 standard space)
class TerritoryPoint {
  final double x;
  final double y;

  const TerritoryPoint(this.x, this.y);

  @override
  String toString() => 'TerritoryPoint($x, $y)';

  Map<String, dynamic> toJson() => {'x': x, 'y': y};
  factory TerritoryPoint.fromJson(Map<String, dynamic> json) => TerritoryPoint(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
      );
}

/// A gift or relic staked in a territory pot
class TerritoryRelic {
  final String id;
  final String name;
  final String assetPath;
  final double valueTon;
  final bool isPlaceholder;

  const TerritoryRelic({
    required this.id,
    required this.name,
    required this.assetPath,
    required this.valueTon,
    // PLACEHOLDER: demo gift staked in territory pot
    this.isPlaceholder = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'assetPath': assetPath,
        'valueTon': valueTon,
        'isPlaceholder': isPlaceholder,
      };

  factory TerritoryRelic.fromJson(Map<String, dynamic> json) => TerritoryRelic(
        id: json['id'] as String,
        name: json['name'] as String,
        assetPath: json['assetPath'] as String,
        valueTon: (json['valueTon'] as num).toDouble(),
        isPlaceholder: json['isPlaceholder'] as bool? ?? true,
      );
}

/// A player's bet entry in the current round
class PlayerBet {
  final String playerId;
  final String username;
  final String? firstName;
  final String avatar;
  final Color color;
  final String currency; // 'ton' or 'stars'
  final double amount;
  final double totalBet; // normalized bet weight
  final double winProbability;
  final List<TerritoryRelic> relics;
  final bool isPlaceholder;

  const PlayerBet({
    required this.playerId,
    required this.username,
    this.firstName,
    required this.avatar,
    required this.color,
    required this.currency,
    required this.amount,
    required this.totalBet,
    this.winProbability = 0.0,
    this.relics = const [],
    // PLACEHOLDER: indicates simulated or demo bet
    this.isPlaceholder = false,
  });

  PlayerBet copyWith({
    String? playerId,
    String? username,
    String? firstName,
    String? avatar,
    Color? color,
    String? currency,
    double? amount,
    double? totalBet,
    double? winProbability,
    List<TerritoryRelic>? relics,
    bool? isPlaceholder,
  }) {
    return PlayerBet(
      playerId: playerId ?? this.playerId,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      avatar: avatar ?? this.avatar,
      color: color ?? this.color,
      currency: currency ?? this.currency,
      amount: amount ?? this.amount,
      totalBet: totalBet ?? this.totalBet,
      winProbability: winProbability ?? this.winProbability,
      relics: relics ?? this.relics,
      isPlaceholder: isPlaceholder ?? this.isPlaceholder,
    );
  }
}

/// Watertight polygon describing a player's proportional area slice
class WatertightPolygon {
  final String playerId;
  final String username;
  final String? firstName;
  final String avatar;
  final Color color;
  final double winProbability;
  final double totalBet;
  final double x; // bounding box minX
  final double y; // bounding box minY
  final double w; // bounding box width
  final double h; // bounding box height
  final List<TerritoryPoint> points;
  final double innerX; // Pole of inaccessibility X
  final double innerY; // Pole of inaccessibility Y
  final double maxRadius; // Inaccessibility clearance

  const WatertightPolygon({
    required this.playerId,
    required this.username,
    this.firstName,
    required this.avatar,
    required this.color,
    required this.winProbability,
    required this.totalBet,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.points,
    required this.innerX,
    required this.innerY,
    required this.maxRadius,
  });
}

/// Physics point sampled along air hockey trajectory
class PhysicsPoint {
  final double x;
  final double y;
  final double vx;
  final double vy;
  final bool isWallHit;
  final double wallIntensity;
  final double timeMs;
  final bool isStopped;

  const PhysicsPoint({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    this.isWallHit = false,
    this.wallIntensity = 0.0,
    required this.timeMs,
    this.isStopped = false,
  });

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'vx': vx,
        'vy': vy,
        'isWallHit': isWallHit,
        'wallIntensity': wallIntensity,
        'timeMs': timeMs,
        'isStopped': isStopped,
      };

  factory PhysicsPoint.fromJson(Map<String, dynamic> json) => PhysicsPoint(
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        vx: (json['vx'] as num).toDouble(),
        vy: (json['vy'] as num).toDouble(),
        isWallHit: json['isWallHit'] as bool? ?? false,
        wallIntensity: (json['wallIntensity'] as num?)?.toDouble() ?? 0.0,
        timeMs: (json['timeMs'] as num).toDouble(),
        isStopped: json['isStopped'] as bool? ?? false,
      );
}

/// Wall hit event during puck rebound
class WallHitEvent {
  final double timeMs;
  final double progress;
  final double x;
  final double y;
  final double intensity;

  const WallHitEvent({
    required this.timeMs,
    required this.progress,
    required this.x,
    required this.y,
    required this.intensity,
  });

  Map<String, dynamic> toJson() => {
        'timeMs': timeMs,
        'progress': progress,
        'x': x,
        'y': y,
        'intensity': intensity,
      };

  factory WallHitEvent.fromJson(Map<String, dynamic> json) => WallHitEvent(
        timeMs: (json['timeMs'] as num).toDouble(),
        progress: (json['progress'] as num).toDouble(),
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        intensity: (json['intensity'] as num).toDouble(),
      );
}

/// Physics engine tuning parameters
class PhysicsConfig {
  final double initialImpulseMin;
  final double initialImpulseMax;
  final double frictionDragCoefficient;
  final double wallElasticityRestitution;
  final double minVelocityStopThreshold;
  final int subTickRate;
  final double gravity;
  final double ballRadius;
  final double cameraHoldMs;
  final double flightDurationMs;

  const PhysicsConfig({
    this.initialImpulseMin = 2400.0,
    this.initialImpulseMax = 3000.0,
    this.frictionDragCoefficient = 0.12,
    this.wallElasticityRestitution = 0.985,
    this.minVelocityStopThreshold = 2.2,
    this.subTickRate = 120,
    this.gravity = 0.0,
    this.ballRadius = 12.0,
    this.cameraHoldMs = 1200.0,
    this.flightDurationMs = 15500.0,
  });
}

/// Simulated authoritative trajectory for puck glide & wall hits
class AirHockeyTrajectory {
  final List<PhysicsPoint> points;
  final List<WallHitEvent> wallHits;
  final double finalX;
  final double finalY;
  final String winnerPlayerId;
  final double totalDurationMs;
  final int wallHitsCount;
  final double launchAngle;
  final double initialSpeed;
  final double stopTimeMs;

  const AirHockeyTrajectory({
    required this.points,
    required this.wallHits,
    required this.finalX,
    required this.finalY,
    required this.winnerPlayerId,
    required this.totalDurationMs,
    required this.wallHitsCount,
    required this.launchAngle,
    required this.initialSpeed,
    required this.stopTimeMs,
  });
}

/// NPC user profile loaded from CSV dataset
class NpcProfile {
  final String userId;
  final String username;
  final String firstName;
  final String lastName;
  final String avatarAssetPath;

  const NpcProfile({
    required this.userId,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.avatarAssetPath,
  });

  String get displayName {
    if (username.isNotEmpty) return '@$username';
    if (firstName.isNotEmpty) return firstName;
    return 'Player $userId';
  }
}

/// Winner info summary
class RoundWinner {
  final String playerId;
  final String username;
  final String? firstName;
  final String avatar;
  final Color color;
  final double payoutTon;
  final int payoutStars;
  final double winnerPercentage;

  const RoundWinner({
    required this.playerId,
    required this.username,
    this.firstName,
    required this.avatar,
    required this.color,
    required this.payoutTon,
    required this.payoutStars,
    required this.winnerPercentage,
  });
}

/// Round execution status
enum RoundStatus {
  waitingForPlayers,
  bettingOpen,
  roundResolving,
  winnerCelebration,
}

/// History record for past round video replay & provably fair verification
class RoundHistoryRecord {
  final int roundId;
  final RoundWinner winner;
  final List<PlayerBet> players;
  final double totalPotTon;
  final int totalPotStars;
  final AirHockeyTrajectory? trajectory;
  final String serverSeedHash;
  final String revealedServerSeed;
  final DateTime timestamp;
  final bool isPlaceholder;

  const RoundHistoryRecord({
    required this.roundId,
    required this.winner,
    required this.players,
    required this.totalPotTon,
    required this.totalPotStars,
    this.trajectory,
    required this.serverSeedHash,
    required this.revealedServerSeed,
    required this.timestamp,
    // PLACEHOLDER: demo history round
    this.isPlaceholder = true,
  });
}

/// Complete current round state
class CurrentRoundState {
  final int roundId;
  final RoundStatus status;
  final List<PlayerBet> bets;
  final double totalPotTon;
  final int totalPotStars;
  final int timeRemainingMs;
  final String serverSeedHash;
  final String? revealedServerSeed;
  final String? winningPlayerId;
  final RoundWinner? winner;
  final AirHockeyTrajectory? trajectory;
  final String poolTier; // 'STANDARD' | 'HIGH_ROLLER'
  final bool isBettingClosed;

  const CurrentRoundState({
    required this.roundId,
    required this.status,
    required this.bets,
    required this.totalPotTon,
    required this.totalPotStars,
    required this.timeRemainingMs,
    required this.serverSeedHash,
    this.revealedServerSeed,
    this.winningPlayerId,
    this.winner,
    this.trajectory,
    this.poolTier = 'STANDARD',
    this.isBettingClosed = false,
  });

  CurrentRoundState copyWith({
    int? roundId,
    RoundStatus? status,
    List<PlayerBet>? bets,
    double? totalPotTon,
    int? totalPotStars,
    int? timeRemainingMs,
    String? serverSeedHash,
    String? revealedServerSeed,
    String? winningPlayerId,
    RoundWinner? winner,
    AirHockeyTrajectory? trajectory,
    String? poolTier,
    bool? isBettingClosed,
  }) {
    return CurrentRoundState(
      roundId: roundId ?? this.roundId,
      status: status ?? this.status,
      bets: bets ?? this.bets,
      totalPotTon: totalPotTon ?? this.totalPotTon,
      totalPotStars: totalPotStars ?? this.totalPotStars,
      timeRemainingMs: timeRemainingMs ?? this.timeRemainingMs,
      serverSeedHash: serverSeedHash ?? this.serverSeedHash,
      revealedServerSeed: revealedServerSeed ?? this.revealedServerSeed,
      winningPlayerId: winningPlayerId ?? this.winningPlayerId,
      winner: winner ?? this.winner,
      trajectory: trajectory ?? this.trajectory,
      poolTier: poolTier ?? this.poolTier,
      isBettingClosed: isBettingClosed ?? this.isBettingClosed,
    );
  }
}

