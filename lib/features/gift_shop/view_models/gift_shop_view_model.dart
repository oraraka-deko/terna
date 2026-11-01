import 'package:flutter/material.dart';
import '../../../models/gift_shop/gift_shop_models.dart';
import '../../../services/gift_shop/gift_shop_repository.dart';
import '../../../services/gift_shop/gift_shop_audio_service.dart';

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
    starsBalance: 100, // PLACEHOLDER: 100 Stars demo
    tonBalance: 10.0, // PLACEHOLDER: 10 TON demo
    gramBalance: 10.0, // PLACEHOLDER: 10 GRAM demo
    isPlaceholder: true, // PLACEHOLDER
  );
  GiftShopUserInventory get userInventory => _userInventory;

  int _selectedBottomNavIndex = 1; // 1 = Store
  int get selectedBottomNavIndex => _selectedBottomNavIndex;

  GiftShopViewModel({GiftShopRepository? repository})
      : _repository = repository ?? GiftShopRepository();

  /// Initialize and load catalog, collections, and initial demo inventory
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      _catalog = await _repository.loadCatalog();
      _collections = _repository.getCollections();
      _userInventory = await _repository.loadInitialPlaceholderInventory();
    } catch (_) {
      // Fallback already provided in repository
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
        items.sort((a, b) => _filterState.currency == GiftShopCurrency.stars
            ? a.priceStars.compareTo(b.priceStars)
            : a.priceGram.compareTo(b.priceGram));
        break;
      case GiftShopSortBy.priceDesc:
        items.sort((a, b) => _filterState.currency == GiftShopCurrency.stars
            ? b.priceStars.compareTo(a.priceStars)
            : b.priceGram.compareTo(a.priceGram));
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

  /// Toggle Currency Mode between Stars and GRAM
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

  /// Purchase gift item simulation
  bool purchaseGift(GiftShopItem item) {
    if (_filterState.currency == GiftShopCurrency.stars) {
      if (_userInventory.starsBalance < item.priceStars) {
        return false;
      }
      final updatedOwned = List<GiftShopItem>.from(_userInventory.ownedGifts)..add(item);
      _userInventory = _userInventory.copyWith(
        starsBalance: _userInventory.starsBalance - item.priceStars,
        ownedGifts: updatedOwned,
      );
    } else {
      if (_userInventory.gramBalance < item.priceGram) {
        return false;
      }
      final updatedOwned = List<GiftShopItem>.from(_userInventory.ownedGifts)..add(item);
      _userInventory = _userInventory.copyWith(
        gramBalance: double.parse((_userInventory.gramBalance - item.priceGram).toStringAsFixed(2)),
        ownedGifts: updatedOwned,
      );
    }

    GiftShopAudioService.playCoin();
    notifyListeners();
    return true;
  }
}

