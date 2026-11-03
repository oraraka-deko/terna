import 'package:terna/core/widgets/safe_avatar_image.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:terna/models/bump_game/bump_models.dart';
import 'bump_painter.dart';

/// Video playback viewer modal with scrubber timeline for Arena Bump
class BumpReplayModal extends StatefulWidget {
  final BumpRoundHistory record;
  final VoidCallback onClose;

  const BumpReplayModal({
    super.key,
    required this.record,
    required this.onClose,
  });

  @override
  State<BumpReplayModal> createState() => _BumpReplayModalState();
}

class _BumpReplayModalState extends State<BumpReplayModal> {
  Timer? _playbackTimer;
  double _progress = 0.0;
  bool _isPlaying = true;
  double _speed = 1.0;
  final Map<String, ImageInfo?> _avatarImageCache = {};

  late List<BumpPlayerBall> _currentBalls;
  late List<EdgeHazard> _currentHazards;

  @override
  void initState() {
    super.initState();
    _currentBalls = widget.record.participants.map((b) => b.copy()).toList();
    _currentHazards = [];
    _loadAvatars();
    _startPlayback();
  }

  void _loadAvatars() {
    for (final b in widget.record.participants) {
      if (b.avatar.isNotEmpty && !_avatarImageCache.containsKey(b.avatar)) {
        _avatarImageCache[b.avatar] = null;
        final imageProvider = safeImageProvider(b.avatar)!;
        final stream = imageProvider.resolve(ImageConfiguration.empty);
        stream.addListener(
          ImageStreamListener((ImageInfo info, bool _) {
            if (mounted) {
              setState(() {
                _avatarImageCache[b.avatar] = info;
              });
            }
          }, onError: (dynamic _, StackTrace? _) {}),
        );
      }
    }
  }

  void _startPlayback() {
    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(const Duration(milliseconds: 32), (timer) {
      if (!_isPlaying) return;

      final frames = widget.record.replayFrames;
      final totalDurationMs = frames.isNotEmpty ? frames.last.timeMs : 8000.0;
      final step = (32.0 * _speed) / (totalDurationMs > 0 ? totalDurationMs : 8000.0);
      final nextProg = _progress + step;

      if (nextProg >= 1.0) {
        setState(() {
          _progress = 1.0;
          _isPlaying = false;
        });
        _applyFrameAtProgress(1.0);
        timer.cancel();
      } else {
        setState(() {
          _progress = nextProg;
        });
        _applyFrameAtProgress(nextProg);
      }
    });
  }

  void _applyFrameAtProgress(double prog) {
    final frames = widget.record.replayFrames;
    if (frames.isEmpty) return;

    final frameIdx = (prog * (frames.length - 1)).clamp(0, frames.length - 1).toInt();
    final frame = frames[frameIdx];

    // Apply ball coordinates and opacities
    for (int i = 0; i < frame.ballStates.length && i < _currentBalls.length; i++) {
      final state = frame.ballStates[i];
      _currentBalls[i].x = state.x;
      _currentBalls[i].y = state.y;
      _currentBalls[i].radius = state.radius;
      _currentBalls[i].state = state.state;
      _currentBalls[i].exitOpacity = state.opacity;
    }

    // Apply hazards
    _currentHazards = frame.hazards.map((h) => EdgeHazard(
      side: h.side,
      startCoord: h.start,
      endCoord: h.end,
      status: h.status,
    )).toList();
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying && _progress >= 1.0) {
        _progress = 0.0;
      }
    });
    if (_isPlaying) {
      _startPlayback();
    }
  }

  void _toggleSpeed() {
    setState(() {
      _speed = _speed == 1.0 ? 2.0 : 1.0;
    });
  }

  void _seek(double val) {
    setState(() {
      _progress = val;
    });
    _applyFrameAtProgress(val);
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final winner = widget.record.winner;
    final totalDurationMs = widget.record.replayFrames.isNotEmpty
        ? widget.record.replayFrames.last.timeMs
        : 8000.0;

    return Container(
      color: Colors.black.withValues(alpha: 0.9),
      child: Center(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 440),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F121E),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.videocam, color: Color(0xFF2DD4BF), size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Replay #${widget.record.roundId}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 20),
                      onPressed: widget.onClose,
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 2. Playback Canvas
                AspectRatio(
                  aspectRatio: 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C0D14),
                      borderRadius: BorderRadius.circular(34),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: CustomPaint(
                        painter: BumpPainter(
                          balls: _currentBalls,
                          hazards: _currentHazards,
                          status: BumpRoundStatus.battle,
                          winner: winner,
                          avatarImages: _avatarImageCache,
                          animationTimeMs: DateTime.now().millisecondsSinceEpoch.toDouble(),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 3. Scrubber Slider
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF2DD4BF),
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                    thumbColor: const Color(0xFF2DD4BF),
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  ),
                  child: Slider(
                    value: _progress,
                    onChanged: _seek,
                  ),
                ),

                // 4. Controls Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        _isPlaying ? Icons.pause_circle : Icons.play_circle,
                        color: const Color(0xFF2DD4BF),
                        size: 32,
                      ),
                      onPressed: _togglePlayPause,
                    ),
                    Text(
                      '${((_progress * totalDurationMs) / 1000.0).toStringAsFixed(1)}s / ${(totalDurationMs / 1000.0).toStringAsFixed(1)}s',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                    TextButton(
                      onPressed: _toggleSpeed,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: Text(
                        '${_speed.toInt()}x',
                        style: const TextStyle(
                          color: Color(0xFF2DD4BF),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 5. Winner Summary Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161928),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.emoji_events, color: Color(0xFFFBBF24), size: 16),
                          const SizedBox(width: 6),
                          Text(
                            winner.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        widget.record.totalPotTon > 0
                            ? '+${(widget.record.totalPotTon * 0.95).toStringAsFixed(3)} TON'
                            : '+${(widget.record.totalPotStars * 0.95).round()} ⭐',
                        style: const TextStyle(
                          color: Color(0xFF2DD4BF),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

