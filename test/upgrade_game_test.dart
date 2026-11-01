import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terna/services/upgrade_game/upgrade_gifts_repository.dart';
import 'package:terna/features/upgrade_game/view_models/upgrade_game_view_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UpgradeGame Math and Inventory Tests', () {
    late UpgradeGiftsRepository repo;

    setUp(() {
      repo = UpgradeGiftsRepository();
    });

    test('Initial placeholder inventory contains all gifts, 10 TON, and 100 Stars', () async {
      final inventory = await repo.loadInitialPlaceholderInventory();

      expect(inventory.isPlaceholder, isTrue);
      expect(inventory.tonBalance, equals(10.0));
      expect(inventory.starsBalance, equals(100));
      expect(inventory.gifts.isNotEmpty, isTrue);
      for (final g in inventory.gifts) {
        expect(g.isPlaceholder, isTrue);
      }
    });

    test('Rate conversions are accurate', () {
      // 100 stars to TON
      final tonVal = repo.starsToTon(100);
      expect(tonVal, greaterThan(0.8));

      // 1 TON to stars
      final starsVal = repo.tonToStars(1.0);
      expect(starsVal, greaterThan(100));
    });

    testWidgets('ViewModel calculations and wheel touch rotation', (tester) async {
      late UpgradeGameViewModel vm;

      await tester.pumpWidget(
        TickerMode(
          enabled: true,
          child: Builder(
            builder: (context) {
              return const SizedBox();
            },
          ),
        ),
      );

      final vsync = tester;
      vm = UpgradeGameViewModel(repository: repo, vsync: vsync);
      await vm.initialize();

      expect(vm.inventory.isPlaceholder, isTrue);
      expect(vm.inventory.tonBalance, 10.0);
      expect(vm.inventory.starsBalance, 100);
      expect(vm.selectedTargetGift, isNotNull);

      // Initially no bet placed
      expect(vm.totalBetValue, 0.0);
      expect(vm.winChancePercent, 0.0);
      expect(vm.isValidTarget, isFalse);

      // Select an inventory gift
      final gift = vm.inventory.gifts.first;
      vm.toggleInventoryGift(gift);
      expect(vm.selectedInventoryGifts.length, 1);
      expect(vm.totalBetValue, greaterThan(0.0));

      // With bet placed and target selected, win chance is calculated
      expect(vm.winChancePercent, greaterThan(0.0));
      expect(vm.winChancePercent, lessThanOrEqualTo(66.6));

      // Wheel touch rotation
      expect(vm.wheelRotation, 0.0);
      vm.onPointerDown(const Offset(140, 20), const Size(280, 280));
      vm.onPointerMove(const Offset(260, 140), const Size(280, 280));
      vm.onPointerUp();

      expect(vm.wheelRotation, isNot(0.0));

      vm.dispose();
    });
  });
}
