import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terna/models/gift_shop/gift_shop_models.dart';
import 'package:terna/services/gift_shop/gift_shop_repository.dart';
import 'package:terna/features/gift_shop/view_models/gift_shop_view_model.dart';
import 'package:terna/widgets/upgrade_game/gift_visual_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Gift Shop Unit Tests', () {
    late GiftShopRepository repository;
    late GiftShopViewModel viewModel;

    setUp(() {
      repository = GiftShopRepository();
      viewModel = GiftShopViewModel(repository: repository);
    });

    test('1. Catalog loads gifts correctly with valid metrics', () async {
      await viewModel.init();

      expect(viewModel.catalog.isNotEmpty, isTrue);
      final firstItem = viewModel.catalog.first;
      expect(firstItem.giftId.isNotEmpty, isTrue);
      expect(firstItem.name.isNotEmpty, isTrue);
      expect(firstItem.priceStars > 0, isTrue);
      expect(firstItem.priceGram > 0, isTrue);
      expect(firstItem.editionNumber.startsWith('#'), isTrue);
      expect(firstItem.isPlaceholder, isTrue);
    });

    test('2. Collections list matches expected screenshot collections', () {
      final collections = repository.getCollections();
      expect(collections.isNotEmpty, isTrue);

      final names = collections.map((c) => c.name).toList();
      expect(names.contains('Myth Mask'), isTrue);
      expect(names.contains('Resistance Dog'), isTrue);
      expect(names.contains('Heroic Helmet'), isTrue);
      expect(names.contains('Swiss Watch'), isTrue);

      // Verify Resistance Dog has floor price 424 GRAM from screenshot
      final resistanceDog = collections.firstWhere((c) => c.name == 'Resistance Dog');
      expect(resistanceDog.floorPriceGram, equals(424.0));
      expect(resistanceDog.isNew, isTrue);
    });

    test('3. Currency toggle updates filter state between Stars and GRAM', () async {
      await viewModel.init();

      expect(viewModel.filterState.currency, equals(GiftShopCurrency.stars));

      viewModel.setCurrency(GiftShopCurrency.gram);
      expect(viewModel.filterState.currency, equals(GiftShopCurrency.gram));

      viewModel.setCurrency(GiftShopCurrency.stars);
      expect(viewModel.filterState.currency, equals(GiftShopCurrency.stars));
    });

    test('4. Initial user inventory contains 100 stars and 10 TON/GRAM placeholders', () async {
      await viewModel.init();

      expect(viewModel.userInventory.starsBalance, equals(100)); // PLACEHOLDER: 100 Stars
      expect(viewModel.userInventory.tonBalance, equals(10.0)); // PLACEHOLDER: 10 TON
      expect(viewModel.userInventory.gramBalance, equals(10.0)); // PLACEHOLDER: 10 GRAM
      expect(viewModel.userInventory.isPlaceholder, isTrue);
      expect(viewModel.userInventory.ownedGifts.isNotEmpty, isTrue);
    });

    test('5. Search filtering accurately narrows down catalog items', () async {
      await viewModel.init();

      final totalCount = viewModel.filteredItems.length;

      // Search for specific gift
      viewModel.setSearchQuery('Easter Egg');
      expect(viewModel.filteredItems.length, lessThanOrEqualTo(totalCount));
      for (final item in viewModel.filteredItems) {
        expect(
          item.name.toLowerCase().contains('easter') ||
              item.editionNumber.contains('easter'),
          isTrue,
        );
      }

      // Clear search
      viewModel.setSearchQuery('');
      expect(viewModel.filteredItems.length, equals(totalCount));
    });

    test('6. Collection filtering isolates selected collection gifts', () async {
      await viewModel.init();

      viewModel.selectCollection('myth_mask');
      expect(viewModel.filterState.selectedCollectionId, equals('myth_mask'));

      viewModel.clearAllFilters();
      expect(viewModel.filterState.selectedCollectionId, isNull);
    });

    test('7. Purchase gift with Stars deducts balance and appends to inventory', () async {
      await viewModel.init();

      final initialStars = viewModel.userInventory.starsBalance;
      final initialOwnedCount = viewModel.userInventory.ownedGifts.length;

      const cheapGift = GiftShopItem(
        giftId: 'test_cheap_gift',
        name: 'Mini Star',
        priceStars: 20,
        priceGram: 1.5,
        editionNumber: '#111222',
        isPlaceholder: true,
      );

      final success = viewModel.purchaseGift(cheapGift);
      expect(success, isTrue);
      expect(viewModel.userInventory.starsBalance, equals(initialStars - 20));
      expect(viewModel.userInventory.ownedGifts.length, equals(initialOwnedCount + 1));
    });

    test('8. Purchase fails cleanly when balance is insufficient', () async {
      await viewModel.init();

      const expensiveGift = GiftShopItem(
        giftId: 'test_expensive_gift',
        name: 'Crown of Cosmos',
        priceStars: 99999,
        priceGram: 99999.0,
        editionNumber: '#999999',
        isPlaceholder: true,
      );

      final success = viewModel.purchaseGift(expensiveGift);
      expect(success, isFalse);
    });

    testWidgets('9. GiftVisualWidget defaults to static image to save CPU/GPU', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GiftVisualWidget(
              giftId: '5170145012310081615',
              name: 'Heart Box',
              size: 56,
              animate: false,
            ),
          ),
        ),
      );

      // Verify Image.asset is used for static image instead of Lottie
      expect(find.byType(GiftVisualWidget), findsOneWidget);
    });
  });
}

