import 'package:flutter/material.dart';
import '../../features/plinko_game/view_models/plinko_game_view_model.dart';
import '../../models/plinko_game/plinko_models.dart';

/// Betting controls panel for Plinko (amount input, presets dock, balance display).
class PlinkoBetControlsWidget extends StatefulWidget {
  final PlinkoGameViewModel viewModel;

  const PlinkoBetControlsWidget({
    super.key,
    required this.viewModel,
  });

  @override
  State<PlinkoBetControlsWidget> createState() => _PlinkoBetControlsWidgetState();
}

class _PlinkoBetControlsWidgetState extends State<PlinkoBetControlsWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.viewModel.betAmount.toString(),
    );
  }

  @override
  void didUpdateWidget(covariant PlinkoBetControlsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentTextVal = double.tryParse(_controller.text);
    if (currentTextVal != widget.viewModel.betAmount) {
      _controller.text = widget.viewModel.currency == PlinkoCurrency.ton
          ? widget.viewModel.betAmount.toStringAsFixed(2)
          : widget.viewModel.betAmount.toInt().toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    final isTon = vm.currency == PlinkoCurrency.ton;
    final balanceStr = isTon
        ? '${vm.tonBalance.toStringAsFixed(3)} TON'
        : '${vm.starsBalance} ⭐';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF111422), Color(0xFF0A0D17)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Bet Amount & Balance
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'BET AMOUNT',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                'Balance: $balanceStr',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Amount Input Box
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                    ),
                    onChanged: (text) {
                      final val = double.tryParse(text) ?? 0.1;
                      vm.setBetAmount(val);
                    },
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                Text(
                  isTon ? 'TON' : '⭐',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Presets Dock (5 columns)
          Row(
            children: isTon
                ? [
                    _buildPresetBtn('+0.1', () => vm.addBetIncrement(0.1), const Color(0xFF67E8F9)),
                    _buildPresetBtn('+0.2', () => vm.addBetIncrement(0.2), const Color(0xFF67E8F9)),
                    _buildPresetBtn('+0.5', () => vm.addBetIncrement(0.5), const Color(0xFF67E8F9)),
                    _buildPresetBtn('Max', () => vm.setMaxBet(), const Color(0xFF22D3EE)),
                    _buildPresetBtn('Clear', () => vm.clearBet(), const Color(0xFFFDA4AF), isClear: true),
                  ]
                : [
                    _buildPresetBtn('+10', () => vm.addBetIncrement(10), const Color(0xFFFDE68A)),
                    _buildPresetBtn('+20', () => vm.addBetIncrement(20), const Color(0xFFFDE68A)),
                    _buildPresetBtn('+50', () => vm.addBetIncrement(50), const Color(0xFFFDE68A)),
                    _buildPresetBtn('Max', () => vm.setMaxBet(), const Color(0xFFFBBF24)),
                    _buildPresetBtn('Clear', () => vm.clearBet(), const Color(0xFFFDA4AF), isClear: true),
                  ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresetBtn(String label, VoidCallback onTap, Color textColor, {bool isClear = false}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: isClear
                    ? const Color(0xFFE11D48).withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isClear
                      ? const Color(0xFFE11D48).withValues(alpha: 0.3)
                      : Colors.white10,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

