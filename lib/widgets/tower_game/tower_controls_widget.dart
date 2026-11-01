import 'package:flutter/material.dart';
import '../../features/tower_game/view_models/tower_game_view_model.dart';
import '../../models/tower_game/tower_game_models.dart';
import '../../services/haptic.dart';

/// Control panel below Play button (Difficulty, Currency, Chips, Bet adjustment).
class TowerControlsWidget extends StatefulWidget {
  final TowerGameViewModel viewModel;

  const TowerControlsWidget({
    super.key,
    required this.viewModel,
  });

  @override
  State<TowerControlsWidget> createState() => _TowerControlsWidgetState();
}

class _TowerControlsWidgetState extends State<TowerControlsWidget> {
  late TextEditingController _betController;

  @override
  void initState() {
    super.initState();
    _betController = TextEditingController(
      text: widget.viewModel.betAmount.toString(),
    );
  }

  @override
  void didUpdateWidget(covariant TowerControlsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.viewModel.isPlaying) {
      final currentTextVal = double.tryParse(_betController.text);
      if (currentTextVal != widget.viewModel.betAmount) {
        _betController.text = widget.viewModel.currency == TowerCurrency.ton
            ? widget.viewModel.betAmount.toStringAsFixed(2)
            : widget.viewModel.betAmount.toInt().toString();
      }
    }
  }

  @override
  void dispose() {
    _betController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    final isLocked = vm.isPlaying;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1322).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF1E293B),
          width: 1.2,
        ),
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
          // 1. Difficulty Selector: Easy • | Medium •• | Master •••
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Row(
              children: TowerDifficulty.values.map((diff) {
                final isActive = vm.difficulty == diff;

                return Expanded(
                  child: GestureDetector(
                    onTap: isLocked ? null : () => vm.setDifficulty(diff),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF7C3AED) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            diff.label,
                            style: TextStyle(
                              color: isActive ? Colors.white : const Color(0xFF94A3B8),
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            diff.dots,
                            style: TextStyle(
                              color: isActive ? Colors.white70 : const Color(0xFF64748B),
                              fontSize: 9,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 10),

          // 2. Currency Selector: Stars | 💎 TON | 🎁 Gift
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Row(
              children: [
                // Stars
                Expanded(
                  child: _buildCurrencyTab(
                    label: 'Stars',
                    isActive: vm.currency == TowerCurrency.stars,
                    activeColor: const Color(0xFF9333EA).withValues(alpha: 0.35),
                    activeBorderColor: const Color(0xFFA855F7).withValues(alpha: 0.6),
                    onTap: isLocked ? null : () => vm.setCurrency(TowerCurrency.stars),
                  ),
                ),
                const SizedBox(width: 4),

                // TON
                Expanded(
                  child: _buildCurrencyTab(
                    label: '💎 TON',
                    isActive: vm.currency == TowerCurrency.ton,
                    activeColor: const Color(0xFF06B6D4).withValues(alpha: 0.25),
                    activeBorderColor: const Color(0xFF22D3EE).withValues(alpha: 0.6),
                    onTap: isLocked ? null : () => vm.setCurrency(TowerCurrency.ton),
                  ),
                ),
                const SizedBox(width: 4),

                // Gift (Placeholder banner)
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedbackService.tap();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Telegram Gifts wagering in Tower coming soon!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        alignment: Alignment.center,
                        child: const Text(
                          '🎁 Gift',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 3. Quick Chips: 20 | 50 | 200
          Row(
            children: [20.0, 50.0, 200.0].map((chip) {
              final chipDisplay = vm.currency == TowerCurrency.ton
                  ? (chip / 100.0).toStringAsFixed(2)
                  : chip.toInt().toString();

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: OutlinedButton(
                    onPressed: isLocked ? null : () => vm.setQuickChip(chip),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFF151C30),
                      side: const BorderSide(color: Color(0xFF334155)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      chipDisplay,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 10),

          // 4. Bet Adjustment Bar: [-] | [Input] | [+] | MAX
          Row(
            children: [
              // Decrement [-]
              SizedBox(
                width: 42,
                height: 42,
                child: OutlinedButton(
                  onPressed: isLocked ? null : () => vm.decrementBet(),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFF151C30),
                    side: const BorderSide(color: Color(0xFF334155)),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '-',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // Bet Input Display
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      Text(
                        vm.currency == TowerCurrency.ton ? '💎' : '⭐',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          controller: _betController,
                          enabled: !isLocked,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                          onChanged: (text) {
                            final val = double.tryParse(text) ?? 0.0;
                            vm.setBetAmount(val);
                          },
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // Increment [+]
              SizedBox(
                width: 42,
                height: 42,
                child: OutlinedButton(
                  onPressed: isLocked ? null : () => vm.incrementBet(),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFF151C30),
                    side: const BorderSide(color: Color(0xFF334155)),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '+',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // MAX button
              SizedBox(
                height: 42,
                child: OutlinedButton(
                  onPressed: isLocked ? null : () => vm.setMaxBet(),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFF151C30),
                    side: const BorderSide(color: Color(0xFF334155)),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'MAX',
                    style: TextStyle(
                      color: Color(0xFFC084FC),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
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

  Widget _buildCurrencyTab({
    required String label,
    required bool isActive,
    required Color activeColor,
    required Color activeBorderColor,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive ? activeBorderColor : Colors.transparent,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : const Color(0xFF94A3B8),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

