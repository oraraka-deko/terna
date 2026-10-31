import 'dart:math';
import 'package:flutter/material.dart';

class StarryBackground extends StatefulWidget {
  final Widget child;
  const StarryBackground({super.key, required this.child});

  @override
  State<StarryBackground> createState() => _StarryBackgroundState();
}

class _StarryBackgroundState extends State<StarryBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Star> _stars = [];
  final Random _random = Random(42);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    for (int i = 0; i < 60; i++) {
      _stars.add(
        _Star(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          radius: _random.nextDouble() * 2.0 + 0.8,
          phase: _random.nextDouble() * 2 * pi,
          isGold: _random.nextBool(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.3),
          radius: 1.4,
          colors: [
            Color(0xFF1E1035), // Deep mystic violet
            Color(0xFF0F0B1E), // Dark celestial purple
            Color(0xFF07050E), // Cosmic black
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _StarrySkyPainter(
                  stars: _stars,
                  animationValue: _controller.value,
                ),
              );
            },
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _Star {
  final double x;
  final double y;
  final double radius;
  final double phase;
  final bool isGold;

  _Star({
    required this.x,
    required this.y,
    required this.radius,
    required this.phase,
    required this.isGold,
  });
}

class _StarrySkyPainter extends CustomPainter {
  final List<_Star> stars;
  final double animationValue;

  _StarrySkyPainter({required this.stars, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    for (final star in stars) {
      final opacity =
          ((sin(animationValue * 2 * pi + star.phase) + 1) / 2) * 0.7 + 0.3;
      final paint = Paint()
        ..color = star.isGold
            ? const Color(0xFFFFD54F).withValues(alpha: opacity)
            : Colors.white.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StarrySkyPainter oldDelegate) => true;
}
