import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:terna/models/territory_game/territory_models.dart';
import 'package:terna/services/territory_game/territory_audio_service.dart';

/// Provably fair explanation and seed hash verification modal
class TerritoryProvablyFairModal extends StatefulWidget {
  final CurrentRoundState roundState;
  final VoidCallback onClose;

  const TerritoryProvablyFairModal({
    super.key,
    required this.roundState,
    required this.onClose,
  });

  @override
  State<TerritoryProvablyFairModal> createState() => _TerritoryProvablyFairModalState();
}

class _TerritoryProvablyFairModalState extends State<TerritoryProvablyFairModal> {
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
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      child: Center(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 380),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF101322),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.verified_user, color: Color(0xFF10B981), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Provably Fair System',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Explanation
              Text(
                'Every round trajectory is calculated deterministically before betting closes. The hash of the secret server seed is published in advance, guaranteeing that neither player actions nor server intervention can alter where the puck glides.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),

              // Pre-round Seed Hash
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C0E18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PRE-ROUND SHA256 HASH:',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            widget.roundState.serverSeedHash,
                            style: const TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 10,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _copiedHash ? Icons.check : Icons.copy,
                            size: 14,
                            color: _copiedHash ? const Color(0xFF10B981) : Colors.white.withValues(alpha: 0.5),
                          ),
                          onPressed: () => _copy(widget.roundState.serverSeedHash, true),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Revealed Seed
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C0E18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REVEALED SERVER SEED:',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            widget.roundState.revealedServerSeed ?? 'Reveals when round concludes',
                            style: TextStyle(
                              color: widget.roundState.revealedServerSeed != null
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.4),
                              fontSize: 10,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        if (widget.roundState.revealedServerSeed != null)
                          IconButton(
                            icon: Icon(
                              _copiedSeed ? Icons.check : Icons.copy,
                              size: 14,
                              color: _copiedSeed ? const Color(0xFF10B981) : Colors.white.withValues(alpha: 0.5),
                            ),
                            onPressed: () => _copy(widget.roundState.revealedServerSeed!, false),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: widget.onClose,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Understood',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

