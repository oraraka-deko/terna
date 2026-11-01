import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:terna/models/bump_game/bump_models.dart';
import 'package:terna/services/bump_game/bump_physics_service.dart';
import 'package:terna/services/bump_game/bump_game_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Arena Bump Physics & Metrics Tests', () {
    test('System bot alone has 35px starter radius (x2.5 larger)', () {
      final bot = BumpPlayerBall(
        id: 'system_core',
        username: 'Arena Core',
        avatar: '',
        color: Colors.orange,
        isSystemBot: true,
        betAmount: 100.0,
        currency: 'stars',
      );
      BumpPhysicsService.updateBallMetrics([bot]);
      expect(bot.radius, 35.0);
    });

    test('Dynamic relative ball metrics scale proportionally to stake ratios', () {
      final bot = BumpPlayerBall(
        id: 'system_core',
        username: 'Arena Core',
        avatar: '',
        color: Colors.orange,
        isSystemBot: true,
        betAmount: 100.0,
        currency: 'stars',
      );
      final user = BumpPlayerBall(
        id: 'p1',
        username: '@alice',
        avatar: '',
        color: Colors.blue,
        betAmount: 200.0,
        currency: 'stars',
      );

      final balls = [bot, user];
      BumpPhysicsService.updateBallMetrics(balls);

      // User has max stake (200) -> capped at max 40.0px
      expect(user.targetRadius, 40.0);
      // Bot has half user's stake -> smaller target radius
      expect(bot.targetRadius, lessThan(user.targetRadius));
      expect(bot.targetRadius, greaterThanOrEqualTo(16.0));

      // Now a 500 Stars whale joins: existing balls shrink proportionally
      final whale = BumpPlayerBall(
        id: 'p2',
        username: '@whale',
        avatar: '',
        color: Colors.purple,
        betAmount: 500.0,
        currency: 'stars',
      );
      balls.add(whale);
      BumpPhysicsService.updateBallMetrics(balls);

      expect(whale.targetRadius, 40.0);
      // Previous user and bot are shrunk
      expect(user.targetRadius, lessThan(40.0));
      expect(bot.targetRadius, lessThan(user.targetRadius));
    });

    test('Perimeter arrangement places balls strictly inside arena without edge clipping', () {
      final balls = List.generate(
        4,
        (i) => BumpPlayerBall(
          id: 'p$i',
          username: '@p$i',
          avatar: '',
          color: Colors.green,
          betAmount: 1.0,
          currency: 'ton',
        ),
      );

      BumpPhysicsService.arrangePerimeterBalls(balls);
      for (final b in balls) {
        expect(b.x, greaterThanOrEqualTo(16.0));
        expect(b.x, lessThanOrEqualTo(460.0 - 16.0));
        expect(b.y, greaterThanOrEqualTo(16.0));
        expect(b.y, lessThanOrEqualTo(460.0 - 16.0));
      }
    });

    test('Apply launch impulse pushes balls toward center', () {
      final b = BumpPlayerBall(
        id: 'p1',
        username: '@alice',
        avatar: '',
        color: Colors.blue,
        betAmount: 1.0,
        currency: 'ton',
        x: 48.0,
        y: 48.0,
      );

      BumpPhysicsService.applyLaunchImpulse([b]);
      // From top-left (48, 48) toward center (230, 230), vx and vy must be positive
      expect(b.vx, greaterThan(0));
      expect(b.vy, greaterThan(0));
    });

    test('Wall collisions bounce ball when hazard is closed or warning', () {
      final b = BumpPlayerBall(
        id: 'p1',
        username: '@alice',
        avatar: '',
        color: Colors.blue,
        betAmount: 1.0,
        currency: 'ton',
        x: 230.0,
        y: 18.0, // Near top wall (minY is 16.0, radius is 20)
        vx: 0.0,
        vy: -100.0,
        radius: 20.0,
      );

      final warningHazard = EdgeHazard(
        side: WallSide.top,
        startCoord: 180.0,
        endCoord: 280.0,
        status: EdgeHazardStatus.warning, // Warning is still a solid wall!
      );

      bool wallBumped = false;
      bool eliminated = false;

      BumpPhysicsService.updatePhysicsStep(
        dt: 0.016,
        balls: [b],
        hazards: [warningHazard],
        onBallBump: (_) {},
        onWallBump: (_) => wallBumped = true,
        onEliminated: (_) => eliminated = true,
      );

      // Warning edge must BOUNCE, NOT ELIMINATE
      expect(wallBumped, isTrue);
      expect(eliminated, isFalse);
      expect(b.vy, greaterThan(0)); // vy reflected downwards
      expect(b.state, BallState.alive);
    });

    test('Open hazard gap eliminates ball passing through', () {
      final b = BumpPlayerBall(
        id: 'p1',
        username: '@alice',
        avatar: '',
        color: Colors.blue,
        betAmount: 1.0,
        currency: 'ton',
        x: 230.0,
        y: 18.0, // Near top wall
        vx: 0.0,
        vy: -100.0,
        radius: 20.0,
      );

      final openHazard = EdgeHazard(
        side: WallSide.top,
        startCoord: 180.0,
        endCoord: 280.0,
        status: EdgeHazardStatus.open, // OPEN hazard gap!
      );

      bool eliminated = false;

      BumpPhysicsService.updatePhysicsStep(
        dt: 0.016,
        balls: [b],
        hazards: [openHazard],
        onBallBump: (_) {},
        onWallBump: (_) {},
        onEliminated: (_) => eliminated = true,
      );

      // Ball passes through open edge and gets eliminated!
      expect(eliminated, isTrue);
      expect(b.state, BallState.exiting);
    });

    test('Open hazard lip/corner bounces ball hitting the wall vertex', () {
      // Ball aimed right at the corner lip (x: 180.0, y: 16.0)
      final b = BumpPlayerBall(
        id: 'p1',
        username: '@alice',
        avatar: '',
        color: Colors.blue,
        betAmount: 1.0,
        currency: 'ton',
        x: 175.0, // Just to the left of the opening start (180.0)
        y: 25.0,
        vx: 50.0,
        vy: -100.0,
        radius: 18.0,
      );

      final openHazard = EdgeHazard(
        side: WallSide.top,
        startCoord: 180.0,
        endCoord: 280.0,
        status: EdgeHazardStatus.open,
      );

      bool wallBumped = false;
      bool eliminated = false;

      BumpPhysicsService.updatePhysicsStep(
        dt: 0.016,
        balls: [b],
        hazards: [openHazard],
        onBallBump: (_) {},
        onWallBump: (_) => wallBumped = true,
        onEliminated: (_) => eliminated = true,
      );

      // Must bounce off corner vertex, NOT be eliminated
      expect(wallBumped, isTrue);
      expect(eliminated, isFalse);
      expect(b.state, BallState.alive);
    });
  });

  group('Arena Bump Repository Tests', () {
    test('BumpGameRepository handles balances and history archiving', () {
      final repo = BumpGameRepository();
      expect(repo.userTonBalance, 10.0);
      expect(repo.userStarsBalance, 100);
      expect(repo.historyRecords, isNotEmpty);

      final debited = repo.debitUserBalance('ton', 2.5);
      expect(debited, isTrue);
      expect(repo.userTonBalance, 7.5);

      repo.creditUserPayout(5.0, 0);
      expect(repo.userTonBalance, 12.5);
    });
  });
}

