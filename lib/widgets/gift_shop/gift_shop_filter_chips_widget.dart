import 'package:flutter/material.dart';
import '../../models/gift_shop/gift_shop_models.dart';

/// Horizontal filter chips row matching Image 1:
/// [Funnel] [Sort] | [Collection ˅] [Model ˅] [Back ˅] [Symbol ˅]
class GiftShopFilterChipsWidget extends StatelessWidget {
  final GiftShopFilterState filterState;
  final VoidCallback onOpenCollectionSheet;
  final VoidCallback onToggleSort;
  final VoidCallback onClearFilters;
  final String? activeCollectionName;

  const GiftShopFilterChipsWidget({
    super.key,
    required this.filterState,
    required this.onOpenCollectionSheet,
    required this.onToggleSort,
    required this.onClearFilters,
    this.activeCollectionName,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          // Filter Funnel button
          _buildIconButton(
            icon: Icons.filter_alt_rounded,
            onTap: onClearFilters,
            tooltip: 'Reset Filters',
            isActive: filterState.selectedCollectionId != null ||
                filterState.searchQuery.isNotEmpty,
          ),
          const SizedBox(width: 8),

          // Sort direction button
          _buildIconButton(
            icon: Icons.swap_vert_rounded,
            onTap: onToggleSort,
            tooltip: 'Sort Items',
            isActive: filterState.sortBy != GiftShopSortBy.popular,
          ),
          const SizedBox(width: 8),

          // Divider
          Container(
            width: 1,
            height: 24,
            color: Colors.white.withValues(alpha: 0.12),
          ),
          const SizedBox(width: 8),

          // Collection Dropdown Chip
          _buildDropdownChip(
            label: activeCollectionName ?? 'Collection',
            icon: Icons.keyboard_arrow_down_rounded,
            isSelected: activeCollectionName != null,
            onTap: onOpenCollectionSheet,
          ),
          const SizedBox(width: 8),

          // Model Dropdown Chip
          _buildDropdownChip(
            label: 'Model',
            icon: Icons.keyboard_arrow_down_rounded,
            isSelected: false,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Model filter (available in full edition release)'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          const SizedBox(width: 8),

          // Back (Backdrop) Dropdown Chip
          _buildDropdownChip(
            label: 'Back',
            icon: Icons.keyboard_arrow_down_rounded,
            isSelected: false,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Backdrop color filter (available in full release)'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          const SizedBox(width: 8),

          // Symbol Dropdown Chip
          _buildDropdownChip(
            label: 'Symbol',
            icon: Icons.keyboard_arrow_down_rounded,
            isSelected: false,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Symbol filter (available in full release)'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    bool isActive = false,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF2563EB).withValues(alpha: 0.3)
            : const Color(0xFF1E212B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? const Color(0xFF3B82F6)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: isActive ? const Color(0xFF60A5FA) : Colors.white60,
          size: 18,
        ),
        onPressed: onTap,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildDropdownChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2563EB).withValues(alpha: 0.25)
              : const Color(0xFF1E212B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF3B82F6)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF93C5FD) : Colors.white70,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              icon,
              color: isSelected ? const Color(0xFF93C5FD) : Colors.white38,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

