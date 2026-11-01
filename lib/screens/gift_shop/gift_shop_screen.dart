import 'package:flutter/material.dart';
import '../../features/gift_shop/view_models/gift_shop_view_model.dart';
import '../../models/gift_shop/gift_shop_models.dart';
import '../../widgets/gift_shop/gift_shop_header_widget.dart';
import '../../widgets/gift_shop/gift_shop_play_banner_widget.dart';
import '../../widgets/gift_shop/gift_shop_category_tabs_widget.dart';
import '../../widgets/gift_shop/gift_shop_search_toolbar_widget.dart';
import '../../widgets/gift_shop/gift_shop_filter_chips_widget.dart';
import '../../widgets/gift_shop/gift_shop_grid_widget.dart';
import '../../widgets/gift_shop/gift_shop_bottom_nav_widget.dart';
import '../../widgets/gift_shop/gift_shop_collection_sheet.dart';
import '../../widgets/gift_shop/gift_shop_details_modal.dart';
import '../../widgets/gift_shop/gift_shop_my_gifts_widget.dart';

/// Main screen for the Gift Shop App Item.
/// Features high modularity with independent layer widgets, responsive layout,
/// animated Lottie .tgs Telegram gifts, and interactive collection filtering.
class GiftShopScreen extends StatefulWidget {
  const GiftShopScreen({super.key});

  @override
  State<GiftShopScreen> createState() => _GiftShopScreenState();
}

class _GiftShopScreenState extends State<GiftShopScreen> {
  late final GiftShopViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = GiftShopViewModel();
    _viewModel.init();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _openCollectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return GiftShopCollectionSheet(
          collections: _viewModel.collections,
          initialSelectedId: _viewModel.filterState.selectedCollectionId,
          onSelectCollection: (colId) {
            _viewModel.selectCollection(colId);
          },
          onClearAll: () {
            _viewModel.clearAllFilters();
          },
        );
      },
    );
  }

  void _openDetailsModal(GiftShopItem item) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) {
        return GiftShopDetailsModal(
          item: item,
          currentCurrency: _viewModel.filterState.currency,
          onBuy: (selectedItem) {
            _handlePurchase(selectedItem);
          },
        );
      },
    );
  }

  void _handlePurchase(GiftShopItem item) {
    final success = _viewModel.purchaseGift(item);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF4ADE80)),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Purchased ${item.name} (${item.editionNumber})! Added to My Gifts.'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1E293B),
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFF87171)),
              const SizedBox(width: 8),
              Text(
                'Insufficient ${_viewModel.filterState.currency == GiftShopCurrency.stars ? "Stars" : "GRAM"} balance!',
              ),
            ],
          ),
          backgroundColor: const Color(0xFF7F1D1D),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        final activeCollection = _viewModel.filterState.selectedCollectionId != null
            ? _viewModel.collections
                .firstWhere(
                  (c) => c.id == _viewModel.filterState.selectedCollectionId,
                  orElse: () => _viewModel.collections.first,
                )
                .name
            : null;

        return Scaffold(
          backgroundColor: const Color(0xFF0C0E14),
          body: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                // Main Content Body
                Column(
                  children: [
                    // Header Bar with Balance Pills
                    GiftShopHeaderWidget(
                      inventory: _viewModel.userInventory,
                      onBack: () => Navigator.of(context).maybePop(),
                    ),

                    // Active Tab Screen Content
                    Expanded(
                      child: _viewModel.isLoading
                          ? const Center(
                              child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
                            )
                          : _viewModel.selectedBottomNavIndex == 2
                              ? GiftShopMyGiftsWidget(
                                  inventory: _viewModel.userInventory,
                                  onGiftTap: _openDetailsModal,
                                )
                              : _buildStoreView(activeCollection),
                    ),
                  ],
                ),

                // Floating Frosted Glass Bottom Navigation Bar
                GiftShopBottomNavWidget(
                  selectedIndex: _viewModel.selectedBottomNavIndex,
                  onItemSelected: (index) {
                    if (index == 0) {
                      // Games tab: returns back to App Drawer or game menu
                      Navigator.of(context).maybePop();
                    } else if (index == 3) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Halloween Spooky Gifts event starts soon!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    } else {
                      _viewModel.setBottomNavIndex(index);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStoreView(String? activeCollection) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "Play With" Currency Switcher Banner
          GiftShopPlayBannerWidget(
            currentCurrency: _viewModel.filterState.currency,
            onCurrencyChanged: _viewModel.setCurrency,
          ),

          // Sub-navigation Category Tabs (All, Collections, Stars, Craft)
          GiftShopCategoryTabsWidget(
            activeCategory: _viewModel.filterState.category,
            onCategorySelected: _viewModel.setCategory,
            onOpenCollectionsModal: _openCollectionSheet,
          ),

          // "Quick find" Search and Quick Actions
          GiftShopSearchToolbarWidget(
            searchQuery: _viewModel.filterState.searchQuery,
            onSearchChanged: _viewModel.setSearchQuery,
            viewMode: _viewModel.filterState.viewMode,
            onToggleViewMode: _viewModel.toggleViewMode,
            onToggleTrends: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Live 24h market volume charts'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),

          // Filter Chips Row (Funnel, Sort, Collection ˅, Model ˅, etc.)
          GiftShopFilterChipsWidget(
            filterState: _viewModel.filterState,
            onOpenCollectionSheet: _openCollectionSheet,
            onToggleSort: _viewModel.toggleSort,
            onClearFilters: _viewModel.clearAllFilters,
            activeCollectionName: activeCollection,
          ),

          // Gifts Grid / List with Promo Card
          GiftShopGridWidget(
            items: _viewModel.filteredItems,
            currentCurrency: _viewModel.filterState.currency,
            viewMode: _viewModel.filterState.viewMode,
            onBuy: _handlePurchase,
            onDetails: _openDetailsModal,
            onResetFilters: _viewModel.clearAllFilters,
          ),
        ],
      ),
    );
  }
}

