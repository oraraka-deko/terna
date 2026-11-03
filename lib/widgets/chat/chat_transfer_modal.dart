library;

import 'dart:math';
import 'package:flutter/material.dart';

import '../../models/chat/chat_models.dart';
import '../../models/inventory/inventory_models.dart';
import '../../services/bio.dart';
import '../../services/haptic.dart';
import '../../services/inventory/inventory_repository.dart';
import '../../services/wallet/wallet_repository.dart';

class ChatTransferModal extends StatefulWidget {
  final String recipientId;
  final String recipientName;
  final ValueChanged<ChatTransferData> onTransferSuccess;

  const ChatTransferModal({
    super.key,
    required this.recipientId,
    required this.recipientName,
    required this.onTransferSuccess,
  });

  static Future<void> show({
    required BuildContext context,
    required String recipientId,
    required String recipientName,
    required ValueChanged<ChatTransferData> onTransferSuccess,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ChatTransferModal(
        recipientId: recipientId,
        recipientName: recipientName,
        onTransferSuccess: onTransferSuccess,
      ),
    );
  }

  @override
  State<ChatTransferModal> createState() => _ChatTransferModalState();
}

class _ChatTransferModalState extends State<ChatTransferModal> {
  final _wallet = WalletRepository();
  final _inventory = InventoryRepository();

  String _transferType = 'STARS'; // 'STARS', 'TON', 'GIFT'
  final TextEditingController _amountController = TextEditingController(text: '50');
  InventoryItem? _selectedGift;
  bool _isProcessing = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _executeTransfer() async {
    final amt = double.tryParse(_amountController.text.trim()) ?? 0.0;

    if (_transferType == 'TON') {
      if (amt <= 0 || amt > _wallet.tonBalance.value) {
        _showError('Insufficient TON balance!');
        return;
      }
    } else if (_transferType == 'STARS') {
      if (amt.toInt() <= 0 || amt.toInt() > _wallet.starsBalance.value) {
        _showError('Insufficient Stars balance!');
        return;
      }
    } else if (_transferType == 'GIFT') {
      if (_selectedGift == null) {
        _showError('Please select a gift to transfer!');
        return;
      }
    }

    setState(() => _isProcessing = true);

    // Prompt biometric authentication if available
    try {
      await authenticateWithBiometrics();
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 600));

    ChatTransferData transfer;

    if (_transferType == 'TON') {
      _wallet.debitTon(amt, 'P2P Transfer to ${widget.recipientName}');
      transfer = ChatTransferData(
        type: 'TON',
        amount: amt,
        status: 'CONFIRMED',
        txHash: '0x${Random().nextInt(999999).toRadixString(16)}...p2p',
      );
    } else if (_transferType == 'STARS') {
      final starsAmt = amt.toInt();
      _wallet.debitStars(starsAmt, 'P2P Transfer to ${widget.recipientName}');
      transfer = ChatTransferData(
        type: 'STARS',
        amount: starsAmt.toDouble(),
        status: 'CONFIRMED',
      );
    } else {
      // Gift transfer
      final gift = _selectedGift!;
      final items = List<InventoryItem>.from(_inventory.userItems.value);
      items.removeWhere((i) => i.instanceId == gift.instanceId);
      _inventory.userItems.value = items;

      transfer = ChatTransferData(
        type: 'GIFT',
        giftId: gift.giftId,
        giftName: gift.name,
        giftAsset: gift.webpPath,
        editionNumber: gift.editionNumber,
        status: 'CONFIRMED',
      );
    }

    HapticFeedbackService.heavyImpact();

    if (!mounted) return;
    Navigator.pop(context);
    widget.onTransferSuccess(transfer);
  }

  void _showError(String message) {
    HapticFeedbackService.error();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return Container(
      constraints: BoxConstraints(maxHeight: media.size.height * 0.85),
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF0F141F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Color(0xFF2DD4BF), width: 1.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2DD4BF).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded, color: Color(0xFF2DD4BF), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('In-Chat Transfer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Send currency or gifts to ${widget.recipientName}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white54),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Transfer Type Segmented Selector
          Row(
            children: [
              _buildTypeChip('STARS', Icons.star_rounded, 'Telegram Stars', const Color(0xFFFFB800)),
              const SizedBox(width: 8),
              _buildTypeChip('TON', Icons.diamond_outlined, 'TON Coin', const Color(0xFF0098EA)),
              const SizedBox(width: 8),
              _buildTypeChip('GIFT', Icons.card_giftcard_rounded, 'Send Gift', const Color(0xFF2DD4BF)),
            ],
          ),

          const SizedBox(height: 20),

          if (_transferType != 'GIFT') ...[
            Text(
              'Amount (${_transferType == 'TON' ? 'TON' : 'Stars'})',
              style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF161C2A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                suffixText: _transferType == 'TON' ? 'TON' : 'Stars',
                suffixStyle: TextStyle(
                  color: _transferType == 'TON' ? const Color(0xFF0098EA) : const Color(0xFFFFB800),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder<double>(
              valueListenable: _wallet.tonBalance,
              builder: (ctx, ton, _) => ValueListenableBuilder<int>(
                valueListenable: _wallet.starsBalance,
                builder: (ctx, stars, _) => Text(
                  _transferType == 'TON' ? 'Available: $ton TON' : 'Available: $stars Stars',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ),
            ),
          ] else ...[
            const Text(
              'Select Gift from Inventory',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ValueListenableBuilder<List<InventoryItem>>(
              valueListenable: _inventory.userItems,
              builder: (ctx, items, _) {
                final gifts = items.where((i) => !i.isDigital).toList();
                if (gifts.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161C2A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('No Telegram gifts available in your inventory.', style: TextStyle(color: Colors.white38, fontSize: 12)),
                    ),
                  );
                }

                return SizedBox(
                  height: 110,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: gifts.length,
                    itemBuilder: (ctx, idx) {
                      final g = gifts[idx];
                      final isSel = _selectedGift?.instanceId == g.instanceId;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedGift = g),
                        child: Container(
                          width: 85,
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xFF2DD4BF).withValues(alpha: 0.2) : const Color(0xFF161C2A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSel ? const Color(0xFF2DD4BF) : Colors.white12,
                              width: isSel ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                g.webpPath,
                                width: 44,
                                height: 44,
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) => const Icon(Icons.card_giftcard, color: Colors.amber),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                g.name,
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _executeTransfer,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2DD4BF),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isProcessing
                  ? const CircularProgressIndicator(color: Colors.black)
                  : Text(
                      'Confirm & Send to ${widget.recipientName}',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String type, IconData icon, String label, Color color) {
    final isSel = _transferType == type;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _transferType = type;
            if (type == 'TON') _amountController.text = '0.5';
            if (type == 'STARS') _amountController.text = '50';
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSel ? color.withValues(alpha: 0.18) : const Color(0xFF161C2A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSel ? color : Colors.white12,
              width: isSel ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSel ? color : Colors.white60, size: 18),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSel ? Colors.white : Colors.white60,
                  fontSize: 10,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

