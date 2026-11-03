library;

import 'package:flutter/material.dart';
import '../../services/wallet/ton_wallet_service.dart';

enum DepositTab { stars, ton }

class WalletDepositDialog extends StatefulWidget {
  final VoidCallback? onBalanceUpdated;

  const WalletDepositDialog({super.key, this.onBalanceUpdated});

  static Future<void> show(BuildContext context, {VoidCallback? onBalanceUpdated}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WalletDepositDialog(onBalanceUpdated: onBalanceUpdated),
    );
  }

  @override
  State<WalletDepositDialog> createState() => _WalletDepositDialogState();
}

class _WalletDepositDialogState extends State<WalletDepositDialog> {
  final _walletService = TonWalletService();

  DepositTab _selectedTab = DepositTab.stars;

  // Stars state
  int _selectedStars = 100;
  final _starsPresets = [50, 100, 250, 500, 1000];
  final _starsInputController = TextEditingController(text: '100');

  // TON state
  double _selectedTon = 1.0;
  final _tonPresets = [0.5, 1.0, 2.5, 5.0, 10.0];
  final _tonInputController = TextEditingController(text: '1.0');

  // Processing state
  bool _isLoading = false;
  String? _statusMessage;
  String? _errorMessage;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _walletService.init();
    _walletService.addListener(_onWalletChanged);
  }

  @override
  void dispose() {
    _walletService.removeListener(_onWalletChanged);
    _starsInputController.dispose();
    _tonInputController.dispose();
    super.dispose();
  }

  void _onWalletChanged() {
    if (mounted) setState(() {});
  }

  String _formatAddress(String? addr) {
    if (addr == null || addr.isEmpty) return '';
    if (addr.length <= 12) return addr;
    return '${addr.substring(0, 6)}...${addr.substring(addr.length - 4)}';
  }

  Future<void> _handleDepositStars() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _statusMessage = 'Initiating Stars invoice...';
      _isSuccess = false;
    });

    try {
      await _walletService.depositStars(
        starsAmount: _selectedStars,
        onStepUpdate: (msg) {
          if (mounted) setState(() => _statusMessage = msg);
        },
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSuccess = true;
          _statusMessage = '✓ Deposited $_selectedStars Stars successfully!';
        });
        widget.onBalanceUpdated?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _statusMessage = null;
        });
      }
    }
  }

  Future<void> _handleDepositTon() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _statusMessage = 'Starting TON deposit...';
      _isSuccess = false;
    });

    try {
      final res = await _walletService.depositTon(
        context: context,
        amountTon: _selectedTon,
        onStepUpdate: (msg) {
          if (mounted) setState(() => _statusMessage = msg);
        },
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSuccess = true;
          _statusMessage = res.message;
        });
        widget.onBalanceUpdated?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _statusMessage = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFF161B26),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title & Close Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Top Up Wallet',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Tab Selector: Stars vs TON
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF0F141C),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(
                    tab: DepositTab.stars,
                    label: '⭐ Stars',
                    isSelected: _selectedTab == DepositTab.stars,
                  ),
                ),
                Expanded(
                  child: _buildTabButton(
                    tab: DepositTab.ton,
                    label: '💎 TON Coin',
                    isSelected: _selectedTab == DepositTab.ton,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Tab Content
          if (_selectedTab == DepositTab.stars) ...[
            _buildStarsContent(),
          ] else ...[
            _buildTonContent(),
          ],

          const SizedBox(height: 16),

          // Live Status / Error / Success Message
          if (_statusMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _isSuccess ? const Color(0xFF064E3B) : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isSuccess ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  if (_isLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  else if (_isSuccess)
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _statusMessage!,
                      style: TextStyle(
                        fontSize: 13,
                        color: _isSuccess ? const Color(0xFF34D399) : Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF451A1A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFEF4444), width: 1),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 13, color: Color(0xFFFCA5A5)),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Main Action Button
          ElevatedButton(
            onPressed: _isLoading ? null : (_selectedTab == DepositTab.stars ? _handleDepositStars : _handleDepositTon),
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedTab == DepositTab.stars ? const Color(0xFFF59E0B) : const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: Text(
              _isLoading
                  ? 'Processing...'
                  : _selectedTab == DepositTab.stars
                      ? 'Pay $_selectedStars ⭐ with Telegram'
                      : 'Deposit $_selectedTon TON',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({required DepositTab tab, required String label, required bool isSelected}) {
    return GestureDetector(
      onTap: () => setState(() {
        _selectedTab = tab;
        _errorMessage = null;
        _statusMessage = null;
        _isSuccess = false;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF263042) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.white54,
          ),
        ),
      ),
    );
  }

  Widget _buildStarsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Select Stars Package:',
          style: TextStyle(fontSize: 13, color: Colors.white70),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _starsPresets.map((stars) {
            final isSelected = _selectedStars == stars;
            return ChoiceChip(
              label: Text('$stars ⭐'),
              selected: isSelected,
              onSelected: (val) {
                if (val) {
                  setState(() {
                    _selectedStars = stars;
                    _starsInputController.text = stars.toString();
                  });
                }
              },
              selectedColor: const Color(0xFFD97706),
              backgroundColor: const Color(0xFF1E2638),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTonContent() {
    final isConnected = _walletService.isConnected;
    final address = _walletService.connectedAddress;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Wallet connection chip / card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F141C),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isConnected ? const Color(0xFF10B981) : const Color(0xFF2E384D),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isConnected ? const Color(0xFF10B981) : Colors.white30,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isConnected ? _formatAddress(address) : 'No Wallet Connected',
                    style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  if (isConnected) {
                    _walletService.disconnectWallet();
                  } else {
                    _walletService.connectWallet(context);
                  }
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  isConnected ? 'Disconnect' : 'Connect',
                  style: TextStyle(
                    fontSize: 13,
                    color: isConnected ? const Color(0xFFEF4444) : const Color(0xFF38BDF8),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        const Text(
          'Select Amount (TON):',
          style: TextStyle(fontSize: 13, color: Colors.white70),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _tonPresets.map((ton) {
            final isSelected = _selectedTon == ton;
            return ChoiceChip(
              label: Text('$ton TON'),
              selected: isSelected,
              onSelected: (val) {
                if (val) {
                  setState(() {
                    _selectedTon = ton;
                    _tonInputController.text = ton.toString();
                  });
                }
              },
              selectedColor: const Color(0xFF0284C7),
              backgroundColor: const Color(0xFF1E2638),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            );
          }).toList(),
        ),
      ],
    );
  }
}
