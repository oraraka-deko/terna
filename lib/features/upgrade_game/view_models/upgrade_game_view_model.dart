import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:terna/models/upgrade_game/telegram_gift_model.dart';
import 'package:terna/models/upgrade_game/upgrade_game_models.dart';
import 'package:terna/services/haptic.dart';
import 'package:terna/services/upgrade_game/upgrade_gifts_repository.dart';
import 'package:terna/services/upgrade_game/wheel_audio_service.dart';
import 'package:terna/services/wallet/wallet_repository.dart';
import 'package:terna/services/inventory/inventory_repository.dart';

class UpgradeGameViewModel extends ChangeNotifier {
  final UpgradeGiftsRepository repository;
  final TickerProvider vsync;

  UpgradeGameViewModel({
    required this.repository,
    required this.vsync,
  });

  UpgradeCurrency currency = UpgradeCurrency.ton;
  bool isDemoMode = false;
  bool isSpinning = false;
  bool isLoading = true;

  UpgradeUserInventory inventory = const UpgradeUserInventory(
    tonBalance: 0,
    starsBalance: 0,
    gifts: [],
    isPlaceholder: false,
  );

  List<TelegramGift> catalogGifts = [];
  TelegramGift? selectedTargetGift;
  List<TelegramGift> selectedInventoryGifts = [];
  double additionalTon = 0.0;
  int additionalStars = 0;

  UpgradeSpinResult? lastResult;

  // Wheel Physics State
  double wheelRotation = 0.0; // In degrees
  bool isDragging = false;
  double _lastAngle = 0.0;
  int _lastTimeMs = 0;
  double _velocity = 0.0; // deg/ms
  int _lastTickIndex = 0;

  Ticker? _glideTicker;
  Ticker? _spinTicker;

  Future<void> initialize() async {
    isLoading = true;
    notifyListeners();

    try {
      catalogGifts = await repository.loadCatalog();
      inventory = await repository.loadInitialPlaceholderInventory();

      if (catalogGifts.isNotEmpty) {
        // Default target gift: one with price_stars >= 100 or the first one
        selectedTargetGift = catalogGifts.firstWhere(
          (g) => g.priceStars >= 100,
          orElse: () => catalogGifts.first,
        );
      }
    } catch (_) {}

    isLoading = false;
    notifyListeners();
  }

  // --- Calculations ---

  double get tonRate => repository.tonRateUsd;
  double get starsRate => repository.starsRateUsd;
  double get houseEdge => repository.houseEdge;
  double get minMultiplier => repository.minMultiplier;

  double starsToTon(int stars) => repository.starsToTon(stars);
  int tonToStars(double ton) => repository.tonToStars(ton);

  /// Compute Total Bet Value in Active Currency
  double get totalBetValue {
    double tonSum = additionalTon;
    int starsSum = additionalStars;

    for (final gift in selectedInventoryGifts) {
      starsSum += gift.priceStars;
      tonSum += starsToTon(gift.priceStars);
    }

    if (currency == UpgradeCurrency.ton) {
      final extraTonFromStars = additionalStars > 0 ? starsToTon(additionalStars) : 0.0;
      return double.parse((tonSum + extraTonFromStars).toStringAsFixed(4));
    } else {
      final extraStarsFromTon = additionalTon > 0 ? tonToStars(additionalTon) : 0;
      return (starsSum + extraStarsFromTon).toDouble();
    }
  }

  /// Target Gift Value in Active Currency
  double get targetGiftValue {
    if (selectedTargetGift == null) return 0.0;
    if (currency == UpgradeCurrency.ton) {
      return starsToTon(selectedTargetGift!.priceStars);
    } else {
      return selectedTargetGift!.priceStars.toDouble();
    }
  }

  /// Check Target Multiplier Constraint
  bool get isValidTarget {
    if (totalBetValue <= 0 || targetGiftValue <= 0) return false;
    return targetGiftValue >= (minMultiplier * totalBetValue);
  }

  /// Target Multiplier Ratio (e.g. 2.45x)
  double get targetRatio {
    if (totalBetValue <= 0) return 0.0;
    return double.parse((targetGiftValue / totalBetValue).toStringAsFixed(2));
  }

  /// Compute Win Chance %
  double get winChancePercent {
    if (totalBetValue <= 0 || targetGiftValue <= 0) return 0.0;
    final prob = totalBetValue / (targetGiftValue * (1 + houseEdge));
    final pct = prob * 100;
    return double.parse(pct.clamp(0.1, 66.6).toStringAsFixed(1));
  }

