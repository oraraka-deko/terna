import 'package:flutter/material.dart';

class MobileFrameWrapper extends StatelessWidget {
  final Widget child;
  final bool darkStatusBar;
  final VoidCallback? onExit;

  const MobileFrameWrapper({
    super.key,
    required this.child,
    this.darkStatusBar = true,
    this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 500 && constraints.maxHeight > 880;

        if (!isLargeScreen) {
          // On mobile viewports or smaller windows, fill smoothly while retaining status bar
          return Scaffold(
            backgroundColor: Colors.black,
            body: SafeArea(
              top: false,
              bottom: false,
              child: Stack(
                children: [
                  Positioned.fill(child: child),
                  _buildStatusBar(isDark: darkStatusBar, context: context),
                  _buildHomeIndicator(),
                  if (onExit != null) _buildExitButton(context),
                ],
              ),
            ),
          );
        }

        // On desktop/web large screens: render centered iPhone 16 Pro viewport
        return Scaffold(
          backgroundColor: const Color(0xFF1E1E24),
          body: Center(
            child: Container(
              width: 393,
              height: 852,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(52),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 36,
                    spreadRadius: 8,
                    offset: const Offset(0, 16),
                  ),
                ],
                border: Border.all(
                  color: const Color(0xFF48484A),
                  width: 9,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(44),
                child: Stack(
                  children: [
                    Positioned.fill(child: child),
                    _buildStatusBar(isDark: darkStatusBar, context: context),
                    _buildHomeIndicator(),
                    if (onExit != null) _buildExitButton(context),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBar({required bool isDark, required BuildContext context}) {
    final textColor = isDark ? Colors.black : Colors.white;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 50,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Time
              Text(
                '9:41',
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),

              // Dynamic Island
              Container(
                width: 124,
                height: 35,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1C1C1E),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),

              // Cellular, WiFi, Battery
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.signal_cellular_alt_rounded, size: 16, color: textColor),
                  const SizedBox(width: 4),
                  Icon(Icons.wifi_rounded, size: 16, color: textColor),
                  const SizedBox(width: 5),
                  Container(
                    width: 24,
                    height: 12,
                    padding: const EdgeInsets.all(1.5),
                    decoration: BoxDecoration(
                      border: Border.all(color: textColor, width: 1.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 15,
                        decoration: BoxDecoration(
                          color: textColor,
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeIndicator() {
    return Positioned(
      bottom: 8,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          width: 134,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(100),
          ),
        ),
      ),
    );
  }

  Widget _buildExitButton(BuildContext context) {
    return Positioned(
      top: 60,
      left: 14,
      child: GestureDetector(
        onTap: onExit,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.close_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }
}
