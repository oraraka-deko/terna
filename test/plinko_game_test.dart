import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terna/models/plinko_game/plinko_models.dart';
import 'package:terna/services/plinko_game/plinko_game_repository.dart';
import 'package:terna/features/plinko_game/view_models/plinko_game_view_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlinkoGame Unit & State Tests', () {
    late PlinkoGameRepository repository;

    setUp(() {
      repository = PlinkoGameRepository();
    });

    test('Risk levels configure correct 13 multiplier buckets', () {
      for (final risk in PlinkoRisk.values) {
        expect(risk.multipliers.length, 13);
        // Symmetrical: left-most and right-most multipliers match
        expect(risk.multipliers.first, risk.multipliers.last);
      }

      expect(PlinkoRisk.low.multipliers.first, 10.0);
      expect(PlinkoRisk.medium.multipliers.first, 33.0);
      expect(PlinkoRisk.high.multipliers.first, 170.0);
    });

    test('Bucket style mappings match multiplier thresholds', () {
      final highStyle = PlinkoBucketStyle.fromMultiplier(170.0);
      expect(highStyle.bg, const Color(0xFFEF4444));

      final midStyle = PlinkoBucketStyle.fromMultiplier(33.0);
      expect(midStyle.bg, const Color(0xFFF97316));

      final lowStyle = PlinkoBucketStyle.fromMultiplier(0.2);
      expect(lowStyle.bg, const Color(0xFF334155));
    });

    test('Repository generates 12-tier paths within valid range', () {
      for (var i = 0; i < 50; i++) {
        final path = repository.generatePath();
        expect(path.length, 12);
        final bucketIndex = path.reduce((a, b) => a + b);
        expect(bucketIndex, inInclusiveRange(0, 12));
      }
    });

    testWidgets('ViewModel board initialization, peg counts, and ball dropping', (tester) async {
      await tester.pumpWidget(
        TickerMode(
          enabled: true,
          child: Builder(
            builder: (context) => const SizedBox(),
          ),
        ),
      );

      final vsync = tester;
      final vm = PlinkoGameViewModel(repository: repository, vsync: vsync);

      // Verify peg pyramid geometry
      // Row 0 has 3 pegs, ..., Row 11 has 14 pegs => sum(3..14) = 102 pegs
      expect(vm.pegs.length, 102);
      expect(vm.buckets.length, 13);
      expect(vm.activeBallsCount, 0);

      final initialTon = vm.tonBalance;
      vm.setCurrency(PlinkoCurrency.ton);
      vm.setBetAmount(0.2);

      // Drop first ball
      vm.dropBall();
      expect(vm.balls.length, 1);
      expect(vm.activeBallsCount, 1);
      expect(vm.tonBalance, initialTon - 0.2);

      // Drop second ball (concurrent in-flight simulation)
      vm.dropBall();
      expect(vm.balls.length, 2);
      expect(vm.activeBallsCount, 2);
      expect(vm.tonBalance, initialTon - 0.4);

      // Advance frames
      await tester.pump(const Duration(milliseconds: 300));
      expect(vm.balls.first.wpIdx, greaterThan(0));

      vm.dispose();
    });
  });
}

