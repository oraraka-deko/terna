import 'package:flutter/material.dart';
import 'package:terna/services/api/gateway_api_service.dart';
import 'package:terna/services/wallet/wallet_repository.dart';

class DebugBalanceAdjustmentScreen extends StatefulWidget {
  const DebugBalanceAdjustmentScreen({super.key});

  @override
  State<DebugBalanceAdjustmentScreen> createState() =>
      _DebugBalanceAdjustmentScreenState();
}

class _DebugBalanceAdjustmentScreenState
    extends State<DebugBalanceAdjustmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userIdController =
      TextEditingController(text: GatewayApiService().currentUserId);
  final _tonDeltaController = TextEditingController(text: '0');
  final _starsDeltaController = TextEditingController(text: '0');
  final _reasonController = TextEditingController(text: 'Local testing');
  bool _isSaving = false;

  @override
  void dispose() {
    _userIdController.dispose();
    _tonDeltaController.dispose();
    _starsDeltaController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final result = await GatewayApiService().adjustUserBalance(
        userId: _userIdController.text.trim(),
        tonDelta: double.parse(_tonDeltaController.text.trim()),
        starsDelta: int.parse(_starsDeltaController.text.trim()),
        reason: _reasonController.text.trim(),
      );
      final wallet = result['wallet'];
      if (_userIdController.text.trim() ==
          GatewayApiService().currentUserId) {
        await WalletRepository().refreshBalances();
      }
      if (!mounted) return;
      final ton = wallet is Map ? wallet['tonBalance'] : null;
      final stars = wallet is Map ? wallet['starsBalance'] : null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Balance adjusted. TON: ${ton ?? 'updated'}, Stars: ${stars ?? 'updated'}.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Balance adjustment failed: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String? _validateTon(String? value) {
    final amount = double.tryParse(value?.trim() ?? '');
    if (amount == null || !amount.isFinite) return 'Enter a valid TON delta.';
    return null;
  }

  String? _validateStars(String? value) {
    if (int.tryParse(value?.trim() ?? '') == null) {
      return 'Enter a whole-number Stars delta.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debug balance adjustment')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Adjustments are sent to the backend admin endpoint. Use positive values to add funds and negative values to subtract them.',
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _userIdController,
                decoration: const InputDecoration(labelText: 'Telegram user ID'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'A user ID is required.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tonDeltaController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: const InputDecoration(labelText: 'TON delta'),
                validator: _validateTon,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _starsDeltaController,
                keyboardType: const TextInputType.numberWithOptions(signed: true),
                decoration: const InputDecoration(labelText: 'Stars delta'),
                validator: _validateStars,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(labelText: 'Reason'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'A reason is required.'
                    : null,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _isSaving ? null : _submit,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.account_balance_wallet_outlined),
                label: Text(_isSaving ? 'Saving...' : 'Apply adjustment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
