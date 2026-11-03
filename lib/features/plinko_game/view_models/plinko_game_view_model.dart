import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:terna/models/plinko_game/plinko_models.dart';
import 'package:terna/services/haptic.dart';
import 'package:terna/services/plinko_game/plinko_audio_service.dart';
import 'package:terna/services/plinko_game/plinko_game_repository.dart';

class PlinkoGameViewModel extends ChangeNotifier {
  final PlinkoGameRepository repository;
  final TickerProvider vsync;

  PlinkoGameViewModel({
    required this.repository,
    required this.vsync,
  }) {
    _initBoard();
    _startTicker();
  }

  // Board Geometry Constants matching PlinkoGame.tsx
  static const double width = 380.0;
  static const double height = 470.0;
  static const int rows = 12;
  static const double startY = 65.0;
  static const double endY = 380.0;
  static const double dy = (endY - startY) / (rows - 1);
  static const double pitch = 23.5;

  // Settings
  PlinkoCurrency currency = PlinkoCurrency.ton;
  double betAmount = 0.2;
  PlinkoRisk risk = PlinkoRisk.medium;

  // Live state
  final List<PlinkoPeg> pegs = [];
  final List<PlinkoBucket> buckets = [];
  final List<PlinkoBall> balls = [];
  final List<PlinkoWinRecord> recentMultipliers = [];
  PlinkoWinRecord? lastWin;

  Ticker? _ticker;
  Duration _lastTickerElapsed = Duration.zero;
  bool isDropping = false;
  String? errorMessage;

  double get tonBalance => repository.tonBalance;
  int get starsBalance => repository.starsBalance;
  int get activeBallsCount => balls.where((b) => !b.settled).length;

  static double getPegY(int r) => startY + r * dy;

  static double getPegX(int r, int c) {
    final count = r + 3;
    final rowWidth = (count - 1) * pitch;
    final startX = (width - rowWidth) / 2.0;
    return startX + c * pitch;
  }

  void _initBoard() {
    pegs.clear();
    for (var r = 0; r < rows; r++) {
      final rowY = getPegY(r);
      final count = r + 3;
      for (var c = 0; c < count; c++) {
        pegs.add(
          PlinkoPeg(
            x: getPegX(r, c),
            y: rowY,
            r: 3.5,
          ),
        );
      }
    }
    _rebuildBuckets();
  }

  void _rebuildBuckets() {
    buckets.clear();
    final multis = risk.multipliers;
    final bucketCount = multis.length;
    const availableWidth = width - 24.0;
    final bucketW = availableWidth / bucketCount;

    for (var i = 0; i < bucketCount; i++) {
      final style = PlinkoBucketStyle.fromMultiplier(multis[i]);
      buckets.add(
        PlinkoBucket(
          x: 12.0 + (i * bucketW),
          w: bucketW,
          multiplier: multis[i],
          color: style.bg,
          glowColor: style.glow,
        ),
      );
    }
  }

  // --- Setting Handlers ---

  void setCurrency(PlinkoCurrency newCurrency) {
    currency = newCurrency;
    if (currency == PlinkoCurrency.stars) {
      if (betAmount < 10) betAmount = 10.0;
    } else {
      if (betAmount > 10) betAmount = 0.2;
    }
    PlinkoAudioService.playPegClick();
    HapticFeedbackService.tap();
    notifyListeners();
  }

  void setRisk(PlinkoRisk newRisk) {
    risk = newRisk;
    _rebuildBuckets();
    PlinkoAudioService.playPegClick();
    HapticFeedbackService.tap();
    notifyListeners();
  }

  void setBetAmount(double val) {
    if (currency == PlinkoCurrency.stars) {
      betAmount = max(10.0, val.floorToDouble());
    } else {
      betAmount = max(0.05, double.parse(val.toStringAsFixed(2)));
    }
    notifyListeners();
  }

  void addBetIncrement(double inc) {
    if (currency == PlinkoCurrency.stars) {
      betAmount = (betAmount + inc).floorToDouble();
    } else {
      betAmount = double.parse((betAmount + inc).toStringAsFixed(2));
    }
    PlinkoAudioService.playPegClick();
    HapticFeedbackService.tap();
    notifyListeners();
  }

