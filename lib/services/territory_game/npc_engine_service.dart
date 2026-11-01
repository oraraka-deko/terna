import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:terna/models/territory_game/territory_models.dart';
import 'package:terna/services/territory_game/territory_slicing_service.dart';

/// NPC player generator from assets/npc/users_202610120424.csv
class NpcEngineService {
  static final List<NpcProfile> _cachedNpcs = [];
  static bool _isLoaded = false;
  static final math.Random _random = math.Random();

  /// Loads NPC dummy database from CSV
  static Future<void> init() async {
    if (_isLoaded && _cachedNpcs.isNotEmpty) return;

    try {
      final csvString = await rootBundle.loadString('assets/npc/users_202610120424.csv');
      final lines = const LineSplitter().convert(csvString);

      // Skip header line
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final parts = _parseCsvLine(line);
        if (parts.length >= 6) {
          final userId = parts[0];
          final username = parts[2];
          final firstName = parts[3];
          final lastName = parts[4];
          final rawAvatar = parts[5];

          String avatarAsset = '';
          if (rawAvatar.isNotEmpty) {
            // Local asset file in assets/npc/avatars/<userId>.jpg
            avatarAsset = 'assets/npc/avatars/$userId.jpg';
          }

          _cachedNpcs.add(NpcProfile(
            userId: userId,
            username: username,
            firstName: firstName,
            lastName: lastName,
            avatarAssetPath: avatarAsset,
          ));
        }
      }
      _isLoaded = true;
    } catch (_) {
      // Fallback fallback simulated players if bundle load fails
      _loadFallbackNpcs();
    }
  }

  static void _loadFallbackNpcs() {
    _cachedNpcs.addAll([
      const NpcProfile(
        userId: '7660412004',
        username: 'amsexyledy',
        firstName: '#святая',
        lastName: '',
        avatarAssetPath: 'assets/npc/avatars/7660412004.jpg',
      ),
      const NpcProfile(
        userId: '1965297855',
        username: 'Jevga22',
        firstName: 'ноунейм',
        lastName: '',
        avatarAssetPath: 'assets/npc/avatars/1965297855.jpg',
      ),
      const NpcProfile(
        userId: '6148607842',
        username: 'ncuxvv',
        firstName: 'DENFLI',
        lastName: '',
        avatarAssetPath: 'assets/npc/avatars/6148607842.jpg',
      ),
      const NpcProfile(
        userId: '8146663698',
        username: 'nominanome',
        firstName: 'mina',
        lastName: '',
        avatarAssetPath: 'assets/npc/avatars/8146663698.jpg',
      ),
      const NpcProfile(
        userId: '7626302101',
        username: 'wdymtho',
        firstName: 'kabooom',
        lastName: '',
        avatarAssetPath: 'assets/npc/avatars/7626302101.jpg',
      ),
      const NpcProfile(
        userId: '1907083243',
        username: 'iliberally',
        firstName: 'Haideco',
        lastName: '',
        avatarAssetPath: 'assets/npc/avatars/1907083243.jpg',
      ),
    ]);
    _isLoaded = true;
  }

  /// Parses a comma-separated line respecting quotes
  static List<String> _parseCsvLine(String line) {
    final List<String> result = [];
    final StringBuffer sb = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final c = line[i];
      if (c == '"') {
        inQuotes = !inQuotes;
      } else if (c == ',' && !inQuotes) {
        result.add(sb.toString().trim());
        sb.clear();
      } else {
        sb.write(c);
      }
    }
    result.add(sb.toString().trim());
    return result;
  }

  /// Gets a random NPC profile
  static NpcProfile getRandomNpc([Set<String>? excludedUserIds]) {
    if (_cachedNpcs.isEmpty) {
      _loadFallbackNpcs();
    }
    final eligible = (excludedUserIds != null && excludedUserIds.isNotEmpty)
        ? _cachedNpcs.where((n) => !excludedUserIds.contains(n.userId)).toList()
        : _cachedNpcs;

    if (eligible.isEmpty) return _cachedNpcs.first;
    return eligible[_random.nextInt(eligible.length)];
  }

  /// Generates an NPC player bet
  static PlayerBet generateNpcBet({
    required int index,
    Set<String>? existingPlayerIds,
    String preferredCurrency = 'ton',
  }) {
    final npc = getRandomNpc(existingPlayerIds);
    final color = kVibrantTerritoryColors[(index + 1) % kVibrantTerritoryColors.length];

    final isTon = preferredCurrency == 'ton' || _random.nextBool();
    double amount;
    double totalBet;

    if (isTon) {
      // 0.2 to 2.5 TON
      final rawAmount = 0.2 + (_random.nextInt(24) * 0.1);
      amount = double.parse(rawAmount.toStringAsFixed(2));
      totalBet = amount * 10.0;
    } else {
      // 25 to 250 Stars
      amount = (25 + _random.nextInt(225)).toDouble();
      totalBet = amount / 10.0;
    }

    // PLACEHOLDER: simulated NPC bet
    return PlayerBet(
      playerId: 'npc_${npc.userId}',
      username: npc.displayName,
      firstName: npc.firstName,
      avatar: npc.avatarAssetPath,
      color: color,
      currency: isTon ? 'ton' : 'stars',
      amount: amount,
      totalBet: totalBet,
      isPlaceholder: true,
    );
  }
}

