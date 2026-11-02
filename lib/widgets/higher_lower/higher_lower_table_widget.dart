import 'package:flutter/material.dart';
import '../../models/higher_lower/higher_lower_models.dart';
import 'card_item_widget.dart';
import 'card_back_widget.dart';
import 'higher_lower_multiplier_ladder_widget.dart';

/// Casino felt table displaying active card, drawn cards history stack, and side multiplier ladder.
class HigherLowerTableWidget extends StatelessWidget {
  final PlayingCard? currentCard;
  final List<PlayingCard> drawnHistory;
  final HigherLowerRoundState state;
  final double higherMultiplier;
  final double currentMultiplier;
  final double lowerMultiplier;
  final bool canCallHigher;
  final bool canCallLower;
  final bool isEdgeCard;

  const HigherLowerTableWidget({
    super.key,
    required this.currentCard,
    required this.drawnHistory,
    required this.state,
    required this.higherMultiplier,
    required this.currentMultiplier,
    required this.lowerMultiplier,
    required this.canCallHigher,
    required this.canCallLower,
    required this.isEdgeCard,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 310),
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Spotlight radial glow on felt table
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFEAB308).withValues(alpha: 0.12),
                  const Color(0xFF7E22CE).withValues(alpha: 0.05),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // Main Card and Ladder Row
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Cards Stack Area
              SizedBox(
                width: 175,
                height: 235,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Up to 2 previous cards stacked behind to the left
                    if (drawnHistory.isNotEmpty)
                      for (int i = 0; i < drawnHistory.length && i < 2; i++)
                        Positioned(
                          left: -22.0 * (i + 1),
                          child: Transform.rotate(
                            angle: -0.04 * (i + 1),
                            child: Opacity(
                              opacity: 0.5 - (i * 0.2),
                              child: CardItemWidget(
                                card: drawnHistory[drawnHistory.length - 1 - i],
                                width: 145,
                                height: 210,
                              ),
                            ),
                          ),
                        ),

                    // Active Card (or Card Back if idle)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, anim) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.2, 0.0),
                            end: Offset.zero,
                          ).animate(anim),
                          child: FadeTransition(opacity: anim, child: child),
                        );
                      },
                      child: currentCard != null
                          ? CardItemWidget(
                              key: ValueKey(currentCard!.toString()),
                              card: currentCard!,
                              width: 150,
                              height: 215,
                              hasGlow: state == HigherLowerRoundState.correct,
                            )
                          : const CardBackWidget(
                              key: ValueKey('back'),
                              width: 150,
                              height: 215,
                            ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 14),

              // Floating Multiplier Ladder Column
              if (currentCard != null)
                HigherLowerMultiplierLadderWidget(
                  higherMultiplier: higherMultiplier,
                  currentMultiplier: currentMultiplier,
                  lowerMultiplier: lowerMultiplier,
                  canCallHigher: canCallHigher,
                  canCallLower: canCallLower,
                  isEdgeCard: isEdgeCard,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

