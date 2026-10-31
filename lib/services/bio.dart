import 'package:flutter/material.dart';
import 'package:flutter_telegram_miniapp/flutter_telegram_miniapp.dart';

Future<void> authenticateWithBiometrics() async {
  final bio = WebApp().biometricManager;

  // 1. Initialize biometric state first
  await bio.init();

  if (!bio.isBiometricAvailable) {
    debugPrint('Biometrics not available on this device');
    return;
  }

  // 2. Request permission if not yet granted
  if (!bio.isAccessGranted) {
    final granted = await bio.requestAccess(
      params: BiometricRequestAccessParams(
         "Authenticate to sign your transaction",
      ),
    );
    if (!granted) return;
  }

  // 3. Authenticate and retrieve saved token
  final (authenticated, token) = await bio.authenticate(
    params: BiometricAuthenticateParams(
       "Confirm your identity",
    ),
  );

  if (authenticated) {
    debugPrint('Authenticated! Token: $token');
  }
}