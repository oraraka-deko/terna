import 'package:terna/core/widgets/safe_avatar_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:terna/models/territory_game/territory_models.dart';
import 'package:terna/services/territory_game/territory_audio_service.dart';

/// Victory celebration modal popup
class TerritoryVictoryModal extends StatefulWidget {
  final CurrentRoundState roundState;
  final VoidCallback onClose;
  final VoidCallback onWatchReplay;

  const TerritoryVictoryModal({
    super.key,
    required this.roundState,
    required this.onClose,
    required this.onWatchReplay,
  });

  @override
  State<TerritoryVictoryModal> createState() => _TerritoryVictoryModalState();
}

class _TerritoryVictoryModalState extends State<TerritoryVictoryModal> {
  bool _copiedHash = false;
  bool _copiedSeed = false;

  void _copy(String text, bool isHash) {
    TerritoryAudioService.playClick();
    Clipboard.setData(ClipboardData(text: text));
    if (isHash) {
      setState(() => _copiedHash = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _copiedHash = false);
      });
    } else {
      setState(() => _copiedSeed = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _copiedSeed = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final winner = widget.roundState.winner;
    if (winner == null) return const SizedBox.shrink();

    return Container(
      color: Colors.black.withValues(alpha: 0.82),
      child: Center(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 380),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF101322),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            boxShadow: const [
              BoxShadow(
                color: Color(0xCC000000),
                blurRadius: 40,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Winner Avatar with Halo & Crown
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2DD4BF).withValues(alpha: 0.5),
                          blurRadius: 28,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: winner.color,
                      backgroundImage:
                          winner.avatar.isNotEmpty ? safeImageProvider(winner.avatar)! : null,
                      child: winner.avatar.isEmpty
                          ? Text(
                              winner.username.replaceAll('@', '').isNotEmpty
                                  ? winner.username.replaceAll('@', '')[0].toUpperCase()
                                  : 'W',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    top: -10,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFBBF24),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.emoji_events, color: Colors.black, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 2. Round Champion Title
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF2DD4BF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'ROUND CHAMPION',
                  style: TextStyle(
                    color: Color(0xFF2DD4BF),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                winner.username,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),

              // 3. Payout Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B2E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2DD4BF).withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Text(
                      'TOTAL PAYOUT',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      winner.payoutTon > 0
                          ? '+${winner.payoutTon.toStringAsFixed(3)} TON'
                          : '+${winner.payoutStars} ⭐',
                      style: const TextStyle(
                        color: Color(0xFF2DD4BF),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 4. Provably Fair Seed Details
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B0D16),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pre-round Hash:',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10),
                        ),
                        GestureDetector(
                          onTap: () => _copy(widget.roundState.serverSeedHash, true),
                          child: Row(
                            children: [
                              Text(
                                '${widget.roundState.serverSeedHash.substring(0, 8)}...',
                                style: const TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                _copiedHash ? Icons.check : Icons.copy,
                                size: 10,
                                color: const Color(0xFF10B981),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Revealed Seed:',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10),
                        ),
                        GestureDetector(
                          onTap: () => _copy(widget.roundState.revealedServerSeed ?? '', false),
                          child: Row(
                            children: [
                              Text(
                                '${(widget.roundState.revealedServerSeed ?? "").substring(0, 10)}...',
                                style: const TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                _copiedSeed ? Icons.check : Icons.copy,
                                size: 10,
                                color: const Color(0xFF10B981),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 5. Actions: Replay & Close
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.onWatchReplay,
                      icon: const Icon(Icons.play_arrow, size: 16, color: Colors.white),
                      label: const Text(
                        'Watch Replay',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: widget.onClose,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2DD4BF),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Next Round',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
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
}
