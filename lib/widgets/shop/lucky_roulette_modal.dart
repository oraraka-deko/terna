library;

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import '../../models/inventory/inventory_models.dart';
import '../../models/shop/shop_models.dart';
import '../../models/upgrade_game/telegram_gift_model.dart';
import '../../services/haptic.dart';
import '../../services/inventory/inventory_repository.dart';
import '../../services/shop/shop_repository.dart';
import '../../services/wallet/wallet_repository.dart';

class LuckyRouletteModal extends StatefulWidget {
  final TelegramGift gift;
  final VoidCallback? onCompleted;

  const LuckyRouletteModal({
    super.key,
    required this.gift,
    this.onCompleted,
  });

  static Future<void> show(BuildContext context, TelegramGift gift) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LuckyRouletteModal(gift: gift),
    );
  }

  @override
  State<LuckyRouletteModal> createState() => _LuckyRouletteModalState();
}

class _LuckyRouletteModalState extends State<LuckyRouletteModal> with SingleTickerProviderStateMixin {
  final _wallet = WalletRepository();
  final _inventory = InventoryRepository();
  final _shopRepo = ShopRepository();

  String _currency = 'TON'; // 'TON' or 'STARS'
  double _winChance = 38.0; // 1% to 95%
  bool _isSpinning = false;
  bool _skipAnimation = false;

  final ScrollController _scrollController = ScrollController();
  static const double _tileWidth = 84.0;
  static const double _tileHeight = 94.0;

  List<LuckyRouletteTile> _previewStrip = [];

  @override
  void initState() {
    super.initState();
    _generatePreviewStrip();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _generatePreviewStrip() {
    final floorTon = double.parse((widget.gift.priceStars * 0.0086).toStringAsFixed(2));
    final out = _shopRepo.generateLuckyRouletteOutcome(
      giftId: widget.gift.giftId,
      giftName: widget.gift.name,
      priceStars: widget.gift.priceStars,
      floorTon: floorTon,
      winChance: _winChance,
    );
    setState(() {
      _previewStrip = out.reelStrip;
    });
  }

  double get _basePriceTon => double.parse((widget.gift.priceStars * 0.0086).toStringAsFixed(2));
  int get _basePriceStars => widget.gift.priceStars;

  double get _spinPriceTon => max(0.01, double.parse(((_winChance / 100.0) * _basePriceTon).toStringAsFixed(2)));
  int get _spinPriceStars => max(1, ((_winChance / 100.0) * _basePriceStars).round());

  bool get _hasSufficientBalance {
    if (_currency == 'TON') {
      return _wallet.tonBalance.value >= _spinPriceTon;
    } else {
      return _wallet.starsBalance.value >= _spinPriceStars;
    }
  }

  Future<void> _startSpin() async {
    if (_isSpinning) return;

    if (!_hasSufficientBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient $_currency balance! Please deposit to spin.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Deduct cost from wallet
    if (_currency == 'TON') {
      _wallet.debitTon(_spinPriceTon, 'Lucky Roulette Spin: ${widget.gift.name}');
    } else {
      _wallet.debitStars(_spinPriceStars, 'Lucky Roulette Spin: ${widget.gift.name}');
    }

    HapticFeedbackService.mediumImpact();

    // Generate definitive outcome
    final outcome = _shopRepo.generateLuckyRouletteOutcome(
      giftId: widget.gift.giftId,
      giftName: widget.gift.name,
      priceStars: widget.gift.priceStars,
      floorTon: _basePriceTon,
      winChance: _winChance,
    );

    setState(() {
      _isSpinning = true;
      _previewStrip = outcome.reelStrip;
    });

    if (_skipAnimation) {
      _onSpinFinished(outcome);
      return;
    }

    // Reset scroll to 0
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0.0);
    }

    // Viewport center offset
    final screenWidth = MediaQuery.of(context).size.width;
    final centerOffset = (screenWidth / 2) - (_tileWidth / 2);
    final targetScroll = (outcome.winIndex * _tileWidth) - centerOffset + (_tileWidth / 2);

    // Smooth suspense scroll over 4.5 seconds
    try {
      await _scrollController.animateTo(
        targetScroll,
        duration: const Duration(milliseconds: 4500),
        curve: Curves.easeOutCubic,
      );
    } catch (_) {}

    _onSpinFinished(outcome);
  }

  void _onSpinFinished(LuckyRouletteOutcome outcome) {
    if (!mounted) return;
    setState(() {
      _isSpinning = false;
    });

    if (outcome.won) {
      HapticFeedbackService.heavyImpact();
      // Add won gift to user's inventory
      _inventory.addItem(
        InventoryItem(
          instanceId: 'gift_${DateTime.now().millisecondsSinceEpoch}',
          giftId: widget.gift.giftId,
          name: widget.gift.name,
          priceStars: widget.gift.priceStars,
          floorTon: _basePriceTon,
          isCollectible: true,
          editionNumber: '#${Random().nextInt(899999) + 100000}',
          rarity: 2,
          acquiredAt: DateTime.now(),
        ),
      );

      _showResultDialog(won: true, message: 'WINNER! You won ${widget.gift.name}!');
    } else {
      HapticFeedbackService.lightImpact();
      _showResultDialog(won: false, message: 'No luck this spin. Try adjusting your win chance!');
    }
  }

