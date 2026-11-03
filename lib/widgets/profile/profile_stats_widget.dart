library;

import 'package:flutter/material.dart';
import '../../models/chat/chat_models.dart';
import '../../services/chat/chat_service.dart';

class ProfileStatsWidget extends StatelessWidget {
  final GamerBioData? customBio;

  const ProfileStatsWidget({super.key, this.customBio});

  @override
  Widget build(BuildContext context) {
    final chatService = ChatService();

    return ValueListenableBuilder<GamerBioData>(
      valueListenable: chatService.userBio,
      builder: (ctx, bioData, _) {
        final bio = customBio ?? bioData;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF131826), Color(0xFF0C101A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF2DD4BF).withValues(alpha: 0.3)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x222DD4BF),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2DD4BF).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.military_tech_rounded, color: Color(0xFF2DD4BF), size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GAMING STATISTICS',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'PvP & Arcade battle performance',
                            style: TextStyle(color: Colors.white38, fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2DD4BF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${bio.winRate}% Win Rate',
                      style: const TextStyle(
                        color: Color(0xFF2DD4BF),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 4 Stat Cards
              Row(
                children: [
                  _buildStatTile('Battles', '${bio.roundsPlayed}', Colors.white),
                  const SizedBox(width: 8),
                  _buildStatTile('Victories', '${bio.roundsWon}', const Color(0xFF10B981)),
                  const SizedBox(width: 8),
                  _buildStatTile('Wagered', '\$${bio.totalWagered.toInt()}', const Color(0xFFFFB800)),
                  const SizedBox(width: 8),
                  _buildStatTile('Best Win', '\$${bio.biggestWin.toInt()}', const Color(0xFF0098EA)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatTile(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF090D15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
    );
  }
}

