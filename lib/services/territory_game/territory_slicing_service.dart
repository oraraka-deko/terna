import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:terna/models/territory_game/territory_models.dart';

/// Vibrant high-contrast flat color palette matching area_game
const List<Color> kVibrantTerritoryColors = [
  Color(0xFF2DD4BF), // Vibrant Teal / Cyan
  Color(0xFF6366F1), // Royal Purple / Indigo
  Color(0xFF65E538), // Bright Lime Green
  Color(0xFFF97316), // Vibrant Orange
  Color(0xFFF43F5E), // Coral / Rose
  Color(0xFF26B8C5), // Electric Deep Teal
  Color(0xFF5850EC), // Electric Violet
  Color(0xFF4ADE80), // Spring Mint Green
  Color(0xFFFB923C), // Warm Sunset Orange
];

/// Proportional Voronoi / Power Diagram & Slicing Engine
class TerritorySlicingService {
  /// Ray-casting algorithm for point-in-polygon containment
  static bool isPointInPolygon(double x, double y, List<TerritoryPoint> points) {
    if (points.length < 3) return false;
    bool inside = false;
    for (int i = 0, j = points.length - 1; i < points.length; j = i++) {
      final xi = points[i].x;
      final yi = points[i].y;
      final xj = points[j].x;
      final yj = points[j].y;

      final intersect = (yi > y != yj > y) &&
          (x < ((xj - xi) * (y - yi)) / (yj - yi + 0.0000001) + xi);
      if (intersect) inside = !inside;
    }
    return inside;
  }

  static double _hypot(double a, double b) => math.sqrt(a * a + b * b);

  /// Distance from point (px, py) to line segment (a, b)
  static double distToSegment(
    double px,
    double py,
    TerritoryPoint a,
    TerritoryPoint b,
  ) {
    final dx = b.x - a.x;
    final dy = b.y - a.y;
    final l2 = dx * dx + dy * dy;
    if (l2 == 0) return _hypot(px - a.x, py - a.y);
    double t = ((px - a.x) * dx + (py - a.y) * dy) / l2;
    t = math.max(0.0, math.min(1.0, t));
    return _hypot(px - (a.x + t * dx), py - (a.y + t * dy));
  }

  /// Minimum distance from point (px, py) to any polygon perimeter edge
  static double distToPolyEdges(
    double px,
    double py,
    List<TerritoryPoint> pts,
  ) {
    double minDist = double.infinity;
    for (int i = 0; i < pts.length; i++) {
      final j = (i + 1) % pts.length;
      final d = distToSegment(px, py, pts[i], pts[j]);
      if (d < minDist) minDist = d;
    }
    return minDist;
  }

  /// Computes polygon centroid using shoelace formula
  static TerritoryPoint computeCentroid(List<TerritoryPoint> points) {
    if (points.isEmpty) return const TerritoryPoint(0, 0);
    if (points.length == 1) return points[0];
    if (points.length == 2) {
      return TerritoryPoint(
        (points[0].x + points[1].x) / 2,
        (points[0].y + points[1].y) / 2,
      );
    }

    double signedArea = 0;
    double cx = 0;
    double cy = 0;

    for (int i = 0; i < points.length; i++) {
      final p0 = points[i];
      final p1 = points[(i + 1) % points.length];
      final a = p0.x * p1.y - p1.x * p0.y;
      signedArea += a;
      cx += (p0.x + p1.x) * a;
      cy += (p0.y + p1.y) * a;
    }

    signedArea *= 0.5;
    if (signedArea.abs() < 0.0001) {
      final avgX = points.fold<double>(0, (acc, p) => acc + p.x) / points.length;
      final avgY = points.fold<double>(0, (acc, p) => acc + p.y) / points.length;
      return TerritoryPoint(avgX, avgY);
    }

    cx = cx / (6 * signedArea);
    cy = cy / (6 * signedArea);
    return TerritoryPoint(cx, cy);
  }

