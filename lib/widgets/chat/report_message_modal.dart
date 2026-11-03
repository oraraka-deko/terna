library;

import 'package:flutter/material.dart';
import '../../services/haptic.dart';

class ReportMessageModal extends StatefulWidget {
  final String messageId;
  final String senderName;

  const ReportMessageModal({
    super.key,
    required this.messageId,
    required this.senderName,
  });

  static Future<void> show(BuildContext context, {required String messageId, required String senderName}) {
    return showDialog(
      context: context,
      builder: (ctx) => ReportMessageModal(messageId: messageId, senderName: senderName),
    );
  }

  @override
  State<ReportMessageModal> createState() => _ReportMessageModalState();
}

class _ReportMessageModalState extends State<ReportMessageModal> {
  String _selectedReason = 'Spam / Unsolicited Advertising';

  final List<String> _reasons = const [
    'Spam / Unsolicited Advertising',
    'Scam / Crypto Phishing',
    'Harassment / Hate Speech',
    'Inappropriate Content',
    'Impersonation',
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF131722),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
      title: Row(
        children: [
          const Icon(Icons.report_problem_rounded, color: Color(0xFFEF4444), size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Report Message from ${widget.senderName}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select violation reason:', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 10),
          ..._reasons.map((r) {
            final isSel = _selectedReason == r;
            return InkWell(
              onTap: () => setState(() => _selectedReason = r),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  children: [
                    Icon(
                      isSel ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: isSel ? const Color(0xFFEF4444) : Colors.white38,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(r, style: const TextStyle(color: Colors.white, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: () {
            HapticFeedbackService.heavyImpact();
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Report submitted to Terna Moderation. Thank you!'),
                backgroundColor: Color(0xFF10B981),
              ),
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
          child: const Text('Submit Report', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
