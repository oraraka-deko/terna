import 'package:flutter/material.dart';
import '../../features/upgrade_game/view_models/upgrade_game_view_model.dart';
import 'gift_visual_widget.dart';
import 'wheel_dial_painter.dart';

/// Interactive Upgrade Wheel with touch physics and stationary center disc.
class UpgradeWheelWidget extends StatelessWidget {
  final UpgradeGameViewModel viewModel;
  final VoidCallback onOpenTargetPicker;
  final double size;

  const UpgradeWheelWidget({
    super.key,
    required this.viewModel,
    required this.onOpenTargetPicker,
    this.size = 280.0,
  });

  @override
  Widget build(BuildContext context) {
    final centerDiscSize = size * 0.48;

    return Center(
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (e) => viewModel.onPointerDown(e.localPosition, Size(size, size)),
        onPointerMove: (e) => viewModel.onPointerMove(e.localPosition, Size(size, size)),
        onPointerUp: (_) => viewModel.onPointerUp(),
        onPointerCancel: (_) => viewModel.onPointerUp(),
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Interactive Rotating Dial & Sector Overlay
              CustomPaint(
                size: Size(size, size),
                painter: WheelDialPainter(
                  rotationDeg: viewModel.wheelRotation,
                  winChancePercent: viewModel.winChancePercent,
                ),
              ),

              // 2. Stationary Center Disc with Target Gift & Big Chance Percentage
              GestureDetector(
                onTap: onOpenTargetPicker,
                child: Container(
                  width: centerDiscSize,
                  height: centerDiscSize,
                  decoration: BoxDecoration(
                    color: const Color(0xFF11141E),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.7),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Target Gift Icon container
                      Container(
                        width: centerDiscSize * 0.44,
                        height: centerDiscSize * 0.44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(4),
                        child: viewModel.selectedTargetGift != null
                            ? GiftVisualWidget(
                                gift: viewModel.selectedTargetGift,
                                size: centerDiscSize * 0.38,
                                animate: viewModel.isSpinning,
                              )
                            : const Icon(
                                Icons.ads_click_rounded,
                                color: Colors.black45,
                                size: 24,
                              ),
                      ),
                      const SizedBox(height: 6),

                      // Chance Percentage Display
                      Text(
                        viewModel.winChancePercent > 0
                            ? '${viewModel.winChancePercent.toStringAsFixed(1)}%'
                            : '0.0%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

