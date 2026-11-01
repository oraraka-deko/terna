import 'package:flutter/material.dart';
import 'package:terna/models/bump_game/bump_models.dart';
import 'package:terna/services/bump_game/bump_audio_service.dart';

/// Betting controls for Arena Bump
class BumpBettingControls extends StatefulWidget {
  final BumpRoundStatus status;
  final double userTonBalance;
  final int userStarsBalance;
  final Function(String currency, double amount) onPlaceBet;

  const BumpBettingControls({
    super.key,
    required this.status,
    required this.userTonBalance,
    required this.userStarsBalance,
    required this.onPlaceBet,
  });

  @override
  State<BumpBettingControls> createState() => _BumpBettingControlsState();
}

class _BumpBettingControlsState extends State<BumpBettingControls> {
  String _currency = 'ton'; // 'ton' or 'stars'
  double _tonAmount = 0.5;
  int _starsAmount = 25;
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: _tonAmount.toString());
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _switchCurrency(String curr) {
    BumpAudioService.playClick();
    setState(() {
      _currency = curr;
      if (curr == 'ton') {
        _textController.text = _tonAmount.toString();
      } else {
        _textController.text = _starsAmount.toString();
      }
    });
  }

  void _addAmount(double delta) {
    BumpAudioService.playClick();
    setState(() {
      if (_currency == 'ton') {
        _tonAmount = double.parse((_tonAmount + delta).clamp(0.1, 100.0).toStringAsFixed(2));
        _textController.text = _tonAmount.toString();
      } else {
        _starsAmount = (_starsAmount + delta.toInt()).clamp(10, 10000);
        _textController.text = _starsAmount.toString();
      }
    });
  }

  void _handlePlaceBet() {
    if (!canBet) return;
    final amount = _currency == 'ton' ? _tonAmount : _starsAmount.toDouble();
    widget.onPlaceBet(_currency, amount);
  }

  bool get canBet {
    final isOpen = widget.status == BumpRoundStatus.waitingForPlayers ||
        widget.status == BumpRoundStatus.countdown;
    if (!isOpen) return false;

    if (_currency == 'ton') {
      return _tonAmount >= 0.1 && widget.userTonBalance >= _tonAmount;
    } else {
      return _starsAmount >= 10 && widget.userStarsBalance >= _starsAmount;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF10131F),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Currency & Balance Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: const Color(0xFF181C2C),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _switchCurrency('ton'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _currency == 'ton' ? const Color(0xFF2DD4BF) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'TON',
                          style: TextStyle(
                            color: _currency == 'ton' ? Colors.black : Colors.white.withValues(alpha: 0.6),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _switchCurrency('stars'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _currency == 'stars' ? const Color(0xFFFBBF24) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '⭐ Stars',
                          style: TextStyle(
                            color: _currency == 'stars' ? Colors.black : Colors.white.withValues(alpha: 0.6),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // PLACEHOLDER: demo wallet balance
              Row(
                children: [
                  Text(
                    'Balance: ',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                  ),
                  Text(
                    _currency == 'ton'
                        ? '${widget.userTonBalance.toStringAsFixed(2)} TON'
                        : '${widget.userStarsBalance} ⭐',
                    style: TextStyle(
                      color: _currency == 'ton' ? const Color(0xFF2DD4BF) : const Color(0xFFFBBF24),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2. Quick Chips
          Row(
            children: _currency == 'ton'
                ? [
                    _buildChip('+0.1', () => _addAmount(0.1)),
                    const SizedBox(width: 6),
                    _buildChip('+0.5', () => _addAmount(0.5)),
                    const SizedBox(width: 6),
                    _buildChip('+1.0', () => _addAmount(1.0)),
                    const SizedBox(width: 6),
                    _buildChip('2X', () {
                      _tonAmount = double.parse((_tonAmount * 2).clamp(0.1, 100.0).toStringAsFixed(2));
                      _textController.text = _tonAmount.toString();
                      setState(() {});
                    }),
                  ]
                : [
                    _buildChip('+10', () => _addAmount(10)),
                    const SizedBox(width: 6),
                    _buildChip('+25', () => _addAmount(25)),
                    const SizedBox(width: 6),
                    _buildChip('+50', () => _addAmount(50)),
                    const SizedBox(width: 6),
                    _buildChip('2X', () {
                      _starsAmount = (_starsAmount * 2).clamp(10, 10000);
                      _textController.text = _starsAmount.toString();
                      setState(() {});
                    }),
                  ],
          ),
          const SizedBox(height: 12),

          // 3. Amount Field & Action Button
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141724),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          onChanged: (val) {
                            final parsed = double.tryParse(val);
                            if (parsed != null) {
                              if (_currency == 'ton') {
                                _tonAmount = parsed;
                              } else {
                                _starsAmount = parsed.toInt();
                              }
                              setState(() {});
                            }
                          },
                        ),
                      ),
                      Text(
                        _currency == 'ton' ? 'TON' : '⭐',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 5,
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: canBet ? _handlePlaceBet : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2DD4BF),
                      disabledBackgroundColor: Colors.white.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      widget.status == BumpRoundStatus.battle
                          ? 'BATTLE LIVE'
                          : 'JOIN ARENA',
                      style: TextStyle(
                        color: canBet ? Colors.black : Colors.white.withValues(alpha: 0.3),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF181C2C),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