  /// Finds Pole of Inaccessibility (deepest point inside polygon with largest clearance to edges)
  static ({double x, double y, double maxRadius}) computePoleOfInaccessibility(
    List<TerritoryPoint> points,
    double minX,
    double minY,
    double maxX,
    double maxY,
  ) {
    final centroid = computeCentroid(points);
    TerritoryPoint bestPoint = centroid;
    double bestDist = isPointInPolygon(centroid.x, centroid.y, points)
        ? distToPolyEdges(centroid.x, centroid.y, points)
        : 0.0;

    const steps = 7;
    final stepX = (maxX - minX) / (steps + 1);
    final stepY = (maxY - minY) / (steps + 1);

    for (int ix = 1; ix <= steps; ix++) {
      for (int iy = 1; iy <= steps; iy++) {
        final px = minX + ix * stepX;
        final py = minY + iy * stepY;
        if (isPointInPolygon(px, py, points)) {
          final d = distToPolyEdges(px, py, points);
          if (d > bestDist) {
            bestDist = d;
            bestPoint = TerritoryPoint(px, py);
          }
        }
      }
    }

    return (
      x: bestPoint.x.roundToDouble(),
      y: bestPoint.y.roundToDouble(),
      maxRadius: math.max(16.0, bestDist.roundToDouble()),
    );
  }

  /// Sutherland-Hodgman convex polygon clipping against half-plane A*x + B*y + C <= 0
  static List<TerritoryPoint> clipPolygonHalfPlane(
    List<TerritoryPoint> poly,
    double A,
    double B,
    double C,
  ) {
    if (poly.length < 3) return [];
    final List<TerritoryPoint> out = [];
    final n = poly.length;

    for (int i = 0; i < n; i++) {
      final cur = poly[i];
      final prev = poly[(i + n - 1) % n];

      final dCur = A * cur.x + B * cur.y + C;
      final dPrev = A * prev.x + B * prev.y + C;

      if (dCur <= 0) {
        if (dPrev > 0) {
          final t = -dPrev / (dCur - dPrev);
          out.add(TerritoryPoint(
            ((prev.x + t * (cur.x - prev.x)) * 10).round() / 10.0,
            ((prev.y + t * (cur.y - prev.y)) * 10).round() / 10.0,
          ));
        }
        out.add(cur);
      } else if (dPrev <= 0) {
        final t = -dPrev / (dCur - dPrev);
        out.add(TerritoryPoint(
          ((prev.x + t * (cur.x - prev.x)) * 10).round() / 10.0,
          ((prev.y + t * (cur.y - prev.y)) * 10).round() / 10.0,
        ));
      }
    }
    return out;
  }

  /// Shoelace area of polygon
  static double computePolygonArea(List<TerritoryPoint> pts) {
    if (pts.length < 3) return 0.0;
    double a = 0.0;
    for (int i = 0; i < pts.length; i++) {
      final j = (i + 1) % pts.length;
      a += pts[i].x * pts[j].y - pts[j].x * pts[i].y;
    }
    return a.abs() * 0.5;
  }

  /// Finds which player territory contains the given point
  static WatertightPolygon? findPlayerAtPoint(
    double x,
    double y,
    List<WatertightPolygon> territories,
  ) {
    for (final poly in territories) {
      if (isPointInPolygon(x, y, poly.points)) {
        return poly;
      }
    }
    return territories.isNotEmpty ? territories.first : null;
  }

