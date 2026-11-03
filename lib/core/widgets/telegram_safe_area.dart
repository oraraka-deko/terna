import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_telegram_miniapp/flutter_telegram_miniapp.dart';

class TelegramSafeArea extends StatefulWidget {
  final Widget child;

  const TelegramSafeArea({super.key, required this.child});

  @override
  State<TelegramSafeArea> createState() => _TelegramSafeAreaState();
}

class _TelegramSafeAreaState extends State<TelegramSafeArea> {
  StreamSubscription<SafeAreaInset>? _safeAreaSubscription;
  StreamSubscription<ContentSafeAreaInset>? _contentSafeAreaSubscription;
  double _safeAreaTop = 0;
  double _contentSafeAreaTop = 0;
  double _topInset = 0;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) return;

    try {
      final webApp = WebApp();
      _safeAreaTop = webApp.safeAreaInset.top;
      _contentSafeAreaTop = webApp.contentSafeAreaInset.top;
      _updateTopInset();
      _safeAreaSubscription =
          webApp.eventHandler.safeAreaChanged.listen((inset) {
        _safeAreaTop = inset.top;
        _updateTopInset();
      });
      _contentSafeAreaSubscription =
          webApp.eventHandler.contentSafeAreaChanged.listen((inset) {
        _contentSafeAreaTop = inset.top;
        _updateTopInset();
      });
    } catch (error) {
      debugPrint('[TelegramSafeArea] Unable to read Telegram insets: $error');
    }
  }

  void _updateTopInset() {
    final nextInset = math.max(_safeAreaTop, _contentSafeAreaTop);
    if (nextInset == _topInset) return;
    if (!mounted) {
      _topInset = nextInset;
      return;
    }
    setState(() => _topInset = nextInset);
  }

  @override
  void dispose() {
    _safeAreaSubscription?.cancel();
    _contentSafeAreaSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = math.max(mediaQuery.padding.top, _topInset);
    final topViewPadding = math.max(mediaQuery.viewPadding.top, _topInset);
    return MediaQuery(
      data: mediaQuery.copyWith(
        padding: mediaQuery.padding.copyWith(top: topPadding),
        viewPadding: mediaQuery.viewPadding.copyWith(top: topViewPadding),
      ),
      child: widget.child,
    );
  }
}
