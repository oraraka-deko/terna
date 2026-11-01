import 'package:flutter/material.dart';

enum PlinkoCurrency {
  ton,
  stars,
}

enum PlinkoRisk {
  low,
  medium,
  high,
}

extension PlinkoRiskExtension on PlinkoRisk {
  String get label {
    switch (this) {
      case PlinkoRisk.low:
        return 'LOW';
      case PlinkoRisk.medium:
        return 'MEDIUM';
      case PlinkoRisk.high:
        return 'HIGH';
    }
  }

  Color get activeColor {
    switch (this) {
      case PlinkoRisk.low:
        return const Color(0xFF10B981); // Emerald
      case PlinkoRisk.medium:
        return const Color(0xFF9333EA); // Purple
      case PlinkoRisk.high:
        return const Color(0xFFE11D48); // Rose
    }
  }

  List<double> get multipliers {
    switch (this) {
      case PlinkoRisk.low:
        return const [10.0, 3.0, 1.6, 1.4, 1.1, 1.0, 0.5, 1.0, 1.1, 1.4, 1.6, 3.0, 10.0];
      case PlinkoRisk.medium:
        return const [33.0, 11.0, 4.0, 2.0, 1.1, 0.6, 0.3, 0.6, 1.1, 2.0, 4.0, 11.0, 33.0];
      case PlinkoRisk.high:
        return const [170.0, 24.0, 8.1, 2.0, 0.7, 0.2, 0.2, 0.2, 0.7, 2.0, 8.1, 24.0, 170.0];
    }
  }
}

/// Multiplier bucket color & glow style
class PlinkoBucketStyle {
  final Color bg;
  final Color glow;

  const PlinkoBucketStyle({required this.bg, required this.glow});

  static PlinkoBucketStyle fromMultiplier(double m) {
    if (m <= 0.3) {
      return const PlinkoBucketStyle(
        bg: Color(0xFF334155),
        glow: Color(0x66334155),
      );
    }
    if (m >= 40.0) {
      return const PlinkoBucketStyle(
        bg: Color(0xFFEF4444),
        glow: Color(0xCCEF4444),
      );
    }
    if (m >= 15.0) {
      return const PlinkoBucketStyle(
        bg: Color(0xFFF97316),
        glow: Color(0xBFFA7316),
      );
    }
    if (m >= 3.0) {
      return const PlinkoBucketStyle(
        bg: Color(0xFFEAB308),
        glow: Color(0xA6EAB308),
      );
    }
    if (m >= 1.0) {
      return const PlinkoBucketStyle(
        bg: Color(0xFF10B981),
        glow: Color(0xA610B981),
      );
    }
    return const PlinkoBucketStyle(
      bg: Color(0xFF64748B),
      glow: Color(0x6664748B),
    );
  }
}

class PlinkoPeg {
  final double x;
  final double y;
  final double r;
  double hit; // For shockwave & glowing highlight (1.0 down to 0.0)

  PlinkoPeg({
    required this.x,
    required this.y,
    this.r = 3.5,
    this.hit = 0.0,
  });
}

class PlinkoBucket {
  final double x;
  final double w;
  final double multiplier;
  final Color color;
  final Color glowColor;
  double hitCount; // For bounce animation (1.0 down to 0.0)

  PlinkoBucket({
    required this.x,
    required this.w,
    required this.multiplier,
    required this.color,
    required this.glowColor,
    this.hitCount = 0.0,
  });
}

class PlinkoWaypoint {
  final double x;
  final double y;
  final int? pegIdx;
  final bool isBucket;

  const PlinkoWaypoint({
    required this.x,
    required this.y,
    this.pegIdx,
    this.isBucket = false,
  });
}

class PlinkoTrailPoint {
  final double x;
  final double y;
  double alpha;

  PlinkoTrailPoint({
    required this.x,
    required this.y,
    this.alpha = 1.0,
  });
}

class PlinkoBall {
  final String id;
  double x;
  double y;
  final double r;
  final PlinkoCurrency currency;
  final double betAmount;
  final double multiplier;
  final double payoutAmount;
  final int bucketIndex;
  final List<PlinkoWaypoint> waypoints;
  int wpIdx;
  double wpT;
  bool settled;
  final List<PlinkoTrailPoint> trail;

  /// FLAG: isPlaceholder marks balls generated with client simulated paths until backend is integrated
  final bool isPlaceholder;

  PlinkoBall({
    required this.id,
    required this.x,
    required this.y,
    this.r = 6.5,
    required this.currency,
    required this.betAmount,
    required this.multiplier,
    required this.payoutAmount,
    required this.bucketIndex,
    required this.waypoints,
    this.wpIdx = 0,
    this.wpT = 0.0,
    this.settled = false,
    List<PlinkoTrailPoint>? trail,
    this.isPlaceholder = true, // PLACEHOLDER FLAG
  }) : trail = trail ?? [];
}

class PlinkoWinRecord {
  final String id;
  final double multiplier;
  final Color color;
  final double payout;
  final PlinkoCurrency currency;

  /// FLAG: isPlaceholder marks simulated offline records
  final bool isPlaceholder;

  const PlinkoWinRecord({
    required this.id,
    required this.multiplier,
    required this.color,
    required this.payout,
    required this.currency,
    this.isPlaceholder = true, // PLACEHOLDER FLAG
  });
}

