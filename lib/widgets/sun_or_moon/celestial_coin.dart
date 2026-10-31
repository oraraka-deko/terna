import 'dart:math';
import 'package:flutter/material.dart';
import 'package:terna/models/sun_or_moon/coin_side.dart';

class CelestialCoin extends StatefulWidget {
  final CoinSide side;
  final bool isFlipping;
  final double size;
  final VoidCallback? onTap;

  const CelestialCoin({
    super.key,
    required this.side,
    this.isFlipping = false,
    this.size = 200.0,
    this.onTap,
  });

  @override
  State<CelestialCoin> createState() => _CelestialCoinState();
}

class _CelestialCoinState extends State<CelestialCoin>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _currentAngle = 0.0;
  double _targetAngle = 0.0;

  @override
  void initState() {
    super.initState();
    _currentAngle = widget.side == CoinSide.sun ? 0.0 : pi;
    _targetAngle = _currentAngle;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _animation = Tween<double>(begin: _currentAngle, end: _targetAngle).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.addListener(() {
      _currentAngle = _animation.value;
    });
  }

  @override
  void didUpdateWidget(covariant CelestialCoin oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isFlipping && !oldWidget.isFlipping) {
      _controller.stop();
      final targetBase = widget.side == CoinSide.sun ? 0.0 : pi;
      const fullSpins = 6;
      final newTarget = ((_currentAngle ~/ (2 * pi)) + fullSpins) * 2 * pi + targetBase;

      _animation = Tween<double>(
        begin: _currentAngle,
        end: newTarget,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
      );

      _controller.forward(from: 0.0).then((_) {
        if (mounted) {
          setState(() {
            _currentAngle = targetBase;
            _targetAngle = targetBase;
          });
        }
      });
    } else if (!widget.isFlipping && widget.side != oldWidget.side) {
      _controller.stop();
      final target = widget.side == CoinSide.sun ? 0.0 : pi;
      _animation = Tween<double>(
        begin: _currentAngle,
        end: target,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
      );
      _controller.forward(from: 0.0).then((_) {
        if (mounted) {
          setState(() {
            _currentAngle = target;
            _targetAngle = target;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final angle = _currentAngle;
          final normalizedAngle = (angle % (2 * pi) + 2 * pi) % (2 * pi);
          final isShowingSun = normalizedAngle < (pi / 2) || normalizedAngle > (3 * pi / 2);

          final currentSide = isShowingSun ? CoinSide.sun : CoinSide.moon;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0015)
              ..rotateY(angle),
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: currentSide == CoinSide.sun
                        ? const Color(0xFFFFB300).withValues(alpha: 0.45)
                        : const Color(0xFF9C27B0).withValues(alpha: 0.45),
                    blurRadius: 32,
                    spreadRadius: 6,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: isShowingSun
                  ? const _SunFace()
                  : Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(pi),
                      child: const _MoonFace(),
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _SunFace extends StatelessWidget {
  const _SunFace();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.2, -0.3),
          radius: 0.9,
          colors: [
            Color(0xFFFFF9C4), // Bright light center
            Color(0xFFFFCA28), // Golden amber
            Color(0xFFFF8F00), // Deep orange gold
            Color(0xFFE65100), // Rich bronze edge
          ],
          stops: [0.0, 0.4, 0.8, 1.0],
        ),
        border: Border.all(
          color: const Color(0xFFFFE082),
          width: 6,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Inner Engraved Ring
          Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFFB300).withValues(alpha: 0.8),
                width: 2,
              ),
            ),
          ),
          // Solar rays background custom paint
          CustomPaint(
            size: const Size(180, 180),
            painter: _SolarRaysPainter(),
          ),
          // Center Sun Emblem
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wb_sunny_rounded,
                size: 64,
                color: Colors.white.withValues(alpha: 0.95),
                shadows: [
                  Shadow(
                    color: const Color(0xFFBF360C).withValues(alpha: 0.8),
                    blurRadius: 8,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'SUN',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 4,
                  shadows: [
                    Shadow(
                      color: const Color(0xFFBF360C).withValues(alpha: 0.8),
                      blurRadius: 6,
                      offset: const Offset(1, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoonFace extends StatelessWidget {
  const _MoonFace();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.2, -0.3),
          radius: 0.9,
          colors: [
            Color(0xFFEDE7F6), // Mystic white silver
            Color(0xFFB39DDB), // Lavender silver
            Color(0xFF7E57C2), // Royal purple
            Color(0xFF311B92), // Deep midnight violet
          ],
          stops: [0.0, 0.35, 0.75, 1.0],
        ),
        border: Border.all(
          color: const Color(0xFFD1C4E9),
          width: 6,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Inner Engraved Ring
          Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF9575CD).withValues(alpha: 0.7),
                width: 2,
              ),
            ),
          ),
          // Lunar stars custom paint
          CustomPaint(
            size: const Size(180, 180),
            painter: _LunarStarsPainter(),
          ),
          // Center Moon Emblem
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.nightlight_round,
                size: 60,
                color: Colors.white.withValues(alpha: 0.95),
                shadows: [
                  Shadow(
                    color: const Color(0xFF1A237E).withValues(alpha: 0.8),
                    blurRadius: 8,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'MOON',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 4,
                  shadows: [
                    Shadow(
                      color: const Color(0xFF1A237E).withValues(alpha: 0.8),
                      blurRadius: 6,
                      offset: const Offset(1, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SolarRaysPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.35)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final rayCount = 16;
    final innerR = size.width * 0.32;
    final outerR = size.width * 0.44;

    for (int i = 0; i < rayCount; i++) {
      final theta = (i * 2 * pi) / rayCount;
      final start = Offset(
        center.dx + innerR * cos(theta),
        center.dy + innerR * sin(theta),
      );
      final end = Offset(
        center.dx + outerR * cos(theta),
        center.dy + outerR * sin(theta),
      );
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LunarStarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    // Small craters and sparkles around edge
    final offsets = [
      Offset(center.dx - 35, center.dy - 35),
      Offset(center.dx + 40, center.dy - 20),
      Offset(center.dx - 30, center.dy + 35),
      Offset(center.dx + 30, center.dy + 30),
      Offset(center.dx - 45, center.dy),
      Offset(center.dx + 45, center.dy),
    ];

    for (final offset in offsets) {
      canvas.drawCircle(offset, 2.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
