import 'package:flutter/material.dart';
import 'package:terna/models/territory_game/territory_models.dart';
import 'territory_painter.dart';

/// Interactive 460x460 Arena Canvas Widget
class TerritoryCanvasWidget extends StatefulWidget {
  final List<WatertightPolygon> territories;
  final double puckX;
  final double puckY;
  final bool puckActive;
  final bool isPuckStopped;
  final List<TerritoryPoint> puckTrail;
  final bool isAiming;
  final double currentAimAngle;
  final double aimOpacity;
  final double cameraZoom;
  final double cameraPanX;
  final double cameraPanY;
  final String? winnerPlayerId;
  final bool isCelebrating;

  const TerritoryCanvasWidget({
    super.key,
    required this.territories,
    required this.puckX,
    required this.puckY,
    required this.puckActive,
    required this.isPuckStopped,
    required this.puckTrail,
    required this.isAiming,
    required this.currentAimAngle,
    required this.aimOpacity,
    required this.cameraZoom,
    required this.cameraPanX,
    required this.cameraPanY,
    this.winnerPlayerId,
    this.isCelebrating = false,
  });

  @override
  State<TerritoryCanvasWidget> createState() => _TerritoryCanvasWidgetState();
}

class _TerritoryCanvasWidgetState extends State<TerritoryCanvasWidget> {
  final Map<String, ImageInfo?> _avatarImageCache = {};

  @override
  void didUpdateWidget(covariant TerritoryCanvasWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadAvatars();
  }

  @override
  void initState() {
    super.initState();
    _loadAvatars();
  }

  void _loadAvatars() {
    for (final poly in widget.territories) {
      if (poly.avatar.isNotEmpty && !_avatarImageCache.containsKey(poly.avatar)) {
        _avatarImageCache[poly.avatar] = null;
        final imageProvider = AssetImage(poly.avatar);
        final stream = imageProvider.resolve(ImageConfiguration.empty);
        stream.addListener(
          ImageStreamListener((ImageInfo info, bool _) {
            if (mounted) {
              setState(() {
                _avatarImageCache[poly.avatar] = info;
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
            child: CustomPaint(
              painter: TerritoryPainter(
                territories: widget.territories,
                puckX: widget.puckX,
                puckY: widget.puckY,
                puckActive: widget.puckActive,
                isPuckStopped: widget.isPuckStopped,
                puckTrail: widget.puckTrail,
                isAiming: widget.isAiming,
                currentAimAngle: widget.currentAimAngle,
                aimOpacity: widget.aimOpacity,
                cameraZoom: widget.cameraZoom,
                cameraPanX: widget.cameraPanX,
                cameraPanY: widget.cameraPanY,
                winnerPlayerId: widget.winnerPlayerId,
                isCelebrating: widget.isCelebrating,
                avatarImages: _avatarImageCache,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
