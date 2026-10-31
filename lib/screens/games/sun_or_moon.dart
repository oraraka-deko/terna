import 'dart:math';

import 'package:flutter/material.dart';
import 'package:terna/main.dart';
import 'package:terna/models/sun_or_moon/coin_side.dart';
import 'package:terna/models/sun_or_moon/game_engine.dart';
import 'package:terna/widgets/sun_or_moon/betting_panel.dart';
import 'package:terna/widgets/sun_or_moon/celestial_coin.dart';
import 'package:terna/widgets/sun_or_moon/history_drawer.dart';
import 'package:terna/widgets/sun_or_moon/result_banner.dart';
import 'package:terna/widgets/sun_or_moon/starry_background.dart';
import 'package:terna/widgets/sun_or_moon/vault_card.dart';

class SunOrMoonGameScreen extends StatefulWidget {
  const SunOrMoonGameScreen({super.key});

  @override
  State<SunOrMoonGameScreen> createState() => _SunOrMoonGameScreenState();
}

class _SunOrMoonGameScreenState extends State<SunOrMoonGameScreen> {
  final GameEngine _game = GameEngine();
  CoinSide _displayedCoinSide = CoinSide.sun;
  CoinSide _lastSelectedSide = CoinSide.sun;

  @override
  void initState() {
    super.initState();
    _displayedCoinSide = _game.selectedSide;
    _lastSelectedSide = _game.selectedSide;
    _game.addListener(_onGameEngineUpdate);
  }

  @override
  void dispose() {
    _game.removeListener(_onGameEngineUpdate);
    super.dispose();
  }

  void _onGameEngineUpdate() {
    setState(() {
      if (!_game.isFlipping) {
        if (_lastSelectedSide != _game.selectedSide) {
          _displayedCoinSide = _game.selectedSide;
          _lastSelectedSide = _game.selectedSide;
        }
      }
    });
  }

  Future<void> _handleFlip() async {
    if (_game.isBankrupt) {
      _game.claimBankruptcyRestart();
      setState(() {
        _displayedCoinSide = _game.selectedSide;
        _lastSelectedSide = _game.selectedSide;
      });
      return;
    }

    if (_game.isFlipping) return;

    // 1. Determine random outcome in advance for the flip animation target
    final random = Random();
    final systemOutcome = random.nextBool() ? CoinSide.sun : CoinSide.moon;

    // 2. Set displayed coin target to system outcome and start flipping
    setState(() {
      _displayedCoinSide = systemOutcome;
    });
    _game.startFlipping();

    final handle = await soloud.play(flipping);
    soloud.seek(handle, Duration(seconds: 7,milliseconds: 500));
    soloud.setVolume(handle, 10.0);
    // 3. Wait for 3D flip animation duration (1800ms)
    await Future.delayed(const Duration(milliseconds: 1800));

    if (!mounted) return;

    // 4. Resolve the outcome on the game engine
    _game.resolveFlip(forcedOutcome: systemOutcome);

    // Keep displaying the outcome that the coin actually landed on
    setState(() {
      _displayedCoinSide = systemOutcome;
    });

    // If player just went bankrupt, prompt restart modal
    if (_game.isBankrupt && mounted) {
      _showBankruptcyDialog();
    }
  }

  void _showBankruptcyDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1B142F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFFFF5252), width: 1.5),
          ),
          title: const Row(
            children: [
              Icon(Icons.lock_rounded, color: Color(0xFFFF5252), size: 28),
              SizedBox(width: 10),
              Text(
                'SYSTEM LOCKED!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'All your funds have been locked by the system into the System Vault.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5252).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Vault Locked:',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '\$${_game.systemLockedVault}',
                      style: const TextStyle(
                        color: Color(0xFFFF5252),
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _game.claimBankruptcyRestart();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB300),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'CLAIM \$100 RESTART',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showRulesDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1B142F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1.5,
            ),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.help_outline_rounded,
                color: Color(0xFFFFB300),
                size: 26,
              ),
              SizedBox(width: 10),
              Text(
                'How to Play',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RuleItem(
                emoji: '💵',
                title: 'Starting Funds',
                description: 'You start with \$100 in your balance.',
              ),
              const SizedBox(height: 12),
              _RuleItem(
                emoji: '🪙',
                title: 'Choose a Side',
                description:
                    'Pick ☀️ Sun or 🌙 Moon, then choose your bet amount.',
              ),
              const SizedBox(height: 12),
              _RuleItem(
                emoji: '✨',
                title: 'Win Condition (2x Multiplier)',
                description:
                    'If the coin lands on your chosen side, your bet is doubled (2x payout)!',
              ),
              const SizedBox(height: 12),
              _RuleItem(
                emoji: '🔒',
                title: 'Loss Condition (System Locked)',
                description:
                    'If you lose, your bet is seized and locked in the System Vault.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'GOT IT',
                style: TextStyle(
                  color: Color(0xFFFFB300),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openHistorySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.7,
          child: HistoryDrawer(game: _game),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isDesktop = mediaQuery.size.width > 768;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wb_sunny_rounded,
              color: Color(0xFFFFB300),
              size: 20,
            ),
            const SizedBox(width: 6),
            const Text(
              'SUN OR MOON',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.nightlight_round,
              color: const Color(0xFFB388FF),
              size: 18,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Rules',
            icon: const Icon(Icons.help_outline_rounded, color: Colors.white70),
            onPressed: _showRulesDialog,
          ),
          IconButton(
            tooltip: 'Flip History',
            icon: const Icon(Icons.history_rounded, color: Colors.white70),
            onPressed: _openHistorySheet,
          ),
          IconButton(
            tooltip: 'Reset Game',
            icon: const Icon(Icons.restart_alt_rounded, color: Colors.white70),
            onPressed: () {
              _game.resetFullGame();
              setState(() {
                _displayedCoinSide = CoinSide.sun;
                _lastSelectedSide = CoinSide.sun;
              });
            },
          ),
        ],
      ),
      body: StarryBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 650 : double.infinity,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Vault Card (Player Balance, System Vault, Streak)
                    VaultCard(game: _game),

                    const SizedBox(height: 20),

                    // Result Banner
                    ResultBanner(
                      won: _game.lastGameWon,
                      outcome: _game.lastOutcome,
                      betAmount:
                          _game.history.isNotEmpty
                              ? _game.history.first.betAmount
                              : _game.currentBet,
                      isFlipping: _game.isFlipping,
                    ),

                    const SizedBox(height: 24),

                    // 3D Animated Celestial Coin
                    CelestialCoin(
                      side: _displayedCoinSide,
                      isFlipping: _game.isFlipping,
                      size: isDesktop ? 220 : 190,
                      onTap: () {
                        if (!_game.isFlipping && !_game.isBankrupt) {
                          _game.setSelectedSide(
                            _game.selectedSide == CoinSide.sun
                                ? CoinSide.moon
                                : CoinSide.sun,
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 28),

                    // Betting & Side Selection Panel
                    BettingPanel(game: _game, onFlip: _handleFlip),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RuleItem extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;

  const _RuleItem({
    required this.emoji,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