  // --- User Actions ---

  void setCurrency(UpgradeCurrency newCurrency) {
    if (isSpinning) return;
    currency = newCurrency;
    notifyListeners();
  }

  void toggleDemoMode() {
    if (isSpinning) return;
    isDemoMode = !isDemoMode;
    notifyListeners();
  }

  void setSelectedTargetGift(TelegramGift gift) {
    if (isSpinning) return;
    selectedTargetGift = gift;
    notifyListeners();
  }

  void toggleInventoryGift(TelegramGift gift) {
    if (isSpinning) return;
    final key = gift.instanceId;
    final alreadySelected = selectedInventoryGifts.any((g) => g.instanceId == key);

    if (alreadySelected) {
      selectedInventoryGifts.removeWhere((g) => g.instanceId == key);
    } else {
      if (selectedInventoryGifts.length >= 4) {
        WheelAudioService.playLoss();
        HapticFeedbackService.warning();
        return;
      }
      selectedInventoryGifts.add(gift);
    }
    WheelAudioService.playBet();
    HapticFeedbackService.tap();
    notifyListeners();
  }

  void setAdditionalTon(double val) {
    if (isSpinning) return;
    additionalTon = max(0.0, val);
    notifyListeners();
  }

  void setAdditionalStars(int val) {
    if (isSpinning) return;
    additionalStars = max(0, val);
    notifyListeners();
  }

  void clearBet() {
    if (isSpinning) return;
    selectedInventoryGifts.clear();
    additionalTon = 0.0;
    additionalStars = 0;
    notifyListeners();
  }

  // --- Wheel Physics & Touch Handling ---

  void _triggerTickAudio(double rot) {
    final tickIndex = (rot / 6.0).floor();
    if (tickIndex != _lastTickIndex) {
      _lastTickIndex = tickIndex;
      WheelAudioService.playTick();
      HapticFeedbackService.tap();
    }
  }

  void onPointerDown(Offset localPos, Size size) {
    if (isSpinning) return;
    _stopGliding();

    final cx = size.width / 2;
    final cy = size.height / 2;
    final angle = atan2(localPos.dy - cy, localPos.dx - cx) * (180.0 / pi);

    isDragging = true;
    _lastAngle = angle;
    _lastTimeMs = DateTime.now().millisecondsSinceEpoch;
    _velocity = 0.0;
  }

  void onPointerMove(Offset localPos, Size size) {
    if (!isDragging || isSpinning) return;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final angle = atan2(localPos.dy - cy, localPos.dx - cx) * (180.0 / pi);

    double delta = angle - _lastAngle;
    if (delta > 180) delta -= 360;
    if (delta < -180) delta += 360;

    final now = DateTime.now().millisecondsSinceEpoch;
    final dt = max(1, now - _lastTimeMs);
    final instantV = delta / dt;
    _velocity = (_velocity * 0.4) + (instantV * 0.6);

    _lastTimeMs = now;
    _lastAngle = angle;

    wheelRotation += delta;
    _triggerTickAudio(wheelRotation);
    notifyListeners();
  }

  void onPointerUp() {
    if (!isDragging) return;
    isDragging = false;

    if (_velocity.abs() > 0.04) {
      _startInertiaGlide(_velocity);
    }
  }

  void _stopGliding() {
    _glideTicker?.stop();
    _glideTicker?.dispose();
    _glideTicker = null;
  }

