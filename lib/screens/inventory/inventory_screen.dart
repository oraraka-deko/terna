library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/inventory/inventory_models.dart';
import '../../services/haptic.dart';
import '../../services/inventory/inventory_repository.dart';
import '../shop/shop_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _inventoryRepo = InventoryRepository();

  InventoryFilter _selectedFilter = InventoryFilter.all;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<InventoryItem> _getFilteredItems(List<InventoryItem> allItems) {
    return allItems.where((item) {
      bool matchesFilter = true;
      if (_selectedFilter == InventoryFilter.digital) {
        matchesFilter = item.isDigital;
      } else if (_selectedFilter == InventoryFilter.gifts) {
        matchesFilter = !item.isDigital;
      } else if (_selectedFilter == InventoryFilter.nft) {
        matchesFilter = item.isCollectible;
      }

      final matchesSearch = _searchQuery.isEmpty ||
          item.name.toLowerCase().contains(_searchQuery.toLowerCase());

      return matchesFilter && matchesSearch;
    }).toList();
  }

  void _showCredentialsModal(InventoryItem item) {
    HapticFeedbackService.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    item.webpPath,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(Icons.vpn_key_rounded, size: 48, color: Color(0xFF2DD4BF)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      const Text('Active Digital Subscription', style: TextStyle(color: Color(0xFF10B981), fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white54),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (item.licenseKey != null) ...[
              _buildCredentialCard('License Key / Activation Code', item.licenseKey!),
              const SizedBox(height: 10),
            ],
            if (item.accountLogin != null) ...[
              _buildCredentialCard('Account Login Email', item.accountLogin!),
              const SizedBox(height: 10),
            ],
            if (item.accountPassword != null) ...[
              _buildCredentialCard('Account Password', item.accountPassword!),
              const SizedBox(height: 10),
            ],
            if (item.instructions != null) ...[
              const SizedBox(height: 4),
              const Text('Activation Instructions', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF090D15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white10),
                ),
                child: Text(
                  item.instructions!,
                  style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                ),
              ),
            ],

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2DD4BF),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCredentialCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF090D15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, color: Color(0xFF2DD4BF), size: 18),
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

  void _promptSellGift(InventoryItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF0F141F),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Color(0xFF2DD4BF), width: 1.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Sell Telegram Gift', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Liquidate ${item.name} directly into your wallet balance.', style: const TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _inventoryRepo.sellGift(instanceId: item.instanceId, currency: 'TON');
                      HapticFeedbackService.mediumImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Sold for ${item.floorTon} TON!'), backgroundColor: const Color(0xFF10B981)),
                      );
                    },
                    icon: const Icon(Icons.diamond_outlined, size: 16),
                    label: Text('Sell for ${item.floorTon} TON'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0098EA),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _inventoryRepo.sellGift(instanceId: item.instanceId, currency: 'STARS');
                      HapticFeedbackService.mediumImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Sold for ${item.priceStars} Stars!'), backgroundColor: const Color(0xFF10B981)),
                      );
                    },
                    icon: const Icon(Icons.star_rounded, size: 16),
                    label: Text('Sell for ${item.priceStars} Stars'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFB800),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _promptSellDigital(InventoryItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131722),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        title: const Text('Liquidate Digital License', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Liquidate "${item.name}" for 60% of its initial purchase price (+${item.digitalSellBackTon} TON)?\n\nYour license will be revoked from inventory.',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _inventoryRepo.sellDigital(item.instanceId);
              HapticFeedbackService.heavyImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✓ Liquidated for ${item.digitalSellBackTon} TON!'),
                  backgroundColor: const Color(0xFF10B981),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            child: const Text('Liquidate (60%)', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1420),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'INVENTORY & VAULT',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.storefront_rounded, color: Color(0xFF2DD4BF)),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ShopScreen()),
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<List<InventoryItem>>(
        valueListenable: _inventoryRepo.userItems,
        builder: (ctx, allItems, _) {
          final items = _getFilteredItems(allItems);

          return CustomScrollView(
            slivers: [
              // Valuation Header Banner
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF2DD4BF).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCol('Total Items', '${allItems.length}', Icons.inventory_2_outlined, const Color(0xFF2DD4BF)),
                        Container(width: 1, height: 36, color: Colors.white12),
                        _buildStatCol('Floor Value', '${_inventoryRepo.totalTonValue.toStringAsFixed(2)} TON', Icons.diamond_outlined, const Color(0xFF0098EA)),
                        Container(width: 1, height: 36, color: Colors.white12),
                        _buildStatCol('Stars Value', '${_inventoryRepo.totalStarsValue}', Icons.star_rounded, const Color(0xFFFFB800)),
                      ],
                    ),
                  ),
                ),
              ),

              // Search & Filter Toolbar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFF131722),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Search inventory items...',
                            hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                            prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38, size: 20),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onChanged: (val) => setState(() => _searchQuery = val.trim()),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildFilterChip('ALL', InventoryFilter.all),
                          const SizedBox(width: 8),
                          _buildFilterChip('DIGITAL', InventoryFilter.digital),
                          const SizedBox(width: 8),
                          _buildFilterChip('GIFTS', InventoryFilter.gifts),
                          const SizedBox(width: 8),
                          _buildFilterChip('NFT', InventoryFilter.nft),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 14)),

              // Items Grid / Empty State
              if (items.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 50, color: Colors.white24),
                          const SizedBox(height: 12),
                          const Text('No inventory items found', style: TextStyle(color: Colors.white54, fontSize: 14)),
                          const SizedBox(height: 14),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ShopScreen()));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2DD4BF),
                              foregroundColor: Colors.black,
                            ),
                            child: const Text('Explore Shop', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.70,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (ctx, idx) => _buildItemCard(items[idx]),
                      childCount: items.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCol(String title, String val, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        Text(title, style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ],
    );
  }

  Widget _buildFilterChip(String label, InventoryFilter filter) {
    final isSelected = _selectedFilter == filter;
    return Expanded(
      child: FilterChip(
        label: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white70,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        selected: isSelected,
        selectedColor: const Color(0xFF2DD4BF),
        backgroundColor: const Color(0xFF131722),
        side: BorderSide(color: isSelected ? const Color(0xFF2DD4BF) : Colors.white12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        showCheckmark: false,
        onSelected: (_) => setState(() => _selectedFilter = filter),
      ),
    );
  }

  Widget _buildItemCard(InventoryItem item) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111624),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isDigital ? const Color(0xFF2DD4BF).withValues(alpha: 0.3) : Colors.white10,
        ),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    item.webpPath,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(Icons.card_giftcard, size: 50, color: Colors.amber),
                  ),
                ),
                if (item.editionNumber != null)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.editionNumber!,
                        style: const TextStyle(color: Color(0xFF2DD4BF), fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Column(
            children: [
              Text(
                item.name,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${item.floorTon} TON • ${item.priceStars} Stars',
                style: const TextStyle(color: Colors.white54, fontSize: 10),
              ),
              const SizedBox(height: 8),

              if (item.isDigital)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showCredentialsModal(item),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2DD4BF),
                          foregroundColor: Colors.black,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 30),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('View Key', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => _promptSellDigital(item),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 30,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text('60%', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 30,
                  child: OutlinedButton(
                    onPressed: () => _promptSellGift(item),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2DD4BF),
                      side: const BorderSide(color: Color(0xFF2DD4BF)),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Sell Back', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
