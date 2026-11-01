import 'package:flutter/material.dart';

/// Provably Fair seed verification footer.
class TowerProvablyFairFooter extends StatelessWidget {
  final String serverSeedHash;

  const TowerProvablyFairFooter({
    super.key,
    required this.serverSeedHash,
  });

  @override
  Widget build(BuildContext context) {
    final displayHash = serverSeedHash.length > 20
        ? '${serverSeedHash.substring(0, 16)}...'
        : serverSeedHash;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF1E293B),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(
                Icons.verified_user_rounded,
                color: Color(0xFFA855F7),
                size: 14,
              ),
              SizedBox(width: 6),
              Text(
                'SHA-256 Provably Fair',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 10,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Text(
            displayHash,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

