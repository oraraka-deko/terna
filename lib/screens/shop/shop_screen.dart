library;

import '../gift_shop/gift_shop_screen.dart';

import 'package:flutter/material.dart';

import '../../services/haptic.dart';
import '../../services/shop/shop_repository.dart';
import '../../services/wallet/wallet_repository.dart';
import '../../widgets/shop/gemini_store_section.dart';
import '../wallet/wallet_screen.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _wallet = WalletRepository();
  final _shopRepo = ShopRepository();

  // Stars Purchase Form State
  int _selectedStarsAmount = 250;
  final TextEditingController _starsRecipientController = TextEditingController(text: '@terna_player');
  final bool _recipientVerified = true;

  // Premium Purchase Form State
  int _selectedPremiumMonths = 3;
  final TextEditingController _premiumRecipientController = TextEditingController(text: '@terna_player');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _starsRecipientController.dispose();
    _premiumRecipientController.dispose();
    super.dispose();
  }

  void _openWallet() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const WalletScreen()),
    );
  }



  Future<void> _buyStars() async {
    final tonPerStar = 0.0086;
    final totalTon = double.parse((_selectedStarsAmount * tonPerStar).toStringAsFixed(2));

    if (_wallet.tonBalance.value < totalTon) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Insufficient TON balance! Need $totalTon TON'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    _wallet.debitTon(totalTon, 'Purchased $_selectedStarsAmount Telegram Stars for ${_starsRecipientController.text}');
    _wallet.creditStars(_selectedStarsAmount, 'Telegram Stars Purchased via Shop');

    HapticFeedbackService.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Successfully sent $_selectedStarsAmount Stars to ${_starsRecipientController.text}!'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  Future<void> _giftPremium() async {
    final prices = _shopRepo.getPrices();
    final opt = prices.premiumOptions.firstWhere((p) => p.months == _selectedPremiumMonths);

    if (_wallet.tonBalance.value < opt.priceTon) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Insufficient TON balance! Need ${opt.priceTon} TON'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    _wallet.debitTon(opt.priceTon, 'Gifted Telegram Premium (${opt.months}mo) to ${_premiumRecipientController.text}');

    HapticFeedbackService.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Successfully gifted ${opt.months} Months Telegram Premium to ${_premiumRecipientController.text}!'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1420),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'TERNA STORE',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
        ),
        actions: [
          // Live Balance Display & Wallet Shortcut
          InkWell(
            onTap: _openWallet,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF161F30),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF2DD4BF).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  ValueListenableBuilder<double>(
                    valueListenable: _wallet.tonBalance,
                    builder: (ctx, ton, _) => Row(
                      children: [
                        const Icon(Icons.diamond_outlined, color: Color(0xFF0098EA), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '$ton',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ValueListenableBuilder<int>(
                    valueListenable: _wallet.starsBalance,
                    builder: (ctx, stars, _) => Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 16),
                        const SizedBox(width: 2),
                        Text(
                          '$stars',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF2DD4BF), size: 16),
                ],
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: const Color(0xFF2DD4BF),
          indicatorWeight: 3,
          labelColor: const Color(0xFF2DD4BF),
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'AI & Software'),
            Tab(text: 'Telegram Gifts'),
            Tab(text: 'Telegram Stars'),
            Tab(text: 'Telegram Premium'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. AI & Software (GeminiStore)
          const SingleChildScrollView(
            child: GeminiStoreSection(),
          ),

          // 2. Telegram Gifts (Full Animated Lottie/TGS Gift Shop)
          const GiftShopScreen(isEmbedded: true),

          // 3. Telegram Stars
          _buildStarsTab(),

          // 4. Telegram Premium
          _buildPremiumTab(),
        ],
      ),
    );
  }


  Widget _buildStarsTab() {
    final tonPerStar = 0.0086;
    final totalTon = double.parse((_selectedStarsAmount * tonPerStar).toStringAsFixed(2));
    final packages = [100, 250, 500, 1000, 2500, 5000];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF131826),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Buy Telegram Stars with TON',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Instantly transfer stars to your personal Telegram account or any @username.',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 16),

                // Recipient Field
                const Text('Recipient Username', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: _starsRecipientController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.alternate_email_rounded, color: Color(0xFF2DD4BF), size: 20),
                    suffixIcon: _recipientVerified
                        ? const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20)
                        : null,
                    filled: true,
                    fillColor: const Color(0xFF0C101A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),

                const SizedBox(height: 18),
                const Text('Select Stars Amount', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                // Package choices
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: packages.map((amt) {
                    final isSelected = _selectedStarsAmount == amt;
                    final cost = double.parse((amt * tonPerStar).toStringAsFixed(2));
                    return InkWell(
                      onTap: () => setState(() => _selectedStarsAmount = amt),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: (MediaQuery.of(context).size.width - 64) / 3,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF2DD4BF).withValues(alpha: 0.15) : const Color(0xFF0C101A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF2DD4BF) : Colors.white12,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 16),
                                const SizedBox(width: 4),
                                Text('$amt', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('$cost TON', style: const TextStyle(color: Color(0xFF2DD4BF), fontSize: 11)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),
                const Divider(color: Colors.white12),
                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Cost:', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    Text('$totalTon TON', style: const TextStyle(color: Color(0xFF2DD4BF), fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _buyStars,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2DD4BF),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Purchase $_selectedStarsAmount Stars', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumTab() {
    final prices = _shopRepo.getPrices();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF131826),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.workspace_premium_rounded, color: Color(0xFFC084FC), size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Gift Telegram Premium',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'No phone number or login needed! Paid directly in TON via smart edge routing.',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 16),

                // Recipient
                const Text('Recipient Username', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: _premiumRecipientController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.alternate_email_rounded, color: Color(0xFFC084FC), size: 20),
                    filled: true,
                    fillColor: const Color(0xFF0C101A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),

                const SizedBox(height: 18),
                const Text('Select Duration', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                ...prices.premiumOptions.map((opt) {
                  final isSelected = _selectedPremiumMonths == opt.months;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFC084FC).withValues(alpha: 0.12) : const Color(0xFF0C101A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? const Color(0xFFC084FC) : Colors.white12,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: ListTile(
                      dense: true,
                      onTap: () => setState(() => _selectedPremiumMonths = opt.months),
                      title: Row(
                        children: [
                          Text('${opt.months} Months Premium', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFC084FC),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('-${opt.discountPercent}%', style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      subtitle: Text('${opt.priceTon} TON', style: const TextStyle(color: Color(0xFFC084FC), fontWeight: FontWeight.bold)),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded, color: Color(0xFFC084FC))
                          : const Icon(Icons.circle_outlined, color: Colors.white24),
                    ),
                  );
                }),

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _giftPremium,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC084FC),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Gift $_selectedPremiumMonths Months Premium', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
