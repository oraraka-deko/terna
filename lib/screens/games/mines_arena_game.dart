import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:terna/main.dart';
import '../../services/api/gateway_api_service.dart';
import '../../services/wallet/wallet_repository.dart';

enum BoardSize {
  threeByThree(3, 9, 'assets/mines_bomb_game/just_board/slice_01.png'),
  fiveByFive(5, 25, 'assets/mines_bomb_game/just_board/slice_05.png');

  final int dimension;
  final int totalTiles;
  final String boardAsset;
  const BoardSize(this.dimension, this.totalTiles, this.boardAsset);
}

enum BetCurrency { ton, stars }

enum GamePhase { idle, playing, cashedOut, exploded }

class MinesArenaGameScreen extends StatefulWidget {
  const MinesArenaGameScreen({super.key});

  @override
  State<MinesArenaGameScreen> createState() => _MinesArenaGameScreenState();
}

class _MinesArenaGameScreenState extends State<MinesArenaGameScreen>
    with TickerProviderStateMixin {
  // Game Setup & Balance
  double get _tonBalance => WalletRepository().tonBalance.value;
  int get _starsBalance => WalletRepository().starsBalance.value;
  String? _currentRoundId;
  bool _isSubmitting = false;
  double? _serverNextMultiplier;

  void _onBalanceChanged() {
    if (mounted) setState(() {});
  }
  BetCurrency _selectedCurrency = BetCurrency.ton;
  double _betAmountTon = 0.1;
  int _betAmountStars = 10;

  BoardSize _boardSize = BoardSize.threeByThree;
  int _mineCount = 3;

  // Active Match State
  GamePhase _phase = GamePhase.idle;
  final Set<int> _mineIndices = {};
  final Set<int> _revealedGemIndices = {};
  int? _explodedIndex;
  double _currentMultiplier = 1.0;

  // Timer
  Timer? _gameTimer;
  int _secondsRemaining = 300; // 5:00

  // Animation Controllers for tiles
  final Map<int, AnimationController> _tileControllers = {};

  @override
  void initState() {
    super.initState();
    _clampMines();
    WalletRepository().tonBalance.addListener(_onBalanceChanged);
    WalletRepository().starsBalance.addListener(_onBalanceChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreActiveRound();
    });
  }

  @override
  void dispose() {
    WalletRepository().tonBalance.removeListener(_onBalanceChanged);
    WalletRepository().starsBalance.removeListener(_onBalanceChanged);
    _gameTimer?.cancel();
    for (final c in _tileControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _clampMines() {
    final maxMines = _boardSize.totalTiles - 1;
    if (_mineCount > maxMines) {
      _mineCount = maxMines;
    } else if (_mineCount < 1) {
      _mineCount = 1;
    }
  }

  int get _maxMines => _boardSize.totalTiles - 1;
  int get _totalSafeGems => _boardSize.totalTiles - _mineCount;
  int get _safeGemsFound => _revealedGemIndices.length;

  double _calculateMultiplier(int gemsFound) {
    if (gemsFound <= 0) return 1.0;
    double prob = 1.0;
    for (int i = 0; i < gemsFound; i++) {
      prob *= (_boardSize.totalTiles - _mineCount - i) /
          (_boardSize.totalTiles - i);
    }
    const houseEdge = 0.05;
    final mult = (1.0 - houseEdge) / prob;
    return (mult * 100).round() / 100.0;
  }

  double get _nextMultiplier =>
      _serverNextMultiplier ?? _calculateMultiplier(_safeGemsFound + 1);

  double get _currentPayout {
    if (_selectedCurrency == BetCurrency.ton) {
      return (_betAmountTon * _currentMultiplier);
    } else {
      return (_betAmountStars * _currentMultiplier);
    }
  }

  double get _nextPayout {
    if (_selectedCurrency == BetCurrency.ton) {
      return (_betAmountTon * _nextMultiplier);
    } else {
      return (_betAmountStars * _nextMultiplier);
    }
  }

  void _startTimer() {
    _gameTimer?.cancel();
    _secondsRemaining = 300;
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
        _cashOut();
      }
    });
  }

  void _prepareTileControllers(int tileCount) {
    for (final controller in _tileControllers.values) {
      controller.dispose();
    }
    _tileControllers.clear();
    for (var index = 0; index < tileCount; index++) {
      _tileControllers[index] = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 350),
      );
    }
  }

  Future<bool> _restoreActiveRound() async {
    try {
      final response = await GatewayApiService().getActiveMines();
      if (!mounted) return false;
      final active = response['activeRound'];
      if (active is! Map<String, dynamic>) return false;
      final roundId = active['roundId'];
      final amount = active['amount'];
      final currency = active['currency'];
      final gridSize = active['gridSize'];
      final mineCount = active['mineCount'];
      if (roundId is! String ||
          amount is! num ||
          !['ton', 'stars'].contains(currency) ||
          gridSize is! num ||
          mineCount is! num) {
        throw const FormatException('The backend returned an invalid active Mines round.');
      }

      final restoredGridSize = gridSize.toInt() == 25 ? BoardSize.fiveByFive : BoardSize.threeByThree;
      final revealed = (active['revealedTiles'] as List<dynamic>? ?? const [])
          .whereType<num>()
          .map((tile) => tile.toInt())
          .toSet();
      _prepareTileControllers(restoredGridSize.totalTiles);
      setState(() {
        _currentRoundId = roundId;
        _selectedCurrency = currency == 'stars' ? BetCurrency.stars : BetCurrency.ton;
        _boardSize = restoredGridSize;
        _mineCount = mineCount.toInt();
        _clampMines();
        if (_selectedCurrency == BetCurrency.stars) {
          _betAmountStars = amount.toInt();
        } else {
          _betAmountTon = amount.toDouble();
        }
        _revealedGemIndices
          ..clear()
          ..addAll(revealed);
        _mineIndices.clear();
        _explodedIndex = null;
        _currentMultiplier =
            (active['currentMultiplier'] as num?)?.toDouble() ?? 1;
        _serverNextMultiplier = null;
        _phase = GamePhase.playing;
        _isSubmitting = false;
      });
      for (final tile in revealed) {
        _tileControllers[tile]?.forward();
      }
      _startTimer();
      await WalletRepository().refreshBalances();
      return true;
    } catch (error) {
      if (mounted) _showToast('Unable to restore active Mines round: $error');
      return false;
    }
  }

  Future<void> _startMatch() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final response = await GatewayApiService().startMines(
        amount: _selectedCurrency == BetCurrency.ton
            ? _betAmountTon
            : _betAmountStars.toDouble(),
        currency: _selectedCurrency == BetCurrency.ton ? 'ton' : 'stars',
        gridSize: _boardSize.totalTiles,
        mineCount: _mineCount,
      );
      final roundId = response['roundId'];
      if (response['success'] != true || roundId is! String || roundId.isEmpty) {
        throw StateError(
          response['error']?.toString() ?? 'The backend did not start a Mines round.',
        );
      }

      if (!mounted) return;
      _prepareTileControllers(_boardSize.totalTiles);

      setState(() {
        _currentRoundId = roundId;
        _mineIndices.clear();
        _revealedGemIndices.clear();
        _explodedIndex = null;
        _currentMultiplier = 1;
        _serverNextMultiplier = (response['nextMultiplier'] as num?)?.toDouble();
        _phase = GamePhase.playing;
        _isSubmitting = false;
      });
      _startTimer();
      await WalletRepository().refreshBalances();
      try {
        soloud.play(startMatch);
      } catch (_) {}
    } catch (error) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        if (!await _restoreActiveRound()) {
          _showToast('Unable to start Mines round: $error');
        }
      }
    }
  }

  Future<void> _handleTileTap(int index) async {
    final roundId = _currentRoundId;
    if (_phase != GamePhase.playing || roundId == null || _isSubmitting) return;
    if (_revealedGemIndices.contains(index) || _explodedIndex != null) return;

    setState(() => _isSubmitting = true);
    try {
      final response = await GatewayApiService().revealMinesTile(
        roundId: roundId,
        tileIndex: index,
      );
      if (!mounted) return;
      final status = response['status'];
      final isMine = response['isMine'];
      if (response['revealedTile'] != index ||
          isMine is! bool ||
          !['safe', 'busted', 'cashed_out'].contains(status)) {
        throw StateError(
          response['error']?.toString() ?? 'The backend returned an invalid Mines result.',
        );
      }

      final revealed = (response['revealedTiles'] as List<dynamic>? ?? const [])
          .whereType<num>()
          .map((tile) => tile.toInt())
          .toSet();
      final mines = (response['minePositions'] as List<dynamic>? ?? const [])
          .whereType<num>()
          .map((tile) => tile.toInt())
          .toSet();
      final serverMultiplier =
          (response['currentMultiplier'] as num?)?.toDouble() ?? _currentMultiplier;
      final nextMultiplier = (response['nextMultiplier'] as num?)?.toDouble();

      if (status == 'safe') {
        if (isMine) {
          throw StateError('The backend marked a safe tile as a mine.');
        }
        try {
          soloud.play(notBomb);
        } catch (_) {}
        HapticFeedback.lightImpact();
        _tileControllers[index]?.forward();
        setState(() {
          _revealedGemIndices
            ..clear()
            ..addAll(revealed);
          _currentMultiplier = serverMultiplier;
          _serverNextMultiplier = nextMultiplier;
          _isSubmitting = false;
        });
        return;
      }

      _gameTimer?.cancel();
      _mineIndices
        ..clear()
        ..addAll(mines);
      if (status == 'busted') {
        try {
          soloud.play(bombEnd);
        } catch (_) {}
        HapticFeedback.heavyImpact();
        setState(() {
          _revealedGemIndices
            ..clear()
            ..addAll(revealed.where((tile) => !mines.contains(tile)));
          _explodedIndex = index;
          _currentMultiplier = 0;
          _serverNextMultiplier = null;
          _phase = GamePhase.exploded;
          _isSubmitting = false;
        });
        for (final tile in _revealedGemIndices) {
          _tileControllers[tile]?.forward();
        }
        for (final mine in _mineIndices) {
          _tileControllers[mine]?.forward();
        }
        return;
      }

      await WalletRepository().refreshBalances();
      if (!mounted) return;
      final payout = (response['payout'] as num?)?.toDouble();
      if (payout == null) {
        throw StateError('The backend did not return the Mines payout.');
      }
      setState(() {
        _revealedGemIndices
          ..clear()
          ..addAll(revealed);
        _currentMultiplier = serverMultiplier;
        _serverNextMultiplier = null;
        _phase = GamePhase.cashedOut;
        _isSubmitting = false;
      });
      for (final tile in _revealedGemIndices) {
        _tileControllers[tile]?.forward();
      }
      for (final mine in _mineIndices) {
        _tileControllers[mine]?.forward();
      }
      _showWinModal(payout, true);
    } catch (error) {
      if (!mounted) return;
      _tileControllers[index]?.reset();
      setState(() => _isSubmitting = false);
      _showToast('Unable to reveal tile: $error');
    }
  }

  Future<void> _cashOut() async {
    final roundId = _currentRoundId;
    if (_phase != GamePhase.playing || roundId == null || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final response = await GatewayApiService().cashoutMines(roundId: roundId);
      final payout = (response['payout'] as num?)?.toDouble();
      if (response['status'] != 'cashed_out' || payout == null) {
        throw StateError(
          response['error']?.toString() ?? 'The backend did not confirm the Mines cashout.',
        );
      }
      await WalletRepository().refreshBalances();
      if (!mounted) return;
      _gameTimer?.cancel();
      _mineIndices
        ..clear()
        ..addAll(
          (response['minePositions'] as List<dynamic>? ?? const [])
              .whereType<num>()
              .map((tile) => tile.toInt()),
        );
      setState(() {
        _currentMultiplier =
            (response['currentMultiplier'] as num?)?.toDouble() ?? _currentMultiplier;
        _serverNextMultiplier = null;
        _phase = GamePhase.cashedOut;
        _isSubmitting = false;
      });
      for (final mine in _mineIndices) {
        _tileControllers[mine]?.forward();
      }
      try {
        soloud.play(notBomb);
      } catch (_) {}
      HapticFeedback.mediumImpact();
      _showWinModal(payout, false);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showToast('Unable to cash out: $error');
    }
  }

  void _showWinModal(double amount, bool isJackpot) {
    showDialog(
      context: context,
      builder: (ctx) {
        final currencySymbol = _selectedCurrency == BetCurrency.ton ? 'TON' : 'Stars';
        return AlertDialog(
          backgroundColor: const Color(0xFF161F33),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFF00E5FF), width: 2),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.18),
                ),
                child: const Center(
                  child: Text('💎', style: TextStyle(fontSize: 40)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isJackpot ? 'ALL GEMS CLEARED!' : 'VICTORY CASHOUT',
                style: const TextStyle(
                  color: Color(0xFF00E5FF),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_currentMultiplier.toStringAsFixed(2)}x',
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '+${_selectedCurrency == BetCurrency.ton ? amount.toStringAsFixed(3) : amount.round()} $currencySymbol',
                style: const TextStyle(
                  color: Color(0xFF00E676),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('CONTINUE', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatTimer(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final currencyName = _selectedCurrency == BetCurrency.ton ? 'TON' : 'Stars';

    return Scaffold(
      backgroundColor: const Color(0xFF070B14), // Deep Space Casino Navy
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                children: [
                  // 1. Top Header (< Hub, MINES ARENA, ⏱ 05:00)
                  _buildTopHeader(),

                  const SizedBox(height: 12),

                  // 2. Next Multiplier ➔ Payout Banner
                  _buildMultiplierBanner(),

                  const SizedBox(height: 12),

                  // 3. Game Settings Row (Mines Count & Board Size)
                  _buildSettingsRow(),

                  const SizedBox(height: 16),

                  // 4. Game Board (3x3 or 5x5)
                  _buildGameBoard(),

                  const SizedBox(height: 16),

                  // 5. Bet Asset & Controls Panel
                  _buildBettingCard(currencyName),

                  const SizedBox(height: 8),

                  // 6. Stake Valuation Footer
                  _buildStakeValuation(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Header Widget
  Widget _buildTopHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // < Hub Button
        GestureDetector(
          onTap: () => Navigator.of(context).maybePop(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF141A29),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF232C42)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back_rounded, size: 16, color: Colors.white70),
                SizedBox(width: 6),
                Text(
                  'Hub',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Center Title (Gold Bomb Badge + MINES ARENA)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2210),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
              ),
              child: const Icon(
                Icons.brightness_low_rounded,
                color: Color(0xFFFFD700),
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MINES ARENA',
                  style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  'PROVABLY FAIR 3D',
                  style: TextStyle(
                    color: Color(0xFF00E5FF),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),

        // ⏱ 05:00 Timer Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF141A29),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF232C42)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.access_time_rounded, size: 15, color: Colors.white70),
              const SizedBox(width: 5),
              Text(
                _formatTimer(_secondsRemaining),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Multiplier / Payout Card
  Widget _buildMultiplierBanner() {
    final currencyName = _selectedCurrency == BetCurrency.ton ? 'TON' : 'Stars';
    final payoutStr = _selectedCurrency == BetCurrency.ton
        ? _nextPayout.toStringAsFixed(3)
        : _nextPayout.round().toString();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1220),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E283D)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Next Multiplier ➔ Payout
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'NEXT MULTIPLIER ➔ PAYOUT',
                style: TextStyle(
                  color: Color(0xFF7A889B),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '${_nextMultiplier.toStringAsFixed(2)}x',
                    style: const TextStyle(
                      color: Color(0xFF00E5FF),
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Text(
                    ' ➔ ',
                    style: TextStyle(color: Color(0xFFE040FB), fontSize: 14),
                  ),
                  Text(
                    '$payoutStr $currencyName',
                    style: const TextStyle(
                      color: Color(0xFF00E676),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Safe Gems Found
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'SAFE GEMS FOUND',
                style: TextStyle(
                  color: Color(0xFF7A889B),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text('💎', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    '$_safeGemsFound / $_totalSafeGems',
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Settings Row: Mines Stepper & Board Toggle
  Widget _buildSettingsRow() {
    final isLocked = _phase == GamePhase.playing;

    return Row(
      children: [
        // Mines Stepper
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1220),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1E283D)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.brightness_low_rounded, color: Color(0xFFFF5252), size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Mines',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildStepperBtn(
                      icon: Icons.chevron_left_rounded,
                      onTap: isLocked || _mineCount <= 1
                          ? null
                          : () {
                              setState(() {
                                _mineCount--;
                                _serverNextMultiplier = null;
                              });
                            },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '$_mineCount',
                        style: const TextStyle(
                          color: Color(0xFFFF5252),
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    _buildStepperBtn(
                      icon: Icons.chevron_right_rounded,
                      onTap: isLocked || _mineCount >= _maxMines
                          ? null
                          : () {
                              setState(() {
                                _mineCount++;
                                _serverNextMultiplier = null;
                              });
                            },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Board Size Switch (3x3 vs 5x5)
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1220),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1E283D)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Color(0xFF00E5FF), size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Board',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildBoardSizePill(
                      label: '3×3',
                      isSelected: _boardSize == BoardSize.threeByThree,
                      onTap: isLocked
                          ? null
                          : () {
                              setState(() {
                                _boardSize = BoardSize.threeByThree;
                                _clampMines();
                                _serverNextMultiplier = null;
                              });
                            },
                    ),
                    const SizedBox(width: 4),
                    _buildBoardSizePill(
                      label: '5×5',
                      isSelected: _boardSize == BoardSize.fiveByFive,
                      onTap: isLocked
                          ? null
                          : () {
                              setState(() {
                                _boardSize = BoardSize.fiveByFive;
                                _clampMines();
                                _serverNextMultiplier = null;
                              });
                            },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepperBtn({required IconData icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          try {
            soloud.play(startMatch);
          } catch (_) {}
          onTap();
        }
      },
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: const Color(0xFF1E283D),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 16,
          color: onTap != null ? Colors.white : Colors.white24,
        ),
      ),
    );
  }

  Widget _buildBoardSizePill({
    required String label,
    required bool isSelected,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00E5FF) : const Color(0xFF141A29),
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                    blurRadius: 6,
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white60,
            fontSize: 11.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  // Game Board Grid with Metallic Frame
  Widget _buildGameBoard() {
    final dim = _boardSize.dimension;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 380),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0B101D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E2940), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _boardSize.totalTiles,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: dim,
            crossAxisSpacing: dim == 3 ? 12 : 8,
            mainAxisSpacing: dim == 3 ? 12 : 8,
          ),
          itemBuilder: (context, index) {
            return _buildTile(index);
          },
        ),
      ),
    );
  }

  // Interactive 3D Flipping Tile
  Widget _buildTile(int index) {
    final isGem = _revealedGemIndices.contains(index);
    final isExploded = _explodedIndex == index;
    final isOtherMine = _phase != GamePhase.playing &&
        _phase != GamePhase.idle &&
        _mineIndices.contains(index) &&
        !isExploded;

    final controller = _tileControllers[index];

    return GestureDetector(
      onTap: () => _handleTileTap(index),
      child: AnimatedBuilder(
        animation: controller ?? const AlwaysStoppedAnimation(0.0),
        builder: (context, child) {
          final animValue = controller?.value ?? 0.0;
          final angle = animValue * math.pi;
          final isFront = angle < (math.pi / 2);

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.002)
              ..rotateY(angle),
            child: isFront
                ? _buildClosedTile()
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: isExploded
                        ? _buildBombTile(isPrimaryHit: true)
                        : isOtherMine
                            ? _buildBombTile(isPrimaryHit: false)
                            : isGem
                                ? _buildGemTile()
                                : _buildClosedTile(),
                  ),
          );
        },
      ),
    );
  }

  // Closed unrevealed tile
  Widget _buildClosedTile() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF151D2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF283652), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 4,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Image.asset(
          'assets/mines_bomb_game/UI_assets_v2/slice_02.png',
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.05),
              border: Border.all(color: Colors.white24),
            ),
          ),
        ),
      ),
    );
  }

  // Revealed Gem Tile
  Widget _buildGemTile() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A2E2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00E5FF), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Center(
        child: Image.asset(
          'assets/mines_bomb_game/UI_assets/slice_08.png',
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const Text('💎', style: TextStyle(fontSize: 32)),
        ),
      ),
    );
  }

  // Revealed Bomb Tile
  Widget _buildBombTile({required bool isPrimaryHit}) {
    return Container(
      decoration: BoxDecoration(
        color: isPrimaryHit ? const Color(0xFF3E1212) : const Color(0xFF261010),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPrimaryHit ? const Color(0xFFFF1744) : const Color(0xFFB71C1C),
          width: isPrimaryHit ? 2.5 : 1.5,
        ),
        boxShadow: isPrimaryHit
            ? [
                BoxShadow(
                  color: const Color(0xFFFF1744).withValues(alpha: 0.6),
                  blurRadius: 14,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Image.asset(
          'assets/mines_bomb_game/UI_assets/slice_16.png',
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const Text('💣', style: TextStyle(fontSize: 32)),
        ),
      ),
    );
  }

  // Betting Controls Panel
  Widget _buildBettingCard(String currencyName) {
    final isPlaying = _phase == GamePhase.playing;
    final canCashOut = isPlaying && _safeGemsFound > 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1220),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1E283D)),
      ),
      child: Column(
        children: [
          // Row 1: BET ASSET + Currency Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'BET ASSET',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Avail: ${_selectedCurrency == BetCurrency.ton ? "💎 ${_tonBalance.toStringAsFixed(2)} TON" : "★ $_starsBalance Stars"}',
                    style: const TextStyle(
                      color: Color(0xFF7A889B),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildCurrencyPill(
                    label: 'TON',
                    icon: '💎',
                    isSelected: _selectedCurrency == BetCurrency.ton,
                    onTap: isPlaying
                        ? null
                        : () {
                            setState(() {
                              _selectedCurrency = BetCurrency.ton;
                            });
                          },
                  ),
                  const SizedBox(width: 6),
                  _buildCurrencyPill(
                    label: 'Stars',
                    icon: '★',
                    isSelected: _selectedCurrency == BetCurrency.stars,
                    onTap: isPlaying
                        ? null
                        : () {
                            setState(() {
                              _selectedCurrency = BetCurrency.stars;
                            });
                          },
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Row 2: AMOUNT Input Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF131A2B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF222C44)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'AMOUNT',
                  style: TextStyle(
                    color: Color(0xFF7A889B),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      _selectedCurrency == BetCurrency.ton
                          ? _betAmountTon.toStringAsFixed(2)
                          : '$_betAmountStars',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      currencyName,
                      style: const TextStyle(
                        color: Color(0xFF00E5FF),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Row 3: Quick Action Chips (+0.1, +0.2, +0.5, Max, Clear)
          Row(
            children: [
              _buildQuickChip(
                '+0.1',
                onTap: isPlaying
                    ? null
                    : () {
                        setState(() {
                          if (_selectedCurrency == BetCurrency.ton) {
                            _betAmountTon = (_betAmountTon + 0.1).clamp(0.01, _tonBalance);
                          } else {
                            _betAmountStars = (_betAmountStars + 5).clamp(1, _starsBalance);
                          }
                        });
                      },
              ),
              const SizedBox(width: 6),
              _buildQuickChip(
                '+0.2',
                onTap: isPlaying
                    ? null
                    : () {
                        setState(() {
                          if (_selectedCurrency == BetCurrency.ton) {
                            _betAmountTon = (_betAmountTon + 0.2).clamp(0.01, _tonBalance);
                          } else {
                            _betAmountStars = (_betAmountStars + 10).clamp(1, _starsBalance);
                          }
                        });
                      },
              ),
              const SizedBox(width: 6),
              _buildQuickChip(
                '+0.5',
                onTap: isPlaying
                    ? null
                    : () {
                        setState(() {
                          if (_selectedCurrency == BetCurrency.ton) {
                            _betAmountTon = (_betAmountTon + 0.5).clamp(0.01, _tonBalance);
                          } else {
                            _betAmountStars = (_betAmountStars + 25).clamp(1, _starsBalance);
                          }
                        });
                      },
              ),
              const SizedBox(width: 6),
              _buildQuickChip(
                'Max',
                onTap: isPlaying
                    ? null
                    : () {
                        setState(() {
                          if (_selectedCurrency == BetCurrency.ton) {
                            _betAmountTon = _tonBalance > 0 ? _tonBalance : 0.1;
                          } else {
                            _betAmountStars = _starsBalance > 0 ? _starsBalance : 10;
                          }
                        });
                      },
              ),
              const SizedBox(width: 6),
              _buildQuickChip(
                'Clear',
                isClear: true,
                onTap: isPlaying
                    ? null
                    : () {
                        setState(() {
                          if (_selectedCurrency == BetCurrency.ton) {
                            _betAmountTon = 0.1;
                          } else {
                            _betAmountStars = 10;
                          }
                        });
                      },
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Big Glowing Action Button (START MATCH vs CASH OUT)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: canCashOut
                    ? const Color(0xFF00E676)
                    : const Color(0xFFFF9800),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                shadowColor: canCashOut
                    ? const Color(0xFF00E676).withValues(alpha: 0.5)
                    : const Color(0xFFFF9800).withValues(alpha: 0.5),
              ),
              onPressed: isPlaying
                  ? (canCashOut ? () => _cashOut() : null)
                  : _startMatch,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    canCashOut
                        ? Icons.diamond_rounded
                        : Icons.brightness_low_rounded,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    canCashOut
                        ? 'CASH OUT (${_currentPayout.toStringAsFixed(3)} $currencyName)'
                        : isPlaying
                            ? 'FIND GEMS'
                            : 'START MATCH',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyPill({
    required String label,
    required String icon,
    required bool isSelected,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00E5FF) : const Color(0xFF141A29),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white70,
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickChip(String label, {bool isClear = false, VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (onTap != null) {
            try {
              soloud.play(startMatch);
            } catch (_) {}
            onTap();
          }
        },
        child: Container(
          height: 32,
          decoration: BoxDecoration(
            color: isClear ? const Color(0xFF2C1318) : const Color(0xFF161F33),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isClear ? const Color(0xFFFF5252).withValues(alpha: 0.4) : const Color(0xFF253350),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isClear ? const Color(0xFFFF5252) : const Color(0xFF00E5FF),
              fontWeight: FontWeight.w800,
              fontSize: 11.5,
            ),
          ),
        ),
      ),
    );
  }

  // Stake Valuation Footer
  Widget _buildStakeValuation() {
    final stake = _selectedCurrency == BetCurrency.ton
        ? '${_betAmountTon.toStringAsFixed(3)} TON'
        : '$_betAmountStars Stars';

    return Text(
      'Bet amount: $stake',
      style: const TextStyle(
        color: Color(0xFF556277),
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
