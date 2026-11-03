library;

import 'package:flutter/foundation.dart';

/// Central environment configuration for Terna client.
/// Connects the Flutter frontend to the Express backend (D:\terna\backend).
class Env {
  Env._();

  /// Configurable backend URL.
  /// Can be overridden via dart-define: --dart-define=BACKEND_URL=https://...
  /// Defaults to localhost:8080 during local development.
  static const String _defaultBackendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://api.esil.click',
  );

  static String _customBackendUrl = '';

  /// Set backend URL at runtime (e.g. from developer settings or dynamic discovery)
  static void setBackendUrl(String url) {
    _customBackendUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
  }

  /// Active backend URL
  static String get backendUrl {
    if (_customBackendUrl.isNotEmpty) {
      return _customBackendUrl;
    }
    return _defaultBackendUrl;
  }

  /// Base API route: e.g. http://localhost:8080/api
  static String get apiBaseUrl => '$backendUrl/api';

  /// General notifications SSE stream endpoint
  static String get sseUrl => '$apiBaseUrl/notifications/events';

  /// Real-time chat SSE stream endpoint
  static String get chatSseUrl => '$apiBaseUrl/chat/events';

  /// Real-time Area PVP SSE stream endpoint
  static String get areaSseUrl => '$apiBaseUrl/games/area/events';

  /// Telegram Bot configuration
  static const String telegramBotUsername = String.fromEnvironment(
    'TG_BOT_USERNAME',
    defaultValue: 'terna_arena_bot',
  );

  /// Test / Demo Fallback Identity (used when not inside a real Telegram WebApp)
  static const String defaultUserId = String.fromEnvironment(
    'DEFAULT_USER_ID',
    defaultValue: 'demo_user_1',
  );

  static const String defaultUsername = String.fromEnvironment(
    'DEFAULT_USERNAME',
    defaultValue: '@terna_player',
  );

  /// TON Connect Manifest URL
  static String get tonConnectManifestUrl {
    if (kIsWeb) {
      final origin = Uri.base.origin;
      if (origin.isNotEmpty) {
        return '$origin/tonconnect-manifest.json';
      }
    }
    return String.fromEnvironment(
      'TON_CONNECT_MANIFEST_URL',
      defaultValue: 'https://giftshaper.esil.click/tonconnect-manifest.json',
    );
  }

  /// Request timeout in milliseconds (fail-safe for offline/slow connections)
  static const Duration requestTimeout = Duration(seconds: 12);
}
