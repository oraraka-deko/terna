import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:terna/core/constants/app_assets.dart';
import 'package:terna/core/theme/app_colors.dart';

enum TelegramTab { contacts, calls, chats, settings }

class FloatingBottomNavBar extends StatelessWidget {
  final TelegramTab currentTab;
  final ValueChanged<TelegramTab> onTabSelected;
  final VoidCallback? onSearchTap;

  const FloatingBottomNavBar({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
    this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24,
      left: 16,
      right: 16,
      child: Row(
        children: [
          // Left Main Glass Capsule (4 Tabs)
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                child: Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.65),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildTabItem(
                        tab: TelegramTab.contacts,
                        label: 'Contacts',
                        icon: Icons.account_circle,
                        isActive: currentTab == TelegramTab.contacts,
                      ),
                      _buildTabItem(
                        tab: TelegramTab.calls,
                        label: 'Calls',
                        icon: Icons.phone,
                        isActive: currentTab == TelegramTab.calls,
                      ),
                      _buildTabItem(
                        tab: TelegramTab.chats,
                        label: 'Chats',
                        icon: Icons.chat_bubble,
                        isActive: currentTab == TelegramTab.chats,
                      ),
                      _buildTabItem(
                        tab: TelegramTab.settings,
                        label: 'Settings',
                        icon: Icons.settings,
                        isActive: currentTab == TelegramTab.settings,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Right Detached Glass Circle Search Button
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: GestureDetector(
                onTap: onSearchTap,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.82),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.65),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Image.asset(
                      AppAssets.symbolSearch,
                      width: 22,
                      height: 22,
                      color: Colors.black,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.search_rounded,
                        color: Colors.black,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required TelegramTab tab,
    required String label,
    required IconData icon,
    required bool isActive,
  }) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTabSelected(tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFE5E5EA).withValues(alpha: 0.75) : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 22,
                color: isActive ? AppColors.primaryBlue : Colors.black,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive ? AppColors.primaryBlue : Colors.black,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