  void setMaxBet() {
    final currentBal = currency == PlinkoCurrency.ton ? tonBalance : starsBalance.toDouble();
    if (currency == PlinkoCurrency.stars) {
      betAmount = max(10.0, currentBal.floorToDouble());
    } else {
      betAmount = max(0.05, double.parse(currentBal.toStringAsFixed(2)));
    }
    PlinkoAudioService.playPegClick();
    HapticFeedbackService.tap();
    notifyListeners();
  }

  void clearBet() {
    betAmount = currency == PlinkoCurrency.stars ? 10.0 : 0.1;
    PlinkoAudioService.playPegClick();
    HapticFeedbackService.tap();
    notifyListeners();
  }

  // --- Drop Ball Action ---

  Future<void> dropBall() async {
    if (isDropping) return;
    final selectedCurrency = currency;
    final selectedBet = betAmount;
    final selectedRisk = risk;
    final currentBal =
        selectedCurrency == PlinkoCurrency.ton ? tonBalance : starsBalance.toDouble();
    if (currentBal < selectedBet || selectedBet <= 0) {
      errorMessage = 'Insufficient balance for this bet.';
      HapticFeedbackService.error();
      notifyListeners();
      return;
    }

    isDropping = true;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await repository.requestDropFromBackend(
        betAmount: selectedBet,
        currency: selectedCurrency,
        risk: selectedRisk,
      );
      final rawPath = result['path'];
      if (rawPath is! List) {
        throw const FormatException('The backend returned an invalid Plinko path.');
      }
      final path = rawPath.map((step) {
        if (step is! num || (step != 0 && step != 1)) {
          throw const FormatException('The backend returned an invalid Plinko path.');
        }
        return step.toInt();
      }).toList();
      final bucketValue = result['terminalBin'];
      final multiplierValue = result['multiplier'];
      final payoutValue = result['payout'];
      if (path.length != rows ||
          bucketValue is! num ||
          multiplierValue is! num ||
          payoutValue is! num) {
        throw const FormatException('The backend returned an incomplete Plinko result.');
      }

      final bucketIndex = bucketValue.toInt();
      if (bucketIndex < 0 ||
          bucketIndex >= buckets.length ||
          path.reduce((a, b) => a + b) != bucketIndex) {
        throw const FormatException('The backend returned an inconsistent Plinko result.');
      }
      final multiplier = multiplierValue.toDouble();
      final payout = payoutValue.toDouble();

      PlinkoAudioService.playDrop();
      HapticFeedbackService.lightImpact();

      // Build waypoints through peg grid
      final waypoints = <PlinkoWaypoint>[
        const PlinkoWaypoint(x: width / 2.0, y: 35.0),
      ];

      var col = 1;
      for (var r = 0; r < rows; r++) {
        final targetX = getPegX(r, col);
        final targetY = getPegY(r);

        final pegIdx = pegs.indexWhere(
          (p) => (p.y - targetY).abs() < 4 && (p.x - targetX).abs() < 4,
        );

        waypoints.add(
          PlinkoWaypoint(
            x: targetX,
            y: targetY,
            pegIdx: pegIdx >= 0 ? pegIdx : null,
          ),
        );

        col += path[r];
      }

      final targetBucket = buckets[bucketIndex];
      waypoints.add(
        PlinkoWaypoint(
          x: targetBucket.x + (targetBucket.w / 2.0),
          y: height - 40.0,
          isBucket: true,
        ),
      );

      final ball = PlinkoBall(
        id: 'ball_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(9999)}',
        x: width / 2.0,
        y: 35.0,
        currency: selectedCurrency,
        betAmount: selectedBet,
        multiplier: multiplier,
        payoutAmount: payout,
        bucketIndex: bucketIndex,
        waypoints: waypoints,
        isPlaceholder: false,
      );

      balls.add(ball);
    } catch (error) {
      errorMessage = error.toString();
      HapticFeedbackService.error();
    } finally {
      isDropping = false;
      notifyListeners();
    }
  }

  // --- Continuous Animation Loop ---

  void _startTicker() {
    _ticker = vsync.createTicker((elapsed) {
      final elapsedSinceLastFrame = elapsed - _lastTickerElapsed;
      _lastTickerElapsed = elapsed;
      final frameDeltaMs = elapsedSinceLastFrame.inMicroseconds / 1000.0;
      final boundedDeltaMs = frameDeltaMs.clamp(0.0, 50.0);
      var needsRepaint = false;

      // 1. Decay Peg shockwaves
      for (final peg in pegs) {
        if (peg.hit > 0.0) {
          peg.hit = max(0.0, peg.hit - 0.045);
          needsRepaint = true;
        }
      }

      // 2. Decay Bucket bounce
      for (final bucket in buckets) {
        if (bucket.hitCount > 0.0) {
          bucket.hitCount = max(0.0, bucket.hitCount - 0.045);
          needsRepaint = true;
        }
      }

      // 3. Step active balls
      final activeBalls = <PlinkoBall>[];
      final random = Random();

      for (final ball in balls) {
        if (ball.settled) continue;

        needsRepaint = true;
        ball.wpT += boundedDeltaMs / 180.0;

        if (ball.wpT >= 1.0) {
          ball.wpT = 0.0;
          ball.wpIdx++;

          if (ball.wpIdx < ball.waypoints.length) {
            final currWp = ball.waypoints[ball.wpIdx];

            if (currWp.pegIdx != null && currWp.pegIdx! < pegs.length) {
              pegs[currWp.pegIdx!].hit = 1.0;
              PlinkoAudioService.playPegClick(550.0 + (random.nextDouble() * 260.0));
              HapticFeedbackService.lightImpact();
            }

            if (currWp.isBucket || ball.wpIdx >= ball.waypoints.length - 1) {
              ball.settled = true;
              final b = buckets[ball.bucketIndex.clamp(0, buckets.length - 1)];
              b.hitCount = 1.0;

              final winRec = PlinkoWinRecord(
                id: 'rec_${DateTime.now().microsecondsSinceEpoch}',
                multiplier: ball.multiplier,
                color: b.color,
                payout: ball.payoutAmount,
                currency: ball.currency,
                isPlaceholder: false,
              );

              lastWin = winRec;
              recentMultipliers.insert(0, winRec);
              if (recentMultipliers.length > 6) {
                recentMultipliers.removeLast();
              }

              if (ball.multiplier >= 1.0) {
                PlinkoAudioService.playVictory();
                HapticFeedbackService.success();
              } else {
                PlinkoAudioService.playTick();
              }
            }
          }
        }

        final p0 = ball.wpIdx < ball.waypoints.length
            ? ball.waypoints[ball.wpIdx]
            : ball.waypoints.last;
        final p1 = (ball.wpIdx + 1) < ball.waypoints.length
            ? ball.waypoints[ball.wpIdx + 1]
            : p0;

        final u = ball.wpT.clamp(0.0, 1.0);
        ball.x = (1.0 - u) * p0.x + u * p1.x;
        // Parabolic bounce arc
        ball.y = (1.0 - u) * p0.y + u * p1.y - (7.5 * sin(pi * u));

        // Trail point
        ball.trail.add(PlinkoTrailPoint(x: ball.x, y: ball.y, alpha: 1.0));
        if (ball.trail.length > 12) ball.trail.removeAt(0);
        for (final t in ball.trail) {
          t.alpha *= 0.85;
        }

        if (!ball.settled) {
          activeBalls.add(ball);
        }
      }

      // Cleanup finished balls (keep recent for memory conservation)
      if (balls.length > 30) {
        balls.removeWhere((b) => b.settled);
      }

      if (needsRepaint) {
        notifyListeners();
      }
    });

    _ticker!.start();
  }

  @override
  void dispose() {
    _ticker?.stop();
    _ticker?.dispose();
    super.dispose();
  }
}