  /// Main algorithm: Proportional Voronoi / Column Slicing Engine
  static List<WatertightPolygon> computeProportionalTerritories(
    List<PlayerBet> bets, [
    double W = 460.0,
    double H = 460.0,
  ]) {
    final totalArea = W * H;

    // 0 Players: Neutral empty arena table
    if (bets.isEmpty) {
      return [
        WatertightPolygon(
          playerId: 'neutral',
          username: 'Arena',
          avatar: '',
          color: const Color(0xFF111318),
          winProbability: 1.0,
          totalBet: 0.0,
          x: 0,
          y: 0,
          w: W,
          h: H,
          points: [
            const TerritoryPoint(0, 0),
            TerritoryPoint(W, 0),
            TerritoryPoint(W, H),
            TerritoryPoint(0, H),
          ],
          innerX: W / 2,
          innerY: H / 2,
          maxRadius: 100,
        ),
      ];
    }

    // 1 Player: Takes the entire table
    if (bets.length == 1) {
      final bet = bets[0];
      return [
        WatertightPolygon(
          playerId: bet.playerId,
          username: bet.username,
          firstName: bet.firstName,
          avatar: bet.avatar,
          color: kVibrantTerritoryColors[0],
          winProbability: 1.0,
          totalBet: bet.totalBet,
          x: 0,
          y: 0,
          w: W,
          h: H,
          points: [
            const TerritoryPoint(0, 0),
            TerritoryPoint(W, 0),
            TerritoryPoint(W, H),
            TerritoryPoint(0, H),
          ],
          innerX: W / 2,
          innerY: H / 2,
          maxRadius: 120,
        ),
      ];
    }

    // Normalize weights & probabilities
    final totalWeight = bets.fold<double>(
      0.0,
      (sum, b) => sum + (b.totalBet > 0 ? b.totalBet : (b.winProbability > 0 ? b.winProbability * 100 : 1.0)),
    );

    final normalizedBets = <({
      PlayerBet bet,
      Color color,
      double fraction,
    })>[];

    for (int i = 0; i < bets.length; i++) {
      final b = bets[i];
      final weight = b.totalBet > 0 ? b.totalBet : (b.winProbability > 0 ? b.winProbability * 100 : 1.0);
      final rawFrac = math.max(0.02, weight / (totalWeight > 0 ? totalWeight : 1.0));
      normalizedBets.add((
        bet: b,
        color: kVibrantTerritoryColors[i % kVibrantTerritoryColors.length],
        fraction: rawFrac,
      ));
    }

    final fracSum = normalizedBets.fold<double>(0.0, (acc, item) => acc + item.fraction);
    final scaledBets = normalizedBets.map((item) => (
      bet: item.bet,
      color: item.color,
      fraction: item.fraction / fracSum,
    )).toList();

    // 2 PLAYERS: Straight slightly-angled split
    if (scaledBets.length == 2) {
      final p1 = scaledBets[0];
      final p2 = scaledBets[1];

      final meanX = p1.fraction * W;
      final maxSlant = math.min(22.0, math.min(meanX, W - meanX) * 0.3);
      final xTop = ((meanX - maxSlant) * 10).round() / 10.0;
      final xBot = ((meanX + maxSlant) * 10).round() / 10.0;

      final poly1Points = [
        const TerritoryPoint(0, 0),
        TerritoryPoint(xTop, 0),
        TerritoryPoint(xBot, H),
        TerritoryPoint(0, H),
      ];

      final poly2Points = [
        TerritoryPoint(xTop, 0),
        TerritoryPoint(W, 0),
        TerritoryPoint(W, H),
        TerritoryPoint(xBot, H),
      ];

      final pole1 = computePoleOfInaccessibility(poly1Points, 0, 0, math.max(xTop, xBot), H);
      final pole2 = computePoleOfInaccessibility(poly2Points, math.min(xTop, xBot), 0, W, H);

      return [
        WatertightPolygon(
          playerId: p1.bet.playerId,
          username: p1.bet.username,
          firstName: p1.bet.firstName,
          avatar: p1.bet.avatar,
          color: p1.color,
          winProbability: p1.fraction,
          totalBet: p1.bet.totalBet,
          x: 0,
          y: 0,
          w: math.max(xTop, xBot),
          h: H,
          points: poly1Points,
          innerX: pole1.x,
          innerY: pole1.y,
          maxRadius: pole1.maxRadius,
        ),
        WatertightPolygon(
          playerId: p2.bet.playerId,
          username: p2.bet.username,
          firstName: p2.bet.firstName,
          avatar: p2.bet.avatar,
          color: p2.color,
          winProbability: p2.fraction,
          totalBet: p2.bet.totalBet,
          x: math.min(xTop, xBot),
          y: 0,
          w: W - math.min(xTop, xBot),
          h: H,
          points: poly2Points,
          innerX: pole2.x,
          innerY: pole2.y,
          maxRadius: pole2.maxRadius,
        ),
      ];
    }

    // 3 PLAYERS: 3 Parallel Vertical Columns
    if (scaledBets.length == 3) {
      final p1 = scaledBets[0];
      final p2 = scaledBets[1];
      final p3 = scaledBets[2];

      final meanX1 = p1.fraction * W;
      final meanX2 = (p1.fraction + p2.fraction) * W;

      final slant1 = math.min(15.0, math.min(meanX1, meanX2 - meanX1) * 0.22);
      final slant2 = math.min(15.0, math.min(meanX2 - meanX1, W - meanX2) * 0.22);

      final x1Top = ((meanX1 - slant1) * 10).round() / 10.0;
      final x1Bot = ((meanX1 + slant1) * 10).round() / 10.0;
      final x2Top = ((meanX2 + slant2) * 10).round() / 10.0;
      final x2Bot = ((meanX2 - slant2) * 10).round() / 10.0;

      final poly1Points = [
        const TerritoryPoint(0, 0),
        TerritoryPoint(x1Top, 0),
        TerritoryPoint(x1Bot, H),
        TerritoryPoint(0, H),
      ];

      final poly2Points = [
        TerritoryPoint(x1Top, 0),
        TerritoryPoint(x2Top, 0),
        TerritoryPoint(x2Bot, H),
        TerritoryPoint(x1Bot, H),
      ];

      final poly3Points = [
        TerritoryPoint(x2Top, 0),
        TerritoryPoint(W, 0),
        TerritoryPoint(W, H),
        TerritoryPoint(x2Bot, H),
      ];

      final pole1 = computePoleOfInaccessibility(poly1Points, 0, 0, math.max(x1Top, x1Bot), H);
      final pole2 = computePoleOfInaccessibility(poly2Points, math.min(x1Top, x1Bot), 0, math.max(x2Top, x2Bot), H);
      final pole3 = computePoleOfInaccessibility(poly3Points, math.min(x2Top, x2Bot), 0, W, H);

      return [
        WatertightPolygon(
          playerId: p1.bet.playerId,
          username: p1.bet.username,
          firstName: p1.bet.firstName,
          avatar: p1.bet.avatar,
          color: p1.color,
          winProbability: p1.fraction,
          totalBet: p1.bet.totalBet,
          x: 0,
          y: 0,
          w: math.max(x1Top, x1Bot),
          h: H,
          points: poly1Points,
          innerX: pole1.x,
          innerY: pole1.y,
          maxRadius: pole1.maxRadius,
        ),
        WatertightPolygon(
          playerId: p2.bet.playerId,
          username: p2.bet.username,
          firstName: p2.bet.firstName,
          avatar: p2.bet.avatar,
          color: p2.color,
          winProbability: p2.fraction,
          totalBet: p2.bet.totalBet,
          x: math.min(x1Top, x1Bot),
          y: 0,
          w: math.max(x2Top, x2Bot) - math.min(x1Top, x1Bot),
          h: H,
          points: poly2Points,
          innerX: pole2.x,
          innerY: pole2.y,
          maxRadius: pole2.maxRadius,
        ),
        WatertightPolygon(
          playerId: p3.bet.playerId,
          username: p3.bet.username,
          firstName: p3.bet.firstName,
          avatar: p3.bet.avatar,
          color: p3.color,
          winProbability: p3.fraction,
          totalBet: p3.bet.totalBet,
          x: math.min(x2Top, x2Bot),
          y: 0,
          w: W - math.min(x2Top, x2Bot),
          h: H,
          points: poly3Points,
          innerX: pole3.x,
          innerY: pole3.y,
          maxRadius: pole3.maxRadius,
        ),
      ];
    }

    // 4+ PLAYERS: 2D Power Diagram Tessellation
    final n = scaledBets.length;
    final List<({double x, double y, double w})> sites = [];

    if (n == 4) {
      sites.addAll([
        (x: 0.28 * W, y: 0.28 * H, w: 0.0),
        (x: 0.72 * W, y: 0.28 * H, w: 0.0),
        (x: 0.28 * W, y: 0.72 * H, w: 0.0),
        (x: 0.72 * W, y: 0.72 * H, w: 0.0),
      ]);
    } else if (n == 5) {
      sites.addAll([
        (x: 0.32 * W, y: 0.28 * H, w: 0.0),
        (x: 0.68 * W, y: 0.28 * H, w: 0.0),
        (x: 0.20 * W, y: 0.72 * H, w: 0.0),
        (x: 0.50 * W, y: 0.72 * H, w: 0.0),
        (x: 0.80 * W, y: 0.72 * H, w: 0.0),
      ]);
    } else {
      final cols = math.sqrt(n).ceil();
      final rows = (n / cols).ceil();
      for (int i = 0; i < n; i++) {
        final r = i ~/ cols;
        final c = i % cols;
        final countInRow = r == rows - 1 ? (n - r * cols) : cols;
        final sx = ((c + 0.5) / countInRow) * W;
        final sy = ((r + 0.5) / rows) * H;
        sites.add((x: sx, y: sy, w: 0.0));
      }
    }

    final targetAreas = scaledBets.map((b) => b.fraction * totalArea).toList();
    List<List<TerritoryPoint>> cellPolygons = [];
    const iterations = 8;

    for (int iter = 0; iter < iterations; iter++) {
      cellPolygons = [];
      for (int i = 0; i < sites.length; i++) {
        final si = sites[i];
        List<TerritoryPoint> poly = [
          const TerritoryPoint(0, 0),
          TerritoryPoint(W, 0),
          TerritoryPoint(W, H),
          TerritoryPoint(0, H),
        ];

        for (int j = 0; j < sites.length; j++) {
          if (i == j) continue;
          final sj = sites[j];
          final A = 2 * (sj.x - si.x);
          final B = 2 * (sj.y - si.y);
          final C = (si.x * si.x + si.y * si.y - si.w) -
              (sj.x * sj.x + sj.y * sj.y - sj.w);
          poly = clipPolygonHalfPlane(poly, A, B, C);
          if (poly.length < 3) break;
        }
        cellPolygons.add(poly);
      }

      // Adjust weights and site centers
      for (int i = 0; i < sites.length; i++) {
        final p = cellPolygons[i];
        final area = computePolygonArea(p);
        final diff = targetAreas[i] - area;
        final newW = sites[i].w + diff * 0.45;
        double newX = sites[i].x;
        double newY = sites[i].y;

        if (p.length >= 3) {
          final c = computeCentroid(p);
          newX += (c.x - sites[i].x) * 0.18;
          newY += (c.y - sites[i].y) * 0.18;
        }
        sites[i] = (x: newX, y: newY, w: newW);
      }
    }

    final List<WatertightPolygon> result = [];
    for (int i = 0; i < scaledBets.length; i++) {
      final item = scaledBets[i];
      List<TerritoryPoint> poly = (i < cellPolygons.length && cellPolygons[i].length >= 3)
          ? cellPolygons[i]
          : [
              const TerritoryPoint(0, 0),
              TerritoryPoint(W, 0),
              TerritoryPoint(W, H),
              TerritoryPoint(0, H),
            ];

      double minX = W;
      double maxX = 0;
      double minY = H;
      double maxY = 0;
      for (final pt in poly) {
        if (pt.x < minX) minX = pt.x;
        if (pt.x > maxX) maxX = pt.x;
        if (pt.y < minY) minY = pt.y;
        if (pt.y > maxY) maxY = pt.y;
      }

      final pole = computePoleOfInaccessibility(poly, minX, minY, maxX, maxY);

      result.add(WatertightPolygon(
        playerId: item.bet.playerId,
        username: item.bet.username,
        firstName: item.bet.firstName,
        avatar: item.bet.avatar,
        color: item.color,
        winProbability: item.fraction,
        totalBet: item.bet.totalBet,
        x: minX,
        y: minY,
        w: maxX - minX,
        h: maxY - minY,
        points: poly,
        innerX: pole.x,
        innerY: pole.y,
        maxRadius: pole.maxRadius,
      ));
    }

    return result;
  }
}
