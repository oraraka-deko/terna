import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:terna/main.dart';
import 'package:terna/models/roulette/odds.dart';
import 'package:terna/models/roulette/roulette_pocket.dart';
import 'package:terna/models/roulette/vector_wheel.dart';
import 'package:terna/providers/roulette/game_state.dart';
import 'package:terna/widgets/roulette/roulettetableboard.dart';


class RouletteApp extends StatefulWidget {
  const RouletteApp({super.key});

  @override
  State<RouletteApp> createState() => _RouletteAppState();
}

class _RouletteAppState extends State<RouletteApp> {
  final RouletteGameState _gameState = RouletteGameState();

  @override
  void dispose() {
    _gameState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'American Roulette',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF06180D),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFD700),
          secondary: Color(0xFF008837),
          surface: Color(0xFF0E2E18),
        ),
        useMaterial3: true,
      ),
      home: AmericanRouletteGame(gameState: _gameState),
    );
  }
}

class RouletteGameScreen extends StatefulWidget {
  const RouletteGameScreen({super.key});

  @override
  State<RouletteGameScreen> createState() => _RouletteGameScreenState();
}

class _RouletteGameScreenState extends State<RouletteGameScreen> {
  final RouletteGameState _gameState = RouletteGameState();

  @override
  void dispose() {
    _gameState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF06180D),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFD700),
          secondary: Color(0xFF008837),
          surface: Color(0xFF0E2E18),
        ),
        useMaterial3: true,
      ),
      child: AmericanRouletteGame(gameState: _gameState),
    );
  }
}
 
class AmericanRouletteGame extends StatefulWidget {
  final RouletteGameState gameState;

  const AmericanRouletteGame({super.key, required this.gameState});

  @override
  State<AmericanRouletteGame> createState() => _AmericanRouletteGameState();
}

