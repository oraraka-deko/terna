import 'package:flutter/material.dart';
import 'package:terna/models/sun_or_moon/game_engine.dart';

class VaultCard extends StatelessWidget {
  final GameEngine game;

  const VaultCard({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1836).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Player Balance
          Expanded(
            child: _StatColumn(
              icon: Icons.account_balance_wallet_rounded,
              iconColor: const Color(0xFF69F0AE),
              label: 'PLAYER BALANCE',
              value: '${game.playerBalance} ⭐',
              valueColor: game.playerBalance > 0
                  ? const Color(0xFF69F0AE)
                  : const Color(0xFFFF5252),
              subtext:
                  '${game.tonBalance.toStringAsFixed(3)} TON • High: ${game.highestBalance} ⭐',
            ),
          ),

          // Divider
          Container(
            width: 1,
            height: 48,
            color: Colors.white.withValues(alpha: 0.15),
          ),

          // System Vault (game statistic)
          Expanded(
            child: _StatColumn(
              icon: Icons.lock_outline_rounded,
              iconColor: const Color(0xFFFF5252),
              label: 'SYSTEM VAULT',
              value: '${game.systemLockedVault} ⭐',
              valueColor: const Color(0xFFFF7043),
              subtext: 'Simulated vault',
            ),
          ),

          // Divider
          Container(
            width: 1,
            height: 48,
            color: Colors.white.withValues(alpha: 0.15),
          ),

          // Win Streak & Stats
          Expanded(
            child: _StatColumn(
              icon: Icons.local_fire_department_rounded,
              iconColor: const Color(0xFFFFAB00),
              label: 'STREAK',
              value: '${game.winStreak}🔥',
              valueColor: const Color(0xFFFFD54F),
              subtext: 'Best: ${game.bestStreak}',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color valueColor;
  final String subtext;

  const _StatColumn({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.valueColor,
    required this.subtext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: Text(
            value,
            key: ValueKey(value),
            style: TextStyle(
              color: valueColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtext,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
