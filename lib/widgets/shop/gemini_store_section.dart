library;

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/inventory/inventory_models.dart';
import '../../models/shop/shop_models.dart';
import '../../services/haptic.dart';
import '../../services/inventory/inventory_repository.dart';
import '../../services/shop/shop_repository.dart';
import '../../services/wallet/wallet_repository.dart';

class GeminiStoreSection extends StatefulWidget {
  const GeminiStoreSection({super.key});

  @override
  State<GeminiStoreSection> createState() => _GeminiStoreSectionState();
}

class _GeminiStoreSectionState extends State<GeminiStoreSection> {
  final _shopRepo = ShopRepository();
  final _wallet = WalletRepository();
  final _inventory = InventoryRepository();

  String _selectedCategory = 'ALL';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'ALL',
    'AI Tools',
    'Dev & Cloud',
    'Media & Entertainment',
    'Utilities',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DigitalProductItem> get _filteredProducts {
    final all = _shopRepo.getDigitalProducts();
    return all.where((p) {
      final matchesCategory = _selectedCategory == 'ALL' || p.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.description.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _openPlanPicker(DigitalProductItem product) {
    HapticFeedbackService.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ProductPurchaseSheet(
        product: product,
        wallet: _wallet,
        inventory: _inventory,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = _filteredProducts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Toolbar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF131722),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search AI subscriptions, licenses, keys...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 18),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val.trim());
              },
            ),
          ),
        ),

        // Categories Filter Chips
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length,
            itemBuilder: (ctx, idx) {
              final cat = _categories[idx];
              final isSelected = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(
                    cat,
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: const Color(0xFF2DD4BF),
                  backgroundColor: const Color(0xFF131722),
                  side: BorderSide(color: isSelected ? const Color(0xFF2DD4BF) : Colors.white12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  showCheckmark: false,
                  onSelected: (_) {
                    setState(() => _selectedCategory = cat);
                  },
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        // Digital Products Grid
        if (products.isEmpty)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Center(
              child: Text(
                'No digital products found for this query.',
                style: TextStyle(color: Colors.white38),
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: products.length,
            itemBuilder: (ctx, idx) {
              final product = products[idx];
              return _buildProductCard(product);
            },
          ),
      ],
    );
  }

  Widget _buildProductCard(DigitalProductItem product) {
    final defaultPlan = product.defaultPlan;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF10141E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poster Header with Tag
          Expanded(
            flex: 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  product.posterAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: const Color(0xFF1E2433),
                    child: const Icon(Icons.code_rounded, color: Colors.white24, size: 40),
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Color(0xFF10141E)],
                      begin: Alignment.center,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                if (product.releaseTag != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2DD4BF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        product.releaseTag!,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Content info
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        product.category,
                        style: const TextStyle(color: Colors.white54, fontSize: 10),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'from ${defaultPlan.priceTon} TON',
                            style: const TextStyle(
                              color: Color(0xFF2DD4BF),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${defaultPlan.priceStars} Stars',
                            style: const TextStyle(color: Color(0xFFFFB800), fontSize: 10),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () => _openPlanPicker(product),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2DD4BF),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                          minimumSize: const Size(40, 30),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Get', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Modal Sheet for choosing subscription tier and currency
class _ProductPurchaseSheet extends StatefulWidget {
  final DigitalProductItem product;
  final WalletRepository wallet;
  final InventoryRepository inventory;

  const _ProductPurchaseSheet({
    required this.product,
    required this.wallet,
    required this.inventory,
  });

  @override
  State<_ProductPurchaseSheet> createState() => _ProductPurchaseSheetState();
}

class _ProductPurchaseSheetState extends State<_ProductPurchaseSheet> {
  late DigitalProductPlan _selectedPlan;
  String _currency = 'TON'; // 'TON' or 'STARS'
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _selectedPlan = widget.product.defaultPlan;
  }

  bool get _canAfford {
    if (_currency == 'TON') {
      return widget.wallet.tonBalance.value >= _selectedPlan.priceTon;
    } else {
      return widget.wallet.starsBalance.value >= _selectedPlan.priceStars;
    }
  }

  Future<void> _executePurchase() async {
    if (!_canAfford) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient $_currency balance! Please deposit to purchase.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);
    HapticFeedbackService.mediumImpact();

    await Future.delayed(const Duration(milliseconds: 700));

    // Debit wallet
    if (_currency == 'TON') {
      widget.wallet.debitTon(_selectedPlan.priceTon, 'Purchased ${widget.product.name} (${_selectedPlan.name})');
    } else {
      widget.wallet.debitStars(_selectedPlan.priceStars, 'Purchased ${widget.product.name} (${_selectedPlan.name})');
    }

    // Generate credentials
    final key = 'KEY-${widget.product.serviceId.toUpperCase()}-${Random().nextInt(8999) + 1000}-${Random().nextInt(8999) + 1000}';
    final login = 'terna.${widget.product.serviceId}@reseller.com';
    final pass = 'Pass#${Random().nextInt(89999) + 10000}';

    final newItem = InventoryItem(
      instanceId: 'sub_${DateTime.now().millisecondsSinceEpoch}',
      giftId: widget.product.serviceId,
      name: '${widget.product.name} (${_selectedPlan.name})',
      priceStars: _selectedPlan.priceStars,
      floorTon: _selectedPlan.priceTon,
      isDigital: true,
      acquiredAt: DateTime.now(),
      status: 'ACTIVE',
      posterAsset: widget.product.posterAsset,
      licenseKey: key,
      accountLogin: login,
      accountPassword: pass,
      instructions: '1. Access service portal\n2. Sign in with credentials\n3. Enjoy your licensed access!',
    );

    widget.inventory.addItem(newItem);

    if (!mounted) return;
    Navigator.pop(context); // Close sheet

    _showDeliveredDialog(newItem);
  }

  void _showDeliveredDialog(InventoryItem item) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131722),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF2DD4BF), width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF2DD4BF), size: 28),
            SizedBox(width: 10),
            Text('DELIVERY INSTANT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your digital subscription for ${item.name} is activated and stored in your Inventory.',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 14),
            _buildCredentialRow('License Key', item.licenseKey ?? 'N/A'),
            const SizedBox(height: 8),
            _buildCredentialRow('Account Login', item.accountLogin ?? 'N/A'),
            const SizedBox(height: 8),
            _buildCredentialRow('Account Password', item.accountPassword ?? 'N/A'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2DD4BF),
              foregroundColor: Colors.black,
            ),
            child: const Text('View in Inventory', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0D14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, color: Color(0xFF2DD4BF), size: 16),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              HapticFeedbackService.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Copied $label!'), duration: const Duration(seconds: 1)),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF0F141F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Color(0xFF2DD4BF), width: 1.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  widget.product.posterAsset,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Icon(Icons.code, size: 50, color: Colors.white),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      widget.product.category,
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white54),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Select Plan Duration', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          // Plan choices
          ...widget.product.plans.map((p) {
            final isSelected = _selectedPlan.planId == p.planId;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF2DD4BF).withValues(alpha: 0.12) : const Color(0xFF161C2A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? const Color(0xFF2DD4BF) : Colors.white12,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: ListTile(
                dense: true,
                onTap: () => setState(() => _selectedPlan = p),
                title: Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text(
                  _currency == 'TON' ? '${p.priceTon} TON' : '${p.priceStars} Stars',
                  style: TextStyle(
                    color: _currency == 'TON' ? const Color(0xFF2DD4BF) : const Color(0xFFFFB800),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle_rounded, color: Color(0xFF2DD4BF))
                    : const Icon(Icons.circle_outlined, color: Colors.white24),
              ),
            );
          }),

          const SizedBox(height: 12),
          const Text('Payment Currency', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('TON Wallet')),
                  selected: _currency == 'TON',
                  selectedColor: const Color(0xFF0098EA).withValues(alpha: 0.25),
                  backgroundColor: const Color(0xFF161C2A),
                  labelStyle: TextStyle(
                    color: _currency == 'TON' ? const Color(0xFF0098EA) : Colors.white60,
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: (_) => setState(() => _currency = 'TON'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Stars Balance')),
                  selected: _currency == 'STARS',
                  selectedColor: const Color(0xFFFFB800).withValues(alpha: 0.25),
                  backgroundColor: const Color(0xFF161C2A),
                  labelStyle: TextStyle(
                    color: _currency == 'STARS' ? const Color(0xFFFFB800) : Colors.white60,
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: (_) => setState(() => _currency = 'STARS'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Total & Buy button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _executePurchase,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2DD4BF),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isProcessing
                  ? const CircularProgressIndicator(color: Colors.black)
                  : Text(
                      'BUY NOW FOR ${_currency == 'TON' ? '${_selectedPlan.priceTon} TON' : '${_selectedPlan.priceStars} STARS'}',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
