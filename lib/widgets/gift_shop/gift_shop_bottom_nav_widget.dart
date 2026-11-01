import 'dart:ui';
import 'package:flutter/material.dart';

/// Floating frosted glass bottom navigation bar matching Image 1:
/// [Games] [Store (Active)] [My gifts] [Event (HOT)] [Profile]
class GiftShopBottomNavWidget extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final VoidCallback? onGamesTap;

  const GiftShopBottomNavWidget({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.onGamesTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 20,
      right: 20,
      bottom: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF161822).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Games
                _buildNavItem(
                  index: 0,
                  icon: Icons.sports_esports_rounded,
                  label: 'Games',
                  onTap: () {
                    if (onGamesTap != null) {
                      onGamesTap!();
                    } else {
                      onItemSelected(0);
                    }
                  },
                ),

                // Store (Active default)
                _buildNavItem(
                  index: 1,
                  icon: Icons.storefront_rounded,
                  label: 'Store',
                  isActivePill: true,
                  onTap: () => onItemSelected(1),
                ),

                // My gifts
                _buildNavItem(
                  index: 2,
                  icon: Icons.card_giftcard_rounded,
                  label: 'My gifts',
                  onTap: () => onItemSelected(2),
                ),

                // Event with HOT badge
                _buildNavItem(
                  index: 3,
                  icon: Icons.celebration_rounded,
                  label: 'Event',
                  badgeText: 'HOT',
                  onTap: () => onItemSelected(3),
                ),

                // Profile Avatar
                GestureDetector(
                  onTap: () => onItemSelected(4),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selectedIndex == 4
                            ? const Color(0xFF38BDF8)
                            : Colors.white.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                      image: const DecorationImage(
                        image: AssetImage('assets/telegram/avatars_demo/avatar_1.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    bool isActivePill = false,
    String? badgeText,
    required VoidCallback onTap,
  }) {
    final isSelected = selectedIndex == index;

    if (isActivePill && isSelected) {
      // Pill highlight for active Store tab (matching screenshot)
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1E88E5),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.white54,
                size: 20,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white54,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
          if (badgeText != null)
            Positioned(
              top: -6,
              right: -10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFFF97316),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

