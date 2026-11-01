import 'package:flutter/material.dart';
import 'package:terna/models/bump_game/bump_models.dart';
import 'bump_painter.dart';

/// Interactive Arena Bump Canvas Widget
class BumpCanvasWidget extends StatefulWidget {
  final List<BumpPlayerBall> balls;
  final List<EdgeHazard> hazards;
  final BumpRoundStatus status;
  final BumpPlayerBall? winner;

  const BumpCanvasWidget({
    super.key,
    required this.balls,
    required this.hazards,
    required this.status,
    this.winner,
  });

  @override
  State<BumpCanvasWidget> createState() => _BumpCanvasWidgetState();
}

class _BumpCanvasWidgetState extends State<BumpCanvasWidget> with SingleTickerProviderStateMixin {
  final Map<String, ImageInfo?> _avatarImageCache = {};
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _loadAvatars();
  }

  @override
  void didUpdateWidget(covariant BumpCanvasWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadAvatars();
  }

  void _loadAvatars() {
    for (final b in widget.balls) {
      if (b.avatar.isNotEmpty && !_avatarImageCache.containsKey(b.avatar)) {
        _avatarImageCache[b.avatar] = null;
        final imageProvider = AssetImage(b.avatar);
        final stream = imageProvider.resolve(ImageConfiguration.empty);
        stream.addListener(
          ImageStreamListener((ImageInfo info, bool _) {
            if (mounted) {
              setState(() {
                _avatarImageCache[b.avatar] = info;
              });
            }
          }, onError: (dynamic _, StackTrace? _) {
            // Ignore missing local avatar assets, painter gracefully falls back to initials
          }),
        );
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 440),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0C0D14),
            borderRadius: BorderRadius.circular(34),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
              width: 2.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0xD9000000),
                blurRadius: 40,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, _) {
                return CustomPaint(
                  painter: BumpPainter(
                    balls: widget.balls,
                    hazards: widget.hazards,
                    status: widget.status,
                    winner: widget.winner,
                    avatarImages: _avatarImageCache,
                    animationTimeMs: DateTime.now().millisecondsSinceEpoch.toDouble(),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

