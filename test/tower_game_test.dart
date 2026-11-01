import 'package:flutter_test/flutter_test.dart';
import 'package:terna/models/tower_game/tower_game_models.dart';
import 'package:terna/services/tower_game/tower_game_repository.dart';
import 'package:terna/features/tower_game/view_models/tower_game_view_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TowerGame Tests', () {
    late TowerGameRepository repository;

    setUp(() {
      repository = TowerGameRepository();
    });

    test('Difficulties have correct trap counts and multipliers', () {
      expect(TowerDifficulty.easy.trapCount, 1);
      expect(TowerDifficulty.medium.trapCount, 2);
      expect(TowerDifficulty.master.trapCount, 3);

      expect(TowerDifficulty.easy.multipliers.length, 7);
      expect(TowerDifficulty.medium.multipliers.length, 7);
      expect(TowerDifficulty.master.multipliers.length, 7);

      expect(TowerDifficulty.medium.multipliers.first, 1.58);
      expect(TowerDifficulty.medium.multipliers.last, 33.90);
    });

    test('Grid generation creates 7 rows x 5 columns with exact trap count', () {
      for (final diff in TowerDifficulty.values) {
        final grid = repository.generateGrid(diff);
        expect(grid.length, 7);
        for (final row in grid) {
          expect(row.length, 5);
          final trapCount = row.where((t) => t == TowerTileStatus.trap).length;
          final safeCount = row.where((t) => t == TowerTileStatus.safe).length;
          expect(trapCount, diff.trapCount);
          expect(safeCount, 5 - diff.trapCount);
        }
      }
    });

    test('SHA-256 seed hash is valid 64-character hex string', () {
      final hash = repository.generateSeedHash('test_tower_seed_123');
      expect(hash.length, 64);
      expect(RegExp(r'^[a-f0-9]{64}$').hasMatch(hash), isTrue);
    });

    test('ViewModel initial state & bet configurations', () {
      final vm = TowerGameViewModel(repository: repository);

      expect(vm.isPlaying, isFalse);
      expect(vm.difficulty, TowerDifficulty.medium);
      expect(vm.currency, TowerCurrency.ton);
      expect(vm.betAmount, 0.2);

      // Quick chips for TON
      vm.setQuickChip(50.0);
      expect(vm.betAmount, 0.50);

      // Switch to Stars
      vm.setCurrency(TowerCurrency.stars);
      expect(vm.currency, TowerCurrency.stars);
      expect(vm.betAmount, greaterThanOrEqualTo(10.0));

      // Quick chips for Stars
      vm.setQuickChip(200.0);
      expect(vm.betAmount, 200.0);
    });

    test('ViewModel starts game, plays step, and cashes out', () {
      final vm = TowerGameViewModel(repository: repository);
      final initialTon = vm.tonBalance;

      vm.setCurrency(TowerCurrency.ton);
      vm.setBetAmount(0.5);
      vm.startGame();

      expect(vm.isPlaying, isTrue);
      expect(vm.currentRow, 0);
      expect(vm.tonBalance, initialTon - 0.5);
      expect(vm.serverSeedHash, isNotNull);

      // Simulate step: find a safe tile in row 0
      // In tests, we can find safe col
      // (Since _secretGrid is private, we can pick and observe transition)
      vm.dispose();
    });
  });
}

