import 'package:flutter/material.dart';

import '../../../services/api/gateway_api_service.dart';
import '../../../models/gift_shop/gift_shop_models.dart';
import '../../../services/gift_shop/gift_shop_repository.dart';
import '../../../services/gift_shop/gift_shop_audio_service.dart';
import '../../../services/wallet/wallet_repository.dart';

/// ViewModel managing state, filtering, and interactions for the Gift Shop.
class GiftShopViewModel extends ChangeNotifier {
  final GiftShopRepository _repository;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<GiftShopItem> _catalog = [];
  List<GiftShopItem> get catalog => _catalog;

  List<GiftCollection> _collections = [];
  List<GiftCollection> get collections => _collections;

  GiftShopFilterState _filterState = const GiftShopFilterState();
  GiftShopFilterState get filterState => _filterState;

  GiftShopUserInventory _userInventory = const GiftShopUserInventory(
    starsBalance: 0,
    tonBalance: 0,
    isPlaceholder: false,
  );
  GiftShopUserInventory get userInventory => _userInventory;
  bool _isPurchasing = false;
  bool get isPurchasing => _isPurchasing;
  String? _purchaseError;
  String? get purchaseError => _purchaseError;

  int _selectedBottomNavIndex = 1; // 1 = Store
  int get selectedBottomNavIndex => _selectedBottomNavIndex;

  GiftShopViewModel({GiftShopRepository? repository})
    : _repository = repository ?? GiftShopRepository();

  /// Initialize the catalog and load wallet-backed balances and inventory.
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prices = await GatewayApiService().getShopPrices();
      final starsPriceUsd = (prices['starsPriceUsd'] as num?)?.toDouble();
      final tonPriceUsd = (prices['tonPriceUsd'] as num?)?.toDouble();
      if (starsPriceUsd == null ||
          starsPriceUsd <= 0 ||
          tonPriceUsd == null ||
          tonPriceUsd <= 0) {
        throw StateError('The shop did not return valid currency prices.');
      }

