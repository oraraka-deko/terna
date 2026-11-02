import 'package:flutter/material.dart';
import '../../models/higher_lower/higher_lower_models.dart';

/// Renders a crisp face-up playing card using white deck assets
/// from assets/cards/white/ with graceful custom fallback.
class CardItemWidget extends StatelessWidget {
  final PlayingCard card;
  final double width;
  final double height;
  final bool hasGlow;

  const CardItemWidget({
    super.key,
    required this.card,
    this.width = 150,
    this.height = 215,
    this.hasGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: hasGlow
                ? const Color(0xFFFBBF24).withValues(alpha: 0.6)
                : Colors.black.withValues(alpha: 0.5),
            blurRadius: hasGlow ? 18 : 12,
            spreadRadius: hasGlow ? 2 : 0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          card.assetPathWhite,
          width: width,
          height: height,
          fit: BoxFit.fill,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackCard();
          },
        ),
      ),
    );
  }

  Widget _buildFallbackCard() {
    final color = card.isRed ? const Color(0xFFDC2626) : const Color(0xFF1E293B);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD97706), width: 2),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Left Rank & Suit
          Align(
            alignment: Alignment.topLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  card.rankLabel,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  card.suitSymbol,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          // Center Big Suit
          Text(
            card.suitSymbol,
            style: TextStyle(
              color: color,
              fontSize: 54,
            ),
          ),

          // Bottom Right Rank & Suit (inverted)
          Align(
            alignment: Alignment.bottomRight,
            child: Transform.rotate(
              angle: 3.14159,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    card.rankLabel,
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    card.suitSymbol,
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                    ),
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

