import 'package:flutter/material.dart';

enum CoinSide {
  sun,
  moon;

  String get displayName => this == CoinSide.sun ? 'Sun' : 'Moon';
  String get emoji => this == CoinSide.sun ? '☀️' : '🌙';

  IconData get icon =>
      this == CoinSide.sun ? Icons.wb_sunny_rounded : Icons.nightlight_round;

  Color get primaryColor =>
      this == CoinSide.sun ? const Color(0xFFFFB300) : const Color(0xFF7C4DFF);

  Color get accentColor =>
      this == CoinSide.sun ? const Color(0xFFFFD54F) : const Color(0xFFB388FF);

  List<Color> get gradientColors => this == CoinSide.sun
      ? [const Color(0xFFFF8F00), const Color(0xFFFFD54F)]
      : [const Color(0xFF4A148C), const Color(0xFF7C4DFF), const Color(0xFFB388FF)];

  String get subtitle => this == CoinSide.sun
      ? 'Radiant Solar Power'
      : 'Mystic Lunar Glow';
}
