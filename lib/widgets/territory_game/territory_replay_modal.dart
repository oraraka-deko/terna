import 'dart:async';
import 'package:flutter/material.dart';
import 'package:terna/models/territory_game/territory_models.dart';
import 'package:terna/services/territory_game/territory_slicing_service.dart';
import 'package:terna/services/territory_game/territory_physics_service.dart';
import 'package:terna/services/territory_game/territory_audio_service.dart';
import 'territory_canvas_widget.dart';

/// Video playback viewer modal with scrubber timeline and speed controls
class TerritoryReplayModal extends StatefulWidget {
  final RoundHistoryRecord record;
  final VoidCallback onClose;

  const TerritoryReplayModal({
    super.key,
    required this.record,
    required this.onClose,
  });

  @override
  State<TerritoryReplayModal> createState() => _TerritoryReplayModalState();
}

class _TerritoryReplayModalState extends State<TerritoryReplayModal> {
  late final AirHockeyTrajectory _trajectory;
  late final List<WatertightPolygon> _territories;

  Timer? _playbackTimer;
  double _progress = 0.0;
  bool _isPlaying = true;
  double _speed = 1.0;
  bool _audioMuted = false;

  double _puckX = 230.0;
  double _puckY = 230.0;
  bool _isPuckStopped = false;
  final List<TerritoryPoint> _trail = [];
  int _lastHitIndex = 0;

  @override
  void initState() {
    super.initState();
    _territories = TerritorySlicingService.computeProportionalTerritories(widget.record.players);
    _trajectory = widget.record.trajectory ??
        TerritoryPhysicsService.simulateAirHockeyFlight(
          seed: widget.record.roundId,
          winnerPlayerId: widget.record.winner.playerId,
          territories: _territories,
          durationMs: 8000.0,
        );
    _startPlayback();
  }

  void _startPlayback() {
    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!_isPlaying) return;

      const durationMs = 8000.0;
      final step = (16.0 * _speed) / durationMs;
      final nextProg = _progress + step;

      if (nextProg >= 1.0) {
        setState(() {
          _progress = 1.0;
          _isPlaying = false;
        });
        _updateSample(1.0);
        timer.cancel();
      } else {
        setState(() {
          _progress = nextProg;
        });
        _updateSample(nextProg);
      }
    });
  }

  void _updateSample(double prog) {
    final sample = TerritoryPhysicsService.sampleTrajectory(_trajectory, prog);
    _puckX = sample.x;
    _puckY = sample.y;
    _isPuckStopped = sample.isStopped;

    if (!sample.isStopped) {
      _trail.add(TerritoryPoint(sample.x, sample.y));
      if (_trail.length > 18) _trail.removeAt(0);
    }

    // Play wall hit audio
    if (!_audioMuted && _trajectory.wallHits.isNotEmpty) {
      final currentMs = prog * _trajectory.totalDurationMs;
      while (_lastHitIndex < _trajectory.wallHits.length &&
          currentMs >= _trajectory.wallHits[_lastHitIndex].timeMs) {
        TerritoryAudioService.playPuckWallHit(_trajectory.wallHits[_lastHitIndex].intensity);
        _lastHitIndex++;
      }
    }
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying && _progress >= 1.0) {
        _progress = 0.0;
        _trail.clear();
        _lastHitIndex = 0;
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
      _trail.clear();
      _lastHitIndex = 0;
    });
    _updateSample(val);
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final winner = widget.record.winner;

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

                // 2. Playback Arena Canvas
                TerritoryCanvasWidget(
                  territories: _territories,
                  puckX: _puckX,
                  puckY: _puckY,
                  puckActive: true,
                  isPuckStopped: _isPuckStopped,
                  puckTrail: _trail,
                  isAiming: false,
                  currentAimAngle: _trajectory.launchAngle,
                  aimOpacity: 1.0,
                  cameraZoom: 1.0,
                  cameraPanX: 230.0,
                  cameraPanY: 230.0,
                  winnerPlayerId: winner.playerId,
                  isCelebrating: _isPuckStopped,
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

                // 4. Playback Controls Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Play / Pause Button
                    IconButton(
                      icon: Icon(
                        _isPlaying ? Icons.pause_circle : Icons.play_circle,
                        color: const Color(0xFF2DD4BF),
                        size: 32,
                      ),
                      onPressed: _togglePlayPause,
                    ),

                    // Timestamp
                    Text(
                      '${(_progress * 8.0).toStringAsFixed(1)}s / 8.0s',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),

                    // Speed Toggle
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

                    // Mute Toggle
                    IconButton(
                      icon: Icon(
                        _audioMuted ? Icons.volume_off : Icons.volume_up,
                        color: Colors.white.withValues(alpha: 0.6),
                        size: 20,
                      ),
                      onPressed: () => setState(() => _audioMuted = !_audioMuted),
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
                            winner.username,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        winner.payoutTon > 0
                            ? '+${winner.payoutTon.toStringAsFixed(3)} TON'
                            : '+${winner.payoutStars} ⭐',
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