  void _startInertiaGlide(double initialV) {
    _stopGliding();
    double v = initialV.clamp(-2.5, 2.5);
    int lastT = DateTime.now().millisecondsSinceEpoch;

    _glideTicker = vsync.createTicker((_) {
      if (isDragging || isSpinning) {
        _stopGliding();
        return;
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final dt = (now - lastT).clamp(1, 32);
      lastT = now;

      wheelRotation += v * dt;
      _triggerTickAudio(wheelRotation);

      v *= pow(0.965, dt / 16.6);

      if (v.abs() > 0.015) {
        notifyListeners();
      } else {
        _stopGliding();
        notifyListeners();
      }
    });

    _glideTicker!.start();
  }

  // --- Wheel Spin Upgrade Execution ---

  void executeUpgrade() {
    if (isSpinning || totalBetValue <= 0 || !isValidTarget) return;

    final currentBal = currency == UpgradeCurrency.ton ? inventory.tonBalance : inventory.starsBalance.toDouble();
    final addedCur = currency == UpgradeCurrency.ton ? additionalTon : additionalStars.toDouble();

    if (!isDemoMode && addedCur > 0 && currentBal < addedCur) {
      WheelAudioService.playLoss();
      HapticFeedbackService.error();
      return;
    }

    _stopGliding();
    isSpinning = true;
    lastResult = null;
    notifyListeners();

    WheelAudioService.playBet();
    HapticFeedbackService.heavyImpact();

    // Roll random outcome (Provably fair simulation)
    final random = Random();
    final rollPercentile = random.nextDouble() * 100.0;
    final won = rollPercentile <= winChancePercent;

    // Compute precise landing angle
    final rollDeg = (rollPercentile / 100.0) * 360.0;
    final winThresholdDeg = (winChancePercent / 100.0) * 360.0;

    double finalRollDeg = rollDeg;
    if (!won && (rollDeg - winThresholdDeg).abs() < 18) {
      finalRollDeg = winThresholdDeg + 1.5 + (random.nextDouble() * 2.5);
    } else if (won && (rollDeg - winThresholdDeg).abs() < 12) {
      finalRollDeg = max(1.0, winThresholdDeg - 1.2 - (random.nextDouble() * 1.8));
    }

    // Exact wheel rotation modulo required to bring finalRollDeg to top pointer (12 o'clock / 0 deg):
    final targetModuloDeg = ((360 - (finalRollDeg % 360)) % 360);

    final decelStartDeg = wheelRotation;
    final currentModulo = ((wheelRotation % 360) + 360) % 360;
    double angleForward = targetModuloDeg - currentModulo;
    if (angleForward < 90) angleForward += 360;

    // 4 full extra revolutions for anticipation
    final extraSpins = 4 * 360.0;
    final targetDeg = wheelRotation + angleForward + extraSpins;
    const decelDurationMs = 4500;
    final startTime = DateTime.now().millisecondsSinceEpoch;

    _spinTicker?.stop();
    _spinTicker?.dispose();

    _spinTicker = vsync.createTicker((_) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final elapsed = now - startTime;
      final progress = (elapsed / decelDurationMs).clamp(0.0, 1.0);

      // Ease out cubic
      final ease = 1.0 - pow(1.0 - progress, 3.8);

      double microSettle = 0.0;
      if (progress > 0.96) {
        final settleT = (progress - 0.96) / 0.04;
        microSettle = sin(settleT * pi) * 0.001;
      }

      wheelRotation = decelStartDeg + (targetDeg - decelStartDeg) * min(1.0, ease + microSettle);
      _triggerTickAudio(wheelRotation);
      notifyListeners();

      if (progress >= 1.0) {
        _spinTicker?.stop();
        _spinTicker?.dispose();
        _spinTicker = null;
        wheelRotation = targetDeg;
        _finalizeUpgrade(won, rollPercentile);
      }
    });

    _spinTicker!.start();
  }

  void _finalizeUpgrade(bool won, double rollPercentile) {
    isSpinning = false;

    final consumed = List<TelegramGift>.from(selectedInventoryGifts);
    final consumedTon = additionalTon;
    final consumedStars = additionalStars;

    lastResult = UpgradeSpinResult(
      won: won,
      rollPercentile: rollPercentile,
      winChancePercent: winChancePercent,
      grantedGift: won ? selectedTargetGift : null,
      consumedGifts: consumed,
      consumedTon: consumedTon,
      consumedStars: consumedStars,
    );

    if (won) {
      WheelAudioService.playWin();
      HapticFeedbackService.success();
    } else {
      WheelAudioService.playLoss();
      HapticFeedbackService.error();
    }

    if (!isDemoMode) {
      // Deduct consumed items & balances
      final consumedKeys = consumed.map((g) => g.instanceId).toSet();
      final remainingGifts = inventory.gifts.where((g) => !consumedKeys.contains(g.instanceId)).toList();

      if (won && selectedTargetGift != null) {
        remainingGifts.insert(
          0,
          selectedTargetGift!.copyWith(
            instanceId: 'won_${DateTime.now().millisecondsSinceEpoch}_${selectedTargetGift!.giftId}',
            isPlaceholder: false,
          ),
        );
      }
      WalletRepository().refreshBalances();
      InventoryRepository().fetchInventory();

      inventory = inventory.copyWith(
        tonBalance: max(0.0, inventory.tonBalance - consumedTon),
        starsBalance: max(0, inventory.starsBalance - consumedStars),
        gifts: remainingGifts,
      );

      selectedInventoryGifts.clear();
      additionalTon = 0.0;
      additionalStars = 0;
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _stopGliding();
    _spinTicker?.stop();
    _spinTicker?.dispose();
    super.dispose();
  }
}
