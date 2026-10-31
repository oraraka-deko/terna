import 'package:flutter/material.dart';
import 'package:terna/models/sun_or_moon/coin_side.dart';
import 'package:terna/models/sun_or_moon/game_engine.dart';

class BettingPanel extends StatelessWidget {
  final GameEngine game;
  final VoidCallback onFlip;

  const BettingPanel({
    super.key,
    required this.game,
    required this.onFlip,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Side Selector (Sun vs Moon)
        Row(
          children: [
            Expanded(
              child: _SideCard(
                side: CoinSide.sun,
                isSelected: game.selectedSide == CoinSide.sun,
                onTap: () => game.setSelectedSide(CoinSide.sun),
                disabled: game.isFlipping,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SideCard(
                side: CoinSide.moon,
                isSelected: game.selectedSide == CoinSide.moon,
                onTap: () => game.setSelectedSide(CoinSide.moon),
                disabled: game.isFlipping,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Bet Amount Selector Container
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1B142F).withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              // Bet Header: Bet Amount & Potential 2x Payout
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BET AMOUNT',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '\$${game.currentBet}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF69F0AE).withValues(alpha: 0.2),
                          const Color(0xFF00E676).withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF69F0AE).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.stars_rounded,
                          size: 16,
                          color: Color(0xFF69F0AE),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '2X Payout: +\$${game.currentBet}',
                          style: const TextStyle(
                            color: Color(0xFF69F0AE),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Chip Buttons ($5, $10, $25, $50, Half, All-In)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _ChipButton(
                    label: '\$10',
                    onTap: () => game.setBet(10),
                    disabled: game.isFlipping || game.playerBalance < 10,
                    isActive: game.currentBet == 10,
                  ),
                  _ChipButton(
                    label: '\$25',
                    onTap: () => game.setBet(25),
                    disabled: game.isFlipping || game.playerBalance < 25,
                    isActive: game.currentBet == 25,
                  ),
                  _ChipButton(
                    label: '\$50',
                    onTap: () => game.setBet(50),
                    disabled: game.isFlipping || game.playerBalance < 50,
                    isActive: game.currentBet == 50,
                  ),
                  _ChipButton(
                    label: '½ Half',
                    onTap: () => game.setQuickBetRatio(0.5),
                    disabled: game.isFlipping || game.playerBalance <= 1,
                    isActive: game.currentBet == (game.playerBalance * 0.5).round(),
                  ),
                  _ChipButton(
                    label: '⚡ ALL-IN',
                    onTap: () => game.setAllIn(),
                    disabled: game.isFlipping || game.playerBalance <= 0,
                    isActive: game.currentBet == game.playerBalance && game.playerBalance > 0,
                    isSpecial: true,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Fine-tuning slider
              if (game.playerBalance > 1)
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: game.selectedSide.primaryColor,
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                    thumbColor: Colors.white,
                    overlayColor: game.selectedSide.primaryColor.withValues(alpha: 0.2),
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                  ),
                  child: Slider(
                    value: game.currentBet.toDouble().clamp(1.0, game.playerBalance.toDouble()),
                    min: 1.0,
                    max: game.playerBalance.toDouble(),
                    onChanged: game.isFlipping
                        ? null
                        : (val) {
                            game.setBet(val.round());
                          },
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Big Play/Flip Button
        _FlipActionButton(
          game: game,
          onPressed: onFlip,
        ),
      ],
    );
  }
}

class _SideCard extends StatelessWidget {
  final CoinSide side;
  final bool isSelected;
  final VoidCallback onTap;
  final bool disabled;

  const _SideCard({
    required this.side,
    required this.isSelected,
    required this.onTap,
    required this.disabled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    side.primaryColor.withValues(alpha: 0.35),
                    side.accentColor.withValues(alpha: 0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [
                    const Color(0xFF1F1836).withValues(alpha: 0.6),
                    const Color(0xFF151026).withValues(alpha: 0.6),
                  ],
                ),
          border: Border.all(
            color: isSelected ? side.primaryColor : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: side.primaryColor.withValues(alpha: 0.35),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              side.icon,
              color: isSelected ? side.accentColor : Colors.white60,
              size: 26,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  side.displayName.toUpperCase(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  isSelected ? 'Selected' : 'Pick',
                  style: TextStyle(
                    color: isSelected ? side.accentColor : Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool disabled;
  final bool isActive;
  final bool isSpecial;

  const _ChipButton({
    required this.label,
    required this.onTap,
    required this.disabled,
    required this.isActive,
    this.isSpecial = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isSpecial
                ? (isActive
                    ? const Color(0xFFFF5252).withValues(alpha: 0.5)
                    : const Color(0xFFFF5252).withValues(alpha: 0.2))
                : (isActive
                    ? const Color(0xFFFFB300).withValues(alpha: 0.35)
                    : Colors.white.withValues(alpha: 0.07)),
            border: Border.all(
              color: isActive
                  ? (isSpecial ? const Color(0xFFFF5252) : const Color(0xFFFFB300))
                  : Colors.white.withValues(alpha: 0.15),
              width: 1.2,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: disabled
                  ? Colors.white24
                  : (isActive ? Colors.white : Colors.white.withValues(alpha: 0.8)),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _FlipActionButton extends StatelessWidget {
  final GameEngine game;
  final VoidCallback onPressed;

  const _FlipActionButton({
    required this.game,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isBankrupt = game.isBankrupt;
    final isFlipping = game.isFlipping;

    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: isBankrupt
            ? const LinearGradient(
                colors: [Color(0xFFD32F2F), Color(0xFFC2185B)],
              )
            : LinearGradient(
                colors: game.selectedSide.gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        boxShadow: [
          BoxShadow(
            color: (isBankrupt
                    ? const Color(0xFFD32F2F)
                    : game.selectedSide.primaryColor)
                .withValues(alpha: 0.45),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: (isFlipping) ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isFlipping) ...[
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'FLIPPING COIN...',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 2.0,
                ),
              ),
            ] else if (isBankrupt) ...[
              const Icon(Icons.refresh_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              const Text(
                'CLAIM \$100 RESTART',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 1.5,
                ),
              ),
            ] else ...[
              Icon(
                game.selectedSide == CoinSide.sun
                    ? Icons.wb_sunny_rounded
                    : Icons.nightlight_round,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                'PLAY ${game.selectedSide.displayName.toUpperCase()} (\$${game.currentBet})',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
