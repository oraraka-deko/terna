import 'package:flutter/material.dart';
import 'package:terna/models/roulette/odds.dart';

class RouletteTableBoard extends StatelessWidget {
  final Map<String, Bet> placedBets;
  final String? winningPocket;
  final Function(String betKey) onCellTap;

  const RouletteTableBoard({
    super.key,
    required this.placedBets,
    this.winningPocket,
    required this.onCellTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 620,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A3B18), // Deep Casino Felt Green
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4AF37), width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 15,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // '0' and '00' Green split endcaps
              SizedBox(
                width: 54,
                child: Column(
                  children: [
                    _buildFeltButton(
                      betKey: '00',
                      label: '00',
                      height: 55,
                      color: const Color(0xFF008837),
                    ),
                    const SizedBox(height: 2),
                    _buildFeltButton(
                      betKey: '0',
                      label: '0',
                      height: 55,
                      color: const Color(0xFF008837),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              // 3x12 Grid: Row 3, Row 2, Row 1
              Expanded(
                child: Column(
                  children: [
                    _buildNumberRow([3, 6, 9, 12, 15, 18, 21, 24, 27, 30, 33, 36], 'Col 3'),
                    const SizedBox(height: 2),
                    _buildNumberRow([2, 5, 8, 11, 14, 17, 20, 23, 26, 29, 32, 35], 'Col 2'),
                    const SizedBox(height: 2),
                    _buildNumberRow([1, 4, 7, 10, 13, 16, 19, 22, 25, 28, 31, 34], 'Col 1'),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              // 2-to-1 Column Bets
              SizedBox(
                width: 48,
                child: Column(
                  children: [
                    _buildFeltButton(betKey: 'Col 3', label: '2:1', height: 36, color: const Color(0xFF005522)),
                    const SizedBox(height: 2),
                    _buildFeltButton(betKey: 'Col 2', label: '2:1', height: 36, color: const Color(0xFF005522)),
                    const SizedBox(height: 2),
                    _buildFeltButton(betKey: 'Col 1', label: '2:1', height: 36, color: const Color(0xFF005522)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Dozen bets (1st 12, 2nd 12, 3rd 12)
          Row(
            children: [
              const SizedBox(width: 58),
              Expanded(child: _buildFeltButton(betKey: '1st 12', label: '1st 12', height: 38, color: const Color(0xFF005522))),
              const SizedBox(width: 2),
              Expanded(child: _buildFeltButton(betKey: '2nd 12', label: '2nd 12', height: 38, color: const Color(0xFF005522))),
              const SizedBox(width: 2),
              Expanded(child: _buildFeltButton(betKey: '3rd 12', label: '3rd 12', height: 38, color: const Color(0xFF005522))),
              const SizedBox(width: 52),
            ],
          ),
          const SizedBox(height: 4),
          // Outside bets (1-18, Even, Red, Black, Odd, 19-36)
          Row(
            children: [
              const SizedBox(width: 58),
              Expanded(child: _buildFeltButton(betKey: '1-18', label: '1-18', height: 38, color: const Color(0xFF005522))),
              const SizedBox(width: 2),
              Expanded(child: _buildFeltButton(betKey: 'Even', label: 'EVEN', height: 38, color: const Color(0xFF005522))),
              const SizedBox(width: 2),
              Expanded(
                child: _buildFeltButton(
                  betKey: 'Red',
                  label: 'RED',
                  height: 38,
                  color: const Color(0xFFD31A1A),
                  showIcon: true,
                  iconColor: Colors.redAccent,
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: _buildFeltButton(
                  betKey: 'Black',
                  label: 'BLACK',
                  height: 38,
                  color: const Color(0xFF1A1A1A),
                  showIcon: true,
                  iconColor: Colors.grey,
                ),
              ),
              const SizedBox(width: 2),
              Expanded(child: _buildFeltButton(betKey: 'Odd', label: 'ODD', height: 38, color: const Color(0xFF005522))),
              const SizedBox(width: 2),
              Expanded(child: _buildFeltButton(betKey: '19-36', label: '19-36', height: 38, color: const Color(0xFF005522))),
              const SizedBox(width: 52),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumberRow(List<int> numbers, String colKey) {
    const redNumbers = {1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36};
    return Row(
      children: numbers.map((n) {
        final isRed = redNumbers.contains(n);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.0),
            child: _buildFeltButton(
              betKey: '$n',
              label: '$n',
              height: 36,
              color: isRed ? const Color(0xFFD31A1A) : const Color(0xFF1A1A1A),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFeltButton({
    required String betKey,
    required String label,
    double? width,
    double height = 36,
    required Color color,
    bool showIcon = false,
    Color? iconColor,
  }) {
    final activeBet = placedBets[betKey];
    final isWinningCell = winningPocket != null && _isWinningBetKey(betKey, winningPocket!);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onCellTap(betKey),
        splashColor: Colors.amber.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: isWinningCell ? const Color(0xFFFFD700) : color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isWinningCell
                  ? Colors.white
                  : activeBet != null
                      ? Colors.amberAccent
                      : Colors.white38,
              width: isWinningCell || activeBet != null ? 2.0 : 0.8,
            ),
            boxShadow: isWinningCell
                ? [
                    BoxShadow(
                      color: Colors.amberAccent.withValues(alpha: 0.8),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ]
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Cell Label
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (showIcon) ...[
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: iconColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      color: isWinningCell ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: label.length > 3 ? 10 : 13,
                    ),
                  ),
                ],
              ),
              // Render Chip Badge Overlay if bet placed
              if (activeBet != null)
                Positioned(
                  child: _ChipBadge(amount: activeBet.amount),
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isWinningBetKey(String betKey, String winner) {
    if (betKey == winner) return true;
    final numVal = int.tryParse(winner);
    if (numVal == null) return false;

    const redNumbers = {1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36};

    switch (betKey) {
      case 'Red':
        return redNumbers.contains(numVal);
      case 'Black':
        return !redNumbers.contains(numVal);
      case 'Even':
        return numVal % 2 == 0;
      case 'Odd':
        return numVal % 2 != 0;
      case '1-18':
        return numVal >= 1 && numVal <= 18;
      case '19-36':
        return numVal >= 19 && numVal <= 36;
      case '1st 12':
        return numVal >= 1 && numVal <= 12;
      case '2nd 12':
        return numVal >= 13 && numVal <= 24;
      case '3rd 12':
        return numVal >= 25 && numVal <= 36;
      case 'Col 1':
        return numVal % 3 == 1;
      case 'Col 2':
        return numVal % 3 == 2;
      case 'Col 3':
        return numVal % 3 == 0;
      default:
        return false;
    }
  }
}

class _ChipBadge extends StatelessWidget {
  final int amount;

  const _ChipBadge({required this.amount});

  Color _getChipColor(int val) {
    if (val >= 1000) return const Color(0xFFFFD700); // Gold
    if (val >= 500) return const Color(0xFF8E24AA); // Purple
    if (val >= 100) return const Color(0xFF212121); // Black
    if (val >= 50) return const Color(0xFFE53935); // Red
    if (val >= 25) return const Color(0xFF43A047); // Green
    return const Color(0xFF00ACC1); // Cyan
  }

  @override
  Widget build(BuildContext context) {
    final chipColor = _getChipColor(amount);
    final isGold = amount >= 1000;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: chipColor,
        shape: BoxShape.circle,
        border: Border.all(color: isGold ? Colors.black : Colors.white, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          amount >= 1000 ? '${(amount / 1000).toStringAsFixed(1)}k' : '\$$amount',
          style: TextStyle(
            color: isGold ? Colors.black : Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}