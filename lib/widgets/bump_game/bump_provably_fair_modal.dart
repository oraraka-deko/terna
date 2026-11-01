import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:terna/services/bump_game/bump_audio_service.dart';

/// Provably fair explanation and seed hash verification modal for Arena Bump
class BumpProvablyFairModal extends StatefulWidget {
  final String serverSeedHash;
  final String? revealedServerSeed;
  final VoidCallback onClose;

  const BumpProvablyFairModal({
    super.key,
    required this.serverSeedHash,
    required this.revealedServerSeed,
    required this.onClose,
  });

  @override
  State<BumpProvablyFairModal> createState() => _BumpProvablyFairModalState();
}

class _BumpProvablyFairModalState extends State<BumpProvablyFairModal> {
  bool _copiedHash = false;
  bool _copiedSeed = false;

  void _copy(String text, bool isHash) {
    BumpAudioService.playClick();
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
                'Arena Bump seed hashes are cryptographically generated before countdown starts. Edge hazard positions, open durations, and initial launch impulses are derived deterministically, ensuring 100% fair battle outcomes.',
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
                            widget.serverSeedHash,
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
                          onPressed: () => _copy(widget.serverSeedHash, true),
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
                            widget.revealedServerSeed ?? 'Revealed when round concludes',
                            style: TextStyle(
                              color: widget.revealedServerSeed != null
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.4),
                              fontSize: 10,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        if (widget.revealedServerSeed != null)
                          IconButton(
                            icon: Icon(
                              _copiedSeed ? Icons.check : Icons.copy,
                              size: 14,
                              color: _copiedSeed ? const Color(0xFF10B981) : Colors.white.withValues(alpha: 0.5),
                            ),
                            onPressed: () => _copy(widget.revealedServerSeed!, false),
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