class _AmericanRouletteGameState extends State<AmericanRouletteGame>
    with TickerProviderStateMixin {
  late AnimationController _spinController;
  late AnimationController _pulseController;

  double _currentWheelAngle = 0.0;
  double _currentBallAngle = 0.0;
  double _ballRadiusFactor = 0.0; // 0.0 (hidden), 0.85 (track), 0.45 (pocket)
  VoidCallback? _spinListener;

  String? _winningPocketLabel;
  bool _showResultOverlay = false;
  SpinResult? _lastSpinResult;

  final List<int> _chipValues = [10, 25, 50, 100, 500, 1000];

  @override
  void initState() {
    super.initState();

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    widget.gameState.addListener(_onGameStateChanged);
  }

  @override
  void dispose() {
    widget.gameState.removeListener(_onGameStateChanged);
    _spinController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onGameStateChanged() {
    if (mounted) {
      setState(() {});
      if (widget.gameState.isGameOver && !_spinController.isAnimating) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showGameOverDialog();
        });
      }
    }
  }

  void _handleFeltTap(String betKey) {
    if (widget.gameState.isSpinning) return;

    Set<String> targets = {};
    BetType type = BetType.straight;

    switch (betKey) {
      case 'Red':
        type = BetType.color;
        targets = {
          '1',
          '3',
          '5',
          '7',
          '9',
          '12',
          '14',
          '16',
          '18',
          '19',
          '21',
          '23',
          '25',
          '27',
          '30',
          '32',
          '34',
          '36',
        };
        break;
      case 'Black':
        type = BetType.color;
        targets = {
          '2',
          '4',
          '6',
          '8',
          '10',
          '11',
          '13',
          '15',
          '17',
          '20',
          '22',
          '24',
          '26',
          '28',
          '29',
          '31',
          '33',
          '35',
        };
        break;
      case 'Even':
        type = BetType.evenOdd;
        targets = {for (var i = 2; i <= 36; i += 2) '$i'};
        break;
      case 'Odd':
        type = BetType.evenOdd;
        targets = {for (var i = 1; i <= 35; i += 2) '$i'};
        break;
      case '1-18':
        type = BetType.highLow;
        targets = {for (var i = 1; i <= 18; i++) '$i'};
        break;
      case '19-36':
        type = BetType.highLow;
        targets = {for (var i = 19; i <= 36; i++) '$i'};
        break;
      case '1st 12':
        type = BetType.dozen;
        targets = {for (var i = 1; i <= 12; i++) '$i'};
        break;
      case '2nd 12':
        type = BetType.dozen;
        targets = {for (var i = 13; i <= 24; i++) '$i'};
        break;
      case '3rd 12':
        type = BetType.dozen;
        targets = {for (var i = 25; i <= 36; i++) '$i'};
        break;
      case 'Col 1':
        type = BetType.column;
        targets = {for (var i = 1; i <= 34; i += 3) '$i'};
        break;
      case 'Col 2':
        type = BetType.column;
        targets = {for (var i = 2; i <= 35; i += 3) '$i'};
        break;
      case 'Col 3':
        type = BetType.column;
        targets = {for (var i = 3; i <= 36; i += 3) '$i'};
        break;
      default:
        type = BetType.straight;
        targets = {betKey};
    }

    final placed = widget.gameState.placeBet(betId: betKey, type: type, targets: targets);
    if (placed) {
      try {
        soloud.play(startMatch);
      } catch (_) {}
    }
  }

  Future<void> _startSpin() async {
    if (!widget.gameState.canSpin) return;

    setState(() {
      _showResultOverlay = false;
      _winningPocketLabel = null;
    });

    widget.gameState.setSpinning(true);
    try {
      final serverResult = await widget.gameState.requestSpin();
      final winningPocket = serverResult['winningPocket'] as String;
      final winningIndex =
          americanWheelPockets.indexWhere((pocket) => pocket.label == winningPocket);
      if (winningIndex < 0) {
        throw const FormatException('The backend returned an unknown roulette pocket.');
      }
      final targetPocket = americanWheelPockets[winningIndex];
      final serverPayout = (serverResult['payout'] as num).toInt();
      try {
        soloud.play(spins);
      } catch (_) {}

      const totalPockets = 38;
      final sliceAngle = (2 * math.pi) / totalPockets;

      // Calculate exact wheel rotation target so the server result lands at the pointer.
      final baseTargetAngle = -winningIndex * sliceAngle;
      double targetWheelAngle = baseTargetAngle;
      while (targetWheelAngle < _currentWheelAngle + (6 * 2 * math.pi)) {
        targetWheelAngle += 2 * math.pi;
      }

      // Ball orbits in reverse and lands at 12 o'clock pointer.
      final startBallAngle = _currentBallAngle;
      double targetBallAngle = -math.pi / 2;
      while (targetBallAngle > startBallAngle - (9 * 2 * math.pi)) {
        targetBallAngle -= 2 * math.pi;
      }

      final startWheel = _currentWheelAngle;

      _spinController.reset();

      if (_spinListener != null) {
      _spinController.removeListener(_spinListener!);
      }
      _spinListener = () {
        final progress = _spinController.value;
        final curvedWheel = Curves.decelerate.transform(progress);
        final curvedBall = const Cubic(0.1, 0.9, 0.2, 1.0).transform(progress);

        setState(() {
          _currentWheelAngle =
              startWheel + (targetWheelAngle - startWheel) * curvedWheel;
          _currentBallAngle =
              startBallAngle + (targetBallAngle - startBallAngle) * curvedBall;

          if (progress < 0.70) {
            _ballRadiusFactor = 0.85;
          } else {
            final dropProgress = (progress - 0.70) / 0.30;
            _ballRadiusFactor =
                0.85 - (0.40 * Curves.easeOutBack.transform(dropProgress));
          }
        });
      };
      _spinController.addListener(_spinListener!);

      await _spinController.forward();
      final result = widget.gameState.evaluateRound(
        targetPocket.label,
        serverPayout: serverPayout,
      );
      setState(() {
        _winningPocketLabel = targetPocket.label;
        _lastSpinResult = result;
        _showResultOverlay = true;
      });

      _pulseController.repeat(reverse: true);
    } catch (error) {
      widget.gameState.cancelSpin(error.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Spin failed: $error')),
        );
      }
    }
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFFFFD700), width: 2),
            ),
            title: const Column(
              children: [
                Icon(
                  Icons.sentiment_very_dissatisfied,
                  color: Colors.amberAccent,
                  size: 56,
                ),
                SizedBox(height: 8),
                Text(
                  'GAME OVER',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
            content: const Text(
              'Your Stars balance is empty. Add Stars in Wallet before placing another bet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 15),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'CLOSE',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          ),
    );
  }

  void _showOddsRulesModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (ctx) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.75,
            maxChildSize: 0.9,
            builder:
                (_, scrollController) => Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        width: 45,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white38,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.casino,
                            color: Color(0xFFFFD700),
                            size: 28,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'American Roulette Rules & Odds',
                            style: TextStyle(
                              color: Color(0xFFFFD700),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'American Roulette features 38 pockets: 1 through 36, plus 0 and 00. Place your chips on the felt and press SPIN!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const Divider(color: Colors.white24, height: 24),
                      Expanded(
                        child: ListView.separated(
                          controller: scrollController,
                          itemCount: BetType.values.length,
                          separatorBuilder:
                              (_, _) => const Divider(color: Colors.white10),
                          itemBuilder: (ctx, idx) {
                            final type = BetType.values[idx];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    type.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF005522),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFFFFD700),
                                      ),
                                    ),
                                    child: Text(
                                      'Payout ${type.payoutText}',
                                      style: const TextStyle(
                                        color: Color(0xFFFFD700),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  type.description,
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.gameState;

    return Scaffold(
      backgroundColor: const Color(
        0xFF06180D,
      ), // Deep Luxurious Casino Background
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0E2E18),
            border: Border(
              bottom: BorderSide(color: Color(0xFFFFD700), width: 1.5),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (Navigator.of(context).canPop()) ...[
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Color(0xFFFFD700),
                        size: 20,
                      ),
                      tooltip: 'Back',
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 4),
                  ],

                  // Game Logo
                  const Row(
                    children: [
                      Icon(Icons.stars, color: Color(0xFFFFD700), size: 24),
                      SizedBox(width: 8),
                      Text(
                        'AMERICAN ROULETTE',
                        style: TextStyle(
                          color: Color(0xFFFFD700),
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),

                  // Spin History Chips Bar
                  if (game.spinHistory.isNotEmpty)
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children:
                              game.spinHistory.map((res) {
                                final isZero =
                                    res.winningPocket == '0' ||
                                    res.winningPocket == '00';
                                const redNums = {
                                  1,
                                  3,
                                  5,
                                  7,
                                  9,
                                  12,
                                  14,
                                  16,
                                  18,
                                  19,
                                  21,
                                  23,
                                  25,
                                  27,
                                  30,
                                  32,
                                  34,
                                  36,
                                };
                                final isRed = redNums.contains(
                                  int.tryParse(res.winningPocket),
                                );
                                final bg =
                                    isZero
                                        ? const Color(0xFF008837)
                                        : isRed
                                        ? const Color(0xFFD31A1A)
                                        : const Color(0xFF1A1A1A);

                                return Container(
                                  margin: const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: bg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white54),
                                  ),
                                  child: Text(
                                    res.winningPocket,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                    ),

                  const SizedBox(width: 12),

                  // Rules & Odds Info Button
                  IconButton(
                    icon: const Icon(
                      Icons.help_outline,
                      color: Color(0xFFFFD700),
                    ),
                    tooltip: 'Rules & Odds',
                    onPressed: _showOddsRulesModal,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Bankroll & Status Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: const Color(0xFF0B2113),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Shared wallet balances
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A3822),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFFFD700),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.account_balance_wallet,
                            color: Color(0xFFFFD700),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'BANK: ${game.balance} ⭐',
                            style: const TextStyle(
                              color: Color(0xFFFFD700),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${game.tonBalance.toStringAsFixed(3)} TON',
                            style: const TextStyle(
                              color: Color(0xFF61A9FF),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Status / Feedback Toast Message
                    if (game.statusMessage != null) ...[
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              game.statusMessage!.contains('WINNER')
                                  ? Colors.amber.withValues(alpha: 0.2)
                                  : game.statusMessage!.contains('Insufficient')
                                  ? Colors.red.withValues(alpha: 0.2)
                                  : Colors.blue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                game.statusMessage!.contains('WINNER')
                                    ? Colors.amber
                                    : game.statusMessage!.contains(
                                      'Insufficient',
                                    )
                                    ? Colors.redAccent
                                    : Colors.blueAccent,
                          ),
                        ),
                        child: Text(
                          game.statusMessage!,
                          style: TextStyle(
                            color:
                                game.statusMessage!.contains('WINNER')
                                    ? Colors.amberAccent
                                    : game.statusMessage!.contains(
                                      'Insufficient',
                                    )
                                    ? Colors.redAccent
                                    : Colors.cyanAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],

                    // Active Bet Total
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A3822),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white30),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.casino,
                            color: Colors.white70,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'BET: \$${game.totalBetAmount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
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

            // Main Game Area (Wheel + Felt Board)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    final isWide = constraints.maxWidth > 800;
                    return Flex(
                      direction: isWide ? Axis.horizontal : Axis.vertical,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Vector Wheel Widget
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 320,
                              height: 320,
                              child: AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) {
                                  return CustomPaint(
                                    painter: RouletteWheelPainter(
                                      rotationAngle: _currentWheelAngle,
                                      pockets: americanWheelPockets,
                                      ballAngle: _currentBallAngle,
                                      ballRadiusFactor: _ballRadiusFactor,
                                      highlightedPocket: _winningPocketLabel,
                                      highlightPulse: _pulseController.value,
                                    ),
                                  );
                                },
                              ),
                            ),

                            // Result Celebration Banner Popup Overlay
                            if (_showResultOverlay && _lastSpinResult != null)
                              Positioned(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xEE161B22),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFFFFD700),
                                      width: 2,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black87,
                                        blurRadius: 15,
                                        spreadRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'WINNING POCKET',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.8,
                                          ),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _lastSpinResult!.winningPocket,
                                        style: const TextStyle(
                                          color: Color(0xFFFFD700),
                                          fontSize: 32,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _lastSpinResult!.netGain > 0
                                            ? 'WIN +\$${_lastSpinResult!.netGain}'
                                            : _lastSpinResult!.netGain == 0
                                            ? 'PUSH \$0'
                                            : 'NO WIN -\$${_lastSpinResult!.totalPayout == 0 ? game.totalLastRoundAmount : -_lastSpinResult!.netGain}',
                                        style: TextStyle(
                                          color:
                                              _lastSpinResult!.netGain > 0
                                                  ? Colors.greenAccent
                                                  : _lastSpinResult!.netGain ==
                                                      0
                                                  ? Colors.amberAccent
                                                  : Colors.redAccent,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),

                        SizedBox(
                          width: isWide ? 32 : 0,
                          height: isWide ? 0 : 20,
                        ),

                        // Betting Felt Board
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 680),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: RouletteTableBoard(
                              placedBets: game.placedBets,
                              winningPocket: _winningPocketLabel,
                              onCellTap: _handleFeltTap,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            // Chips Selector & Action Control Bar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFF0E2E18),
                border: Border(
                  top: BorderSide(color: Color(0xFFFFD700), width: 1.5),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Chip Denomination Choice Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children:
                        _chipValues.map((val) {
                          final isSelected = game.selectedChip == val;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: GestureDetector(
                              onTap: () {
                                game.selectChip(val);
                                try {
                                  soloud.play(startMatch);
                                } catch (_) {}
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: isSelected ? 52 : 44,
                                height: isSelected ? 52 : 44,
                                decoration: BoxDecoration(
                                  color: _getChipColor(val),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? Colors.amberAccent
                                            : Colors.white70,
                                    width: isSelected ? 3.0 : 1.5,
                                  ),
                                  boxShadow:
                                      isSelected
                                          ? [
                                            BoxShadow(
                                              color: Colors.amberAccent
                                                  .withValues(alpha: 0.6),
                                              blurRadius: 10,
                                              spreadRadius: 2,
                                            ),
                                          ]
                                          : null,
                                ),
                                child: Center(
                                  child: Text(
                                    '\$$val',
                                    style: TextStyle(
                                      color:
                                          val >= 1000
                                              ? Colors.black
                                              : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: isSelected ? 12 : 10,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),

                  const SizedBox(height: 12),

                  // Action Buttons Row (Clear, Undo, Double, Rebet, SPIN)
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade900,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text(
                          'CLEAR',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed:
                            game.isSpinning || game.placedBets.isEmpty
                                ? null
                                : game.clearBets,
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade900,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.undo, size: 18),
                        label: const Text(
                          'UNDO',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed:
                            game.isSpinning || game.placedBets.isEmpty
                                ? null
                                : game.undoLastBet,
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade900,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.exposure_plus_2, size: 18),
                        label: const Text(
                          'DOUBLE',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed:
                            game.canDouble
                                ? () {
                                  game.doubleBets();
                                  try {
                                    soloud.play(startMatch);
                                  } catch (_) {}
                                }
                                : null,
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade900,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.repeat, size: 18),
                        label: const Text(
                          'REBET',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed:
                            game.canRebet
                                ? () {
                                  game.rebet();
                                  try {
                                    soloud.play(startMatch);
                                  } catch (_) {}
                                }
                                : null,
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              game.canSpin
                                  ? const Color(0xFFFFD700)
                                  : Colors.grey.shade800,
                          foregroundColor:
                              game.canSpin ? Colors.black : Colors.white38,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 14,
                          ),
                          elevation: game.canSpin ? 8 : 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color:
                                  game.canSpin
                                      ? Colors.amberAccent
                                      : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        icon: Icon(
                          Icons.play_arrow,
                          color: game.canSpin ? Colors.black : Colors.white38,
                          size: 24,
                        ),
                        label: const Text(
                          'SPIN',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 1.2,
                          ),
                        ),
                        onPressed: game.canSpin ? _startSpin : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getChipColor(int val) {
    if (val >= 1000) return const Color(0xFFFFD700); // Gold
    if (val >= 500) return const Color(0xFF8E24AA); // Purple
    if (val >= 100) return const Color(0xFF212121); // Black
    if (val >= 50) return const Color(0xFFE53935); // Red
    if (val >= 25) return const Color(0xFF43A047); // Green
    return const Color(0xFF00ACC1); // Cyan
  }
}
