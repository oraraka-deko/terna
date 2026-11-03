library;

import 'dart:math';
import 'package:flutter/material.dart';

import '../../models/inventory/inventory_models.dart';
import '../../models/wallet/wallet_models.dart';
import '../../services/haptic.dart';
import '../../services/inventory/inventory_repository.dart';
import '../../services/wallet/ton_wallet_service.dart';
import '../../services/wallet/wallet_repository.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _walletRepo = WalletRepository();
  final _tonWallet = TonWalletService();
  final _inventoryRepo = InventoryRepository();

  // Deposit State
  String _depositMethod = 'TON'; // 'TON', 'STARS', 'GIFTS'
  double _depositTonAmount = 1.0;
  int _depositStarsAmount = 100;
  bool _isDepositing = false;
  String _depositStatusMsg = '';

  // Withdraw State
  final TextEditingController _withdrawAddressController = TextEditingController();
  final TextEditingController _withdrawAmountController = TextEditingController(text: '1.0');
  bool _isWithdrawing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: 0);
    _walletRepo.refreshBalances();
    _tonWallet.addListener(_onWalletChanged);
  }

  void _onWalletChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tonWallet.removeListener(_onWalletChanged);
    _tabController.dispose();
    _withdrawAddressController.dispose();
    _withdrawAmountController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // TON DEPOSIT ACTION
  // --------------------------------------------------------------------------
  Future<void> _handleTonDeposit() async {
    setState(() {
      _isDepositing = true;
      _depositStatusMsg = 'Initiating TON Connect deposit...';
    });

    try {
      final res = await _walletRepo.executeTonDeposit(
        context,
        _depositTonAmount,
        onStepUpdate: (msg) {
          if (mounted) setState(() => _depositStatusMsg = msg);
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.message),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deposit error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDepositing = false;
          _depositStatusMsg = '';
        });
      }
    }
  }

  // --------------------------------------------------------------------------
  // STARS DEPOSIT ACTION
  // --------------------------------------------------------------------------
  Future<void> _handleStarsDeposit() async {
    setState(() {
      _isDepositing = true;
      _depositStatusMsg = 'Opening Telegram Stars invoice...';
    });

    try {
      final success = await _walletRepo.executeStarsDeposit(
        context,
        _depositStarsAmount,
        onStepUpdate: (msg) {
          if (mounted) setState(() => _depositStatusMsg = msg);
        },
      );

      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Credited $_depositStarsAmount Telegram Stars!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDepositing = false;
          _depositStatusMsg = '';
        });
      }
    }
  }

  // --------------------------------------------------------------------------
  // WITHDRAW TON ACTION
  // --------------------------------------------------------------------------
  Future<void> _handleWithdrawTon() async {
    final addr = _withdrawAddressController.text.trim();
    final amount = double.tryParse(_withdrawAmountController.text.trim()) ?? 0.0;

    if (addr.isEmpty || addr.length < 24) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid TON address!'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    if (amount <= 0 || amount > _walletRepo.tonBalance.value) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid withdrawal amount!'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isWithdrawing = true);
    await Future.delayed(const Duration(milliseconds: 1000));

    final ok = await _walletRepo.withdrawTon(addr, amount);
    if (mounted) {
      setState(() => _isWithdrawing = false);
      if (ok) {
        HapticFeedbackService.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Withdrawal request for $amount TON submitted!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        _withdrawAmountController.text = '1.0';
      }
    }
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
          'TERNA WALLET',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: () => _walletRepo.refreshBalances(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF2DD4BF),
          indicatorWeight: 3,
          labelColor: const Color(0xFF2DD4BF),
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Deposit'),
            Tab(text: 'Withdraw'),
            Tab(text: 'Ledger'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildDepositTab(),
          _buildWithdrawTab(),
          _buildLedgerTab(),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TAB 1: OVERVIEW
  // --------------------------------------------------------------------------
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Total Portfolio Value Banner
          ValueListenableBuilder<double>(
            valueListenable: _walletRepo.tonBalance,
            builder: (ctx, ton, _) {
              return ValueListenableBuilder<int>(
                valueListenable: _walletRepo.starsBalance,
                builder: (ctx, stars, _) {
                  final totalUsd = double.parse(((ton * 1.515) + (stars * 0.0130)).toStringAsFixed(2));
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F2B26), Color(0xFF0D1420)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF2DD4BF).withValues(alpha: 0.3)),
                      boxShadow: const [
                        BoxShadow(color: Color(0x332DD4BF), blurRadius: 16, offset: Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Estimated Total Assets',
                          style: TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '\$$totalUsd USD',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _tabController.animateTo(1),
                                icon: const Icon(Icons.arrow_downward_rounded, size: 16),
                                label: const Text('Deposit'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2DD4BF),
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _tabController.animateTo(2),
                                icon: const Icon(Icons.arrow_upward_rounded, size: 16),
                                label: const Text('Withdraw'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white24),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),

          const SizedBox(height: 16),

          // TON Asset Card
          ValueListenableBuilder<double>(
            valueListenable: _walletRepo.tonBalance,
            builder: (ctx, ton, _) {
              final tonUsd = double.parse((ton * 1.515).toStringAsFixed(2));
              final isConnected = _tonWallet.isConnected;
              final addr = _tonWallet.connectedAddress;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF131826),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0098EA).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.diamond_outlined, color: Color(0xFF0098EA), size: 24),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('TON Coin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                Text('The Open Network', style: TextStyle(color: Colors.white38, fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('$ton TON', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('\$$tonUsd', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: Colors.white10, height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isConnected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                              color: isConnected ? const Color(0xFF10B981) : Colors.white38,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isConnected && addr != null
                                  ? '${addr.substring(0, 6)}...${addr.substring(max(0, addr.length - 4))}'
                                  : 'Wallet not connected',
                              style: const TextStyle(color: Colors.white60, fontSize: 12),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            if (isConnected) {
                              _tonWallet.disconnectWallet();
                            } else {
                              _tonWallet.connectWallet(context);
                            }
                          },
                          child: Text(
                            isConnected ? 'Disconnect' : 'Connect TON',
                            style: TextStyle(
                              color: isConnected ? Colors.redAccent : const Color(0xFF0098EA),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          // Telegram Stars Card
          ValueListenableBuilder<int>(
            valueListenable: _walletRepo.starsBalance,
            builder: (ctx, stars, _) {
              final starsUsd = double.parse((stars * 0.0130).toStringAsFixed(2));
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF131826),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB800).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Telegram Stars', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                            Text('Official In-App Currency', style: TextStyle(color: Colors.white38, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('$stars Stars', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('\$$starsUsd', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TAB 2: DEPOSIT
  // --------------------------------------------------------------------------
  Widget _buildDepositTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Method segmented selector
          Row(
            children: [
              _buildMethodTab('TON', Icons.diamond_outlined, 'TON Connect'),
              const SizedBox(width: 8),
              _buildMethodTab('STARS', Icons.star_rounded, 'Telegram Stars'),
              const SizedBox(width: 8),
              _buildMethodTab('GIFTS', Icons.card_giftcard_rounded, 'Sell Gifts'),
            ],
          ),

          const SizedBox(height: 20),

          if (_depositMethod == 'TON') _buildTonDepositSection(),
          if (_depositMethod == 'STARS') _buildStarsDepositSection(),
          if (_depositMethod == 'GIFTS') _buildGiftsDepositSection(),
        ],
      ),
    );
  }

  Widget _buildMethodTab(String method, IconData icon, String label) {
    final isSelected = _depositMethod == method;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _depositMethod = method),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2DD4BF).withValues(alpha: 0.15) : const Color(0xFF131826),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF2DD4BF) : Colors.white12,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? const Color(0xFF2DD4BF) : Colors.white60, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white60,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTonDepositSection() {
    final amounts = [0.5, 1.0, 2.5, 5.0, 10.0];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131826),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Deposit Amount', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: amounts.map((amt) {
              final isSelected = _depositTonAmount == amt;
              return ChoiceChip(
                label: Text('$amt TON'),
                selected: isSelected,
                selectedColor: const Color(0xFF2DD4BF),
                backgroundColor: const Color(0xFF0C101A),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.black : Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
                onSelected: (_) => setState(() => _depositTonAmount = amt),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          if (_depositStatusMsg.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _depositStatusMsg,
                style: const TextStyle(color: Color(0xFF2DD4BF), fontSize: 12),
              ),
            ),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isDepositing ? null : _handleTonDeposit,
              icon: _isDepositing
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Icon(Icons.diamond_outlined),
              label: Text(
                _isDepositing ? 'Processing...' : 'Deposit $_depositTonAmount TON',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2DD4BF),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarsDepositSection() {
    final packages = [50, 100, 250, 500, 1000, 2500];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131826),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Stars Package', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: packages.map((pkg) {
              final isSelected = _depositStarsAmount == pkg;
              return ChoiceChip(
                label: Text('$pkg Stars'),
                selected: isSelected,
                selectedColor: const Color(0xFFFFB800),
                backgroundColor: const Color(0xFF0C101A),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.black : Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
                onSelected: (_) => setState(() => _depositStarsAmount = pkg),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          if (_depositStatusMsg.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _depositStatusMsg,
                style: const TextStyle(color: Color(0xFFFFB800), fontSize: 12),
              ),
            ),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isDepositing ? null : _handleStarsDeposit,
              icon: _isDepositing
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Icon(Icons.star_rounded),
              label: Text(
                _isDepositing ? 'Processing...' : 'Pay for $_depositStarsAmount Stars',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB800),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGiftsDepositSection() {
    return ValueListenableBuilder<List<InventoryItem>>(
      valueListenable: _inventoryRepo.userItems,
      builder: (ctx, items, _) {
        final gifts = items.where((i) => !i.isDigital).toList();

        if (gifts.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF131826),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'No Telegram gifts in inventory to sell.\nWin gifts in Lucky Roulette or buy in Shop!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ),
          );
        }

        return Column(
          children: gifts.map((g) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF131826),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  Image.asset(
                    g.webpPath,
                    width: 44,
                    height: 44,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(Icons.card_giftcard, color: Colors.amber),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(g.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('${g.floorTon} TON / ${g.priceStars} Stars', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _inventoryRepo.sellGift(instanceId: g.instanceId, currency: 'TON');
                      HapticFeedbackService.mediumImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Sold ${g.name} for ${g.floorTon} TON!'), backgroundColor: const Color(0xFF10B981)),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2DD4BF),
                      foregroundColor: Colors.black,
                      minimumSize: const Size(60, 32),
                    ),
                    child: const Text('Sell TON', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // TAB 3: WITHDRAW
  // --------------------------------------------------------------------------
  Widget _buildWithdrawTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
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
                Icon(Icons.arrow_upward_rounded, color: Color(0xFF2DD4BF)),
                SizedBox(width: 8),
                Text('Withdraw TON Coin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Withdrawals are processed instantly via TON blockchain.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 16),

            const Text('Destination TON Address', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _withdrawAddressController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'EQ... or UQ... TON address',
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: const Color(0xFF0C101A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),

            const SizedBox(height: 14),

            const Text('Amount (TON)', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _withdrawAmountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF0C101A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                suffixText: 'TON',
                suffixStyle: const TextStyle(color: Color(0xFF2DD4BF), fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isWithdrawing ? null : _handleWithdrawTon,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2DD4BF),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isWithdrawing
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text('Confirm Withdrawal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TAB 4: LEDGER
  // --------------------------------------------------------------------------
  Widget _buildLedgerTab() {
    return ValueListenableBuilder<List<WalletTransaction>>(
      valueListenable: _walletRepo.transactions,
      builder: (ctx, txs, _) {
        if (txs.isEmpty) {
          return const Center(
            child: Text('No transaction history yet.', style: TextStyle(color: Colors.white54)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: txs.length,
          itemBuilder: (ctx, idx) {
            final tx = txs[idx];
            final isPositive = tx.amount > 0;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF131826),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isPositive
                          ? const Color(0xFF10B981).withValues(alpha: 0.15)
                          : const Color(0xFFEF4444).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPositive ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                      color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tx.description,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${tx.timestamp.hour.toString().padLeft(2, '0')}:${tx.timestamp.minute.toString().padLeft(2, '0')} • ${tx.type}',
                          style: const TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isPositive ? '+' : ''}${tx.amount} ${tx.currency}',
                        style: TextStyle(
                          color: isPositive ? const Color(0xFF10B981) : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tx.status,
                          style: const TextStyle(color: Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
