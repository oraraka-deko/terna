// Native Alert
import 'package:flutter/material.dart';
import 'package:flutter_telegram_miniapp/flutter_telegram_miniapp.dart';

Future<void> showAlertExample() async {
  await WebApp().showAlert(message: "Files saved successfully!");
}

// Native Confirmation
Future<void> showConfirmExample() async {
  final bool confirmed = await WebApp().showConfirm(
    message: "Do you really want to delete this session?",
  );
  if (confirmed) {
    debugPrint("Deleted!");
  }
}

// Native Invoices (Stars or Payment Providers)
Future<void> openInvoiceExample(String invoiceUrl) async {
  final InvoiceResult result = await WebApp().openInvoice(url: invoiceUrl);
  debugPrint('Payment status: ${result.name}'); // e.g., paid, cancelled, failed
}