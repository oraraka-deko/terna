import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terna/services/upgrade_game/upgrade_gifts_repository.dart';
import 'package:terna/features/upgrade_game/view_models/upgrade_game_view_model.dart';
import 'package:terna/services/wallet/wallet_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UpgradeGame Math and Inventory Tests', () {
    late UpgradeGiftsRepository repo;

    setUp(() {
      repo = UpgradeGiftsRepository();
    });

    test('User inventory uses shared wallet balances and has no demo gifts', () async {
      final inventory = await repo.loadUserInventory();

      expect(inventory.isPlaceholder, isFalse);
      expect(inventory.tonBalance, equals(WalletRepository().tonBalance.value));
      expect(inventory.starsBalance, equals(WalletRepository().starsBalance.value));
      expect(inventory.gifts, isEmpty);
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

      expect(vm.inventory.isPlaceholder, isFalse);
      expect(vm.inventory.tonBalance, WalletRepository().tonBalance.value);
      expect(vm.inventory.starsBalance, WalletRepository().starsBalance.value);
      expect(vm.selectedTargetGift, isNotNull);

      // Initially no bet placed
      expect(vm.totalBetValue, 0.0);
      expect(vm.winChancePercent, 0.0);
      expect(vm.isValidTarget, isFalse);

      // Additional Stars stake works without a fabricated inventory item.
      vm.setAdditionalStars(10);
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