  void _showResultDialog({required bool won, required String message}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131722),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: won ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            width: 1.5,
          ),
        ),
        title: Row(
          children: [
            Icon(
              won ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded,
              color: won ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              size: 28,
            ),
            const SizedBox(width: 10),
            Text(
              won ? 'CONGRATULATIONS!' : 'EMPTY BOX',
              style: TextStyle(
                color: won ? const Color(0xFF10B981) : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (won)
              Container(
                width: 90,
                height: 90,
                margin: const EdgeInsets.symmetric(vertical: 12),
                child: Image.asset(
                  widget.gift.webpPath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(Icons.card_giftcard, size: 60, color: Colors.amber),
                ),
              ),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            if (won) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Item delivered to your Inventory',
                  style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
            },
            child: const Text('Close', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _startSpin();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: won ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Spin Again', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return Container(
      constraints: BoxConstraints(maxHeight: media.size.height * 0.88),
      decoration: const BoxDecoration(
        color: Color(0xFF0D111A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: Color(0xFF2DD4BF), width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x332DD4BF),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle & Header
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2DD4BF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.casino_rounded, color: Color(0xFF2DD4BF), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lucky Roulette: ${widget.gift.name}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Value: $_basePriceStars Stars (~$_basePriceTon TON)',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Spinning Reel Strip Viewer
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: _tileHeight + 16,
                        decoration: BoxDecoration(
                          color: const Color(0xFF080B11),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: ListView.builder(
                          controller: _scrollController,
                          scrollDirection: Axis.horizontal,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _previewStrip.length,
                          itemBuilder: (ctx, idx) {
                            final tile = _previewStrip[idx];
                            return _buildReelTile(tile);
                          },
                        ),
                      ),
                      // Target Pointer Needle
                      IgnorePointer(
                        child: Container(
                          width: _tileWidth + 4,
                          height: _tileHeight + 20,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF2DD4BF), width: 2),
                            borderRadius: BorderRadius.circular(10),
                            color: const Color(0xFF2DD4BF).withValues(alpha: 0.08),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2DD4BF).withValues(alpha: 0.4),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Align(
                            alignment: Alignment.topCenter,
                            child: Icon(Icons.arrow_drop_down, color: Color(0xFF2DD4BF), size: 24),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Currency Selection Chips (TON vs Stars)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildCurrencyChip('TON', Icons.diamond_outlined, const Color(0xFF0098EA)),
                      const SizedBox(width: 12),
                      _buildCurrencyChip('STARS', Icons.star_rounded, const Color(0xFFFFB800)),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Win Chance Slider (1% to 95%)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131926),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Win Probability',
                              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2DD4BF).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${_winChance.toInt()}%',
                                style: const TextStyle(
                                  color: Color(0xFF2DD4BF),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: const Color(0xFF2DD4BF),
                            inactiveTrackColor: Colors.white12,
                            thumbColor: const Color(0xFF2DD4BF),
                            overlayColor: const Color(0x332DD4BF),
                            trackHeight: 4,
                          ),
                          child: Slider(
                            value: _winChance,
                            min: 1.0,
                            max: 95.0,
                            divisions: 94,
                            onChanged: _isSpinning
                                ? null
                                : (val) {
                                    setState(() {
                                      _winChance = val;
                                    });
                                    _generatePreviewStrip();
                                  },
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('1% (Cheapest)', style: TextStyle(color: Colors.white38, fontSize: 11)),
                            Text(
                              'Cost: ${_currency == 'TON' ? '$_spinPriceTon TON' : '$_spinPriceStars Stars'}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const Text('95% (Safest)', style: TextStyle(color: Colors.white38, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Skip Animation Checkbox & User Balance indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _skipAnimation,
                            activeColor: const Color(0xFF2DD4BF),
                            checkColor: Colors.black,
                            onChanged: _isSpinning
                                ? null
                                : (v) {
                                    setState(() => _skipAnimation = v ?? false);
                                  },
                          ),
                          const Text('Fast Instant Spin', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                      ValueListenableBuilder<double>(
                        valueListenable: _wallet.tonBalance,
                        builder: (ctx, ton, _) {
                          return ValueListenableBuilder<int>(
                            valueListenable: _wallet.starsBalance,
                            builder: (ctx, stars, _) {
                              return Text(
                                _currency == 'TON' ? 'Balance: $ton TON' : 'Balance: $stars Stars',
                                style: TextStyle(
                                  color: _hasSufficientBalance ? Colors.white60 : Colors.redAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Spin Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSpinning ? null : _startSpin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2DD4BF),
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: Colors.white24,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 6,
                      ),
                      child: _isSpinning
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Spinning...',
                                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            )
                          : Text(
                              'SPIN FOR ${_currency == 'TON' ? '$_spinPriceTon TON' : '$_spinPriceStars STARS'}',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                letterSpacing: 0.5,
                              ),
                            ),
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

  Widget _buildCurrencyChip(String curr, IconData icon, Color color) {
    final isSelected = _currency == curr;
    return InkWell(
      onTap: _isSpinning
          ? null
          : () {
              setState(() {
                _currency = curr;
              });
            },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : const Color(0xFF131926),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : Colors.white12,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(
              curr,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReelTile(LuckyRouletteTile tile) {
    return Container(
      width: _tileWidth,
      height: _tileHeight,
      margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
      decoration: BoxDecoration(
        color: tile.isFailure ? const Color(0xFF161A22) : const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: tile.isFailure ? Colors.white10 : const Color(0xFF2DD4BF).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (tile.isFailure)
            const Icon(Icons.close_rounded, color: Colors.white24, size: 30)
          else
            Image.asset(
              tile.assetPath,
              width: 44,
              height: 44,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(Icons.card_giftcard, color: Color(0xFF2DD4BF), size: 36),
            ),
          const SizedBox(height: 4),
          Text(
            tile.isFailure ? 'EMPTY' : tile.name,
            style: TextStyle(
              color: tile.isFailure ? Colors.white30 : Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
