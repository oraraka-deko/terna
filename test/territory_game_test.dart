import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:terna/models/territory_game/territory_models.dart';
import 'package:terna/services/territory_game/territory_slicing_service.dart';
import 'package:terna/services/territory_game/territory_physics_service.dart';
import 'package:terna/services/territory_game/npc_engine_service.dart';
import 'package:terna/services/territory_game/territory_game_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Territory Slicing Service Tests', () {
    test('Empty bets returns neutral arena table', () {
      final slices = TerritorySlicingService.computeProportionalTerritories([]);
      expect(slices.length, 1);
      expect(slices.first.playerId, 'neutral');
      expect(slices.first.w, 460.0);
      expect(slices.first.h, 460.0);
    });

    test('1 player takes entire table', () {
      const bet = PlayerBet(
        playerId: 'p1',
        username: '@alice',
        avatar: '',
        color: Colors.teal,
        currency: 'ton',
        amount: 1.0,
        totalBet: 10.0,
      );
      final slices = TerritorySlicingService.computeProportionalTerritories([
        bet,
      ]);
      expect(slices.length, 1);
      expect(slices.first.playerId, 'p1');
      expect(slices.first.winProbability, 1.0);
      expect(slices.first.points.length, 4);
    });

    test('2 players split table with straight angled cut', () {
      const p1 = PlayerBet(
        playerId: 'p1',
        username: '@alice',
        avatar: '',
        color: Colors.teal,
        currency: 'ton',
        amount: 1.0,
        totalBet: 10.0,
      );
      const p2 = PlayerBet(
        playerId: 'p2',
        username: '@bob',
        avatar: '',
        color: Colors.indigo,
        currency: 'ton',
        amount: 1.0,
        totalBet: 10.0,
      );
      final slices = TerritorySlicingService.computeProportionalTerritories([
        p1,
        p2,
      ]);
      expect(slices.length, 2);
      expect(slices[0].playerId, 'p1');
      expect(slices[1].playerId, 'p2');
      expect(slices[0].winProbability, closeTo(0.5, 0.01));
      expect(slices[1].winProbability, closeTo(0.5, 0.01));
    });

    test('3 players split into 3 vertical columns', () {
      final bets = [
        const PlayerBet(
          playerId: 'p1',
          username: '@p1',
          avatar: '',
          color: Colors.red,
          currency: 'ton',
          amount: 1.0,
          totalBet: 10.0,
        ),
        const PlayerBet(
          playerId: 'p2',
          username: '@p2',
          avatar: '',
          color: Colors.green,
          currency: 'ton',
          amount: 1.0,
          totalBet: 10.0,
        ),
        const PlayerBet(
          playerId: 'p3',
          username: '@p3',
          avatar: '',
          color: Colors.blue,
          currency: 'ton',
          amount: 1.0,
          totalBet: 10.0,
        ),
      ];
      final slices = TerritorySlicingService.computeProportionalTerritories(
        bets,
      );
      expect(slices.length, 3);
      expect(
        slices[0].winProbability +
            slices[1].winProbability +
            slices[2].winProbability,
        closeTo(1.0, 0.01),
      );
    });

    test('4 players generate 2D tessellation', () {
      final bets = List.generate(
        4,
        (i) => PlayerBet(
          playerId: 'p$i',
          username: '@p$i',
          avatar: '',
          color: Colors.amber,
          currency: 'ton',
          amount: 1.0,
          totalBet: 10.0,
        ),
      );
      final slices = TerritorySlicingService.computeProportionalTerritories(
        bets,
      );
      expect(slices.length, 4);
      for (final s in slices) {
        expect(s.points.length, greaterThanOrEqualTo(3));
      }
    });

    test('Point in polygon detects interior and exterior points', () {
      const square = [
        TerritoryPoint(0, 0),
        TerritoryPoint(100, 0),
        TerritoryPoint(100, 100),
        TerritoryPoint(0, 100),
      ];
      expect(TerritorySlicingService.isPointInPolygon(50, 50, square), isTrue);
      expect(
        TerritorySlicingService.isPointInPolygon(150, 50, square),
        isFalse,
      );
    });
  });

  group('Territory Physics Service Tests', () {
    test('simulateAirHockeyFlight derives a reproducible winner from its landing point', () {
      const p1 = PlayerBet(
        playerId: 'p1',
        username: '@alice',
        avatar: '',
        color: Colors.teal,
        currency: 'ton',
        amount: 2.0,
        totalBet: 20.0,
      );
      const p2 = PlayerBet(
        playerId: 'p2',
        username: '@bob',
        avatar: '',
        color: Colors.indigo,
        currency: 'ton',
        amount: 1.0,
        totalBet: 10.0,
      );
      final territories =
          TerritorySlicingService.computeProportionalTerritories([p1, p2]);

      final trajectory = TerritoryPhysicsService.simulateAirHockeyFlight(
        seed: '12345',
        territories: territories,
        durationMs: 8000.0,
      );
      final repeatedTrajectory =
          TerritoryPhysicsService.simulateAirHockeyFlight(
            seed: '12345',
            territories: territories,
            durationMs: 8000.0,
          );

      expect(trajectory.points, isNotEmpty);
      expect(trajectory.finalX, greaterThan(0));
      expect(trajectory.finalY, greaterThan(0));
      expect(
        trajectory.points.map((point) => point.toJson()).toList(),
        repeatedTrajectory.points.map((point) => point.toJson()).toList(),
      );
      for (final point in trajectory.points) {
        expect(point.x * 100, closeTo((point.x * 100).roundToDouble(), 0.0001));
        expect(point.y * 100, closeTo((point.y * 100).roundToDouble(), 0.0001));
        expect(point.vx * 100, closeTo((point.vx * 100).roundToDouble(), 0.0001));
        expect(point.vy * 100, closeTo((point.vy * 100).roundToDouble(), 0.0001));
      }

      final landedPoly = TerritorySlicingService.findPlayerAtPoint(
        trajectory.finalX,
        trajectory.finalY,
        territories,
      );
      expect(landedPoly, isNotNull);
      expect(trajectory.winnerPlayerId, landedPoly!.playerId);
    });

    test('sampleTrajectory smoothly interpolates positions', () {
      final traj = AirHockeyTrajectory(
        points: const [
          PhysicsPoint(x: 230, y: 230, vx: 100, vy: 100, timeMs: 0),
          PhysicsPoint(x: 300, y: 300, vx: 50, vy: 50, timeMs: 4000),
          PhysicsPoint(
            x: 350,
            y: 350,
            vx: 0,
            vy: 0,
            timeMs: 8000,
            isStopped: true,
          ),
        ],
        wallHits: [],
        finalX: 350,
        finalY: 350,
        winnerPlayerId: 'p1',
        totalDurationMs: 8000,
        wallHitsCount: 0,
        launchAngle: 0.785,
        initialSpeed: 141.4,
        stopTimeMs: 8000,
      );

      final start = TerritoryPhysicsService.sampleTrajectory(traj, 0.0);
      expect(start.x, 230.0);
      expect(start.y, 230.0);

      final mid = TerritoryPhysicsService.sampleTrajectory(traj, 0.5);
      expect(mid.x, closeTo(300.0, 5.0));

      final end = TerritoryPhysicsService.sampleTrajectory(traj, 1.0);
      expect(end.x, 350.0);
      expect(end.isStopped, isTrue);
    });
  });

  group('NPC Engine & Repository Tests', () {
    test(
      'generateNpcBet produces realistic simulated bets tagged as placeholder',
      () {
        final bet = NpcEngineService.generateNpcBet(index: 0);
        expect(bet.isPlaceholder, isTrue);
        expect(bet.playerId.startsWith('npc_'), isTrue);
        expect(bet.amount, greaterThan(0));
      },
    );

    test('TerritoryGameRepository handles balances and round creation', () {
      final repo = TerritoryGameRepository();
      expect(repo.userTonBalance, 10.0);
      expect(repo.userStarsBalance, 100);

      final debited = repo.debitUserBalance('ton', 2.0);
      expect(debited, isTrue);
      expect(repo.userTonBalance, 8.0);

      repo.creditUserPayout(3.5, 0);
      expect(repo.userTonBalance, 11.5);

      final round = repo.createNewRound();
      expect(round.status, RoundStatus.bettingOpen);
      expect(round.serverSeedHash, isNotEmpty);
      expect(round.revealedServerSeed, isNull);
      expect(round.bets, isEmpty);
    });
  });
}