      _catalog = await _repository.loadCatalog(
        starsPriceUsd: starsPriceUsd,
        tonPriceUsd: tonPriceUsd,
      );
      _collections = _repository.getCollections();
      await _refreshWalletAndInventory();
    } catch (_) {
      _purchaseError = 'Unable to load your wallet-backed gift inventory.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Filtered items computed based on search query, category, collection, and sort
  List<GiftShopItem> get filteredItems {
    var items = List<GiftShopItem>.from(_catalog);

    // Filter by Category
    switch (_filterState.category) {
      case GiftShopCategory.all:
        break;
      case GiftShopCategory.collections:
        // When in collections mode, show high-tier collection gifts
        items = items.where((i) => i.backdropCount > 1).toList();
        break;
      case GiftShopCategory.stars:
        // Stars focus: gifts priced moderately in stars
        items = items.where((i) => i.priceStars <= 100).toList();
        break;
      case GiftShopCategory.craft:
        // Craft focus: upgradeable items
        items = items.where((i) => i.isUpgradeable).toList();
        break;
    }

    // Filter by Search Query
    if (_filterState.searchQuery.trim().isNotEmpty) {
      final q = _filterState.searchQuery.trim().toLowerCase();
      items = items.where((i) {
        return i.name.toLowerCase().contains(q) ||
            i.editionNumber.toLowerCase().contains(q) ||
            i.sampleModelNames.any((m) => m.toLowerCase().contains(q));
      }).toList();
    }

    // Filter by Selected Collection
    if (_filterState.selectedCollectionId != null &&
        _filterState.selectedCollectionId!.isNotEmpty) {
      final collection = _collections.firstWhere(
        (c) => c.id == _filterState.selectedCollectionId,
        orElse: () => _collections.first,
      );
      items = items.where((i) {
        return i.name.toLowerCase().contains(collection.name.toLowerCase()) ||
            collection.name.toLowerCase().contains(i.name.toLowerCase());
      }).toList();
    }

    // Sort items
    switch (_filterState.sortBy) {
      case GiftShopSortBy.priceAsc:
        items.sort(
          (a, b) => _filterState.currency == GiftShopCurrency.stars
              ? a.priceStars.compareTo(b.priceStars)
              : a.priceTon.compareTo(b.priceTon),
        );
        break;
      case GiftShopSortBy.priceDesc:
        items.sort(
          (a, b) => _filterState.currency == GiftShopCurrency.stars
              ? b.priceStars.compareTo(a.priceStars)
              : b.priceTon.compareTo(a.priceTon),
        );
        break;
      case GiftShopSortBy.popular:
        items.sort((a, b) => b.modelCount.compareTo(a.modelCount));
        break;
      case GiftShopSortBy.name:
        items.sort((a, b) => a.name.compareTo(b.name));
        break;
    }

    return items;
  }

  /// Toggle Currency Mode between Stars and TON
  void setCurrency(GiftShopCurrency currency) {
    if (_filterState.currency == currency) return;
    GiftShopAudioService.playTap();
    _filterState = _filterState.copyWith(currency: currency);
    notifyListeners();
  }

  /// Change Category Tab
  void setCategory(GiftShopCategory category) {
    if (_filterState.category == category) return;
    GiftShopAudioService.playSwitchTab();
    _filterState = _filterState.copyWith(category: category);
    notifyListeners();
  }

  /// Update search text
  void setSearchQuery(String query) {
    _filterState = _filterState.copyWith(searchQuery: query);
    notifyListeners();
  }

  /// Select a collection from the Collection Filter Sheet
  void selectCollection(String? collectionId) {
    GiftShopAudioService.playTap();
    _filterState = _filterState.copyWith(
      selectedCollectionId: collectionId,
      clearCollection: collectionId == null,
    );
    notifyListeners();
  }

  /// Clear all applied filters
  void clearAllFilters() {
    GiftShopAudioService.playTap();
    _filterState = const GiftShopFilterState();
    notifyListeners();
  }

  /// Toggle sorting mode
  void toggleSort() {
    GiftShopAudioService.playTap();
    final nextSort = switch (_filterState.sortBy) {
      GiftShopSortBy.popular => GiftShopSortBy.priceAsc,
      GiftShopSortBy.priceAsc => GiftShopSortBy.priceDesc,
      GiftShopSortBy.priceDesc => GiftShopSortBy.name,
      GiftShopSortBy.name => GiftShopSortBy.popular,
    };
    _filterState = _filterState.copyWith(sortBy: nextSort);
    notifyListeners();
  }

  /// Cycle view layout mode (grid2 -> grid3 -> list)
  void toggleViewMode() {
    GiftShopAudioService.playTap();
    final nextMode = switch (_filterState.viewMode) {
      GiftShopViewMode.grid2 => GiftShopViewMode.grid3,
      GiftShopViewMode.grid3 => GiftShopViewMode.list,
      GiftShopViewMode.list => GiftShopViewMode.grid2,
    };
    _filterState = _filterState.copyWith(viewMode: nextMode);
    notifyListeners();
  }

  /// Switch bottom navigation item
  void setBottomNavIndex(int index) {
    if (_selectedBottomNavIndex == index) return;
    GiftShopAudioService.playSwitchTab();
    _selectedBottomNavIndex = index;
    notifyListeners();
  }

  Future<bool> purchaseGift(GiftShopItem item) async {
    if (_isPurchasing) return false;

    final currency = _filterState.currency == GiftShopCurrency.stars
        ? 'stars'
        : 'ton';
    final balance = currency == 'stars'
        ? WalletRepository().starsBalance.value.toDouble()
        : WalletRepository().tonBalance.value;
    final amount = currency == 'stars'
        ? item.priceStars.toDouble()
        : item.priceTon;
    if (balance < amount) {
      _purchaseError =
          'Insufficient ${currency == 'stars' ? 'Stars' : 'TON'} balance.';
      notifyListeners();
      return false;
    }

    _isPurchasing = true;
    _purchaseError = null;
    notifyListeners();
    try {
      final api = GatewayApiService();
      final response = await api.purchaseShopGift(
        giftId: item.giftId,
        currency: currency,
      );
      final gift = response['gift'];
      if (response['success'] != true ||
          gift is! Map<String, dynamic> ||
          gift['id'] is! String ||
          gift['giftId'] != item.giftId) {
        throw StateError(
          response['error']?.toString() ??
              'The backend did not confirm the gift purchase.',
        );
      }

      final wallet = response['wallet'];
      if (wallet is! Map<String, dynamic> ||
          wallet['tonBalance'] is! num ||
          wallet['starsBalance'] is! num) {
        throw StateError(
          'The backend did not return the updated wallet balances.',
        );
      }
      WalletRepository().tonBalance.value = (wallet['tonBalance'] as num)
          .toDouble();
      WalletRepository().starsBalance.value = (wallet['starsBalance'] as num)
          .toInt();
      _userInventory = _userInventory.copyWith(
        tonBalance: WalletRepository().tonBalance.value,
        starsBalance: WalletRepository().starsBalance.value,
        ownedGifts: [..._userInventory.ownedGifts, item],
        isPlaceholder: false,
      );

      GiftShopAudioService.playCoin();
      return true;
    } catch (error) {
      _purchaseError = error.toString();
      return false;
    } finally {
      _isPurchasing = false;
      notifyListeners();
    }
  }

  Future<void> _refreshWalletAndInventory() async {
    final wallet = WalletRepository();
    await wallet.refreshBalances();
    final rawInventory = await GatewayApiService().getUserInventory();
    final catalogById = {for (final item in _catalog) item.giftId: item};
    final owned = <GiftShopItem>[];
    for (final raw in rawInventory) {
      if (raw is! Map<String, dynamic>) continue;
      final giftId = raw['giftId']?.toString();
      final catalogItem = catalogById[giftId];
      if (catalogItem == null) continue;
      owned.add(catalogItem);
    }

    _userInventory = GiftShopUserInventory(
      starsBalance: wallet.starsBalance.value,
      tonBalance: wallet.tonBalance.value,
      ownedGifts: owned,
      isPlaceholder: false,
    );
  }
}
