import 'package:flutter/material.dart';
import '../../models/gift_shop/gift_shop_models.dart';

/// Search input and quick action buttons matching Image 1 ("Quick find", trends, view mode).
class GiftShopSearchToolbarWidget extends StatelessWidget {
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final GiftShopViewMode viewMode;
  final VoidCallback onToggleViewMode;
  final VoidCallback? onToggleTrends;

  const GiftShopSearchToolbarWidget({
    super.key,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.viewMode,
    required this.onToggleViewMode,
    this.onToggleTrends,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          // "Quick find" search box
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF181A22),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: TextField(
                onChanged: onSearchChanged,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Quick find',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Colors.white.withValues(alpha: 0.4),
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 18),
                          onPressed: () => onSearchChanged(''),
                        )
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Market Trend / Analytics button
          _buildCircleButton(
            icon: Icons.trending_up_rounded,
            onTap: onToggleTrends ?? () {},
            tooltip: 'Market Trends',
          ),
          const SizedBox(width: 8),

          // Grid / List View Toggle button
          _buildCircleButton(
            icon: viewMode == GiftShopViewMode.list
                ? Icons.grid_view_rounded
                : Icons.view_headline_rounded,
            onTap: onToggleViewMode,
            tooltip: 'Toggle View',
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF1E212B),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white70, size: 20),
        onPressed: onTap,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
      ),
    );
  }
}

