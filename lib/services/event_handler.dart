import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_telegram_miniapp/flutter_telegram_miniapp.dart';

class EventWatcherExample extends StatefulWidget {
  const EventWatcherExample({super.key});

  @override
  State<EventWatcherExample> createState() => _EventWatcherExampleState();
}

class _EventWatcherExampleState extends State<EventWatcherExample> {
  final _webApp = WebApp();
  final List<StreamSubscription> _subscriptions = [];
void setupBottomButtons() {
  final webApp = WebApp();

  // Configure MainButton
  webApp.mainButton
    ..setText('PAY NOW')
    ..setParams(color: Colors.green)
    ..setParams(textColor:Colors.white)
    ..show();

  // Configure SecondaryButton (if supported in client version)
  webApp.secondaryButton
    ..setText('CANCEL')
    ..setParams(position: BottomButtonPosition.left)
    ..show();

  // Listen to clicks
  webApp.eventHandler.mainButtonClicked.listen((_) {
    webApp.mainButton.showProgress(leaveActive: false);
    
    // Trigger Telegram haptic
    webApp.hapticFeedback.notificationOccurred(type:
      HapticFeedbackNotificationType.success,
    );
  });
}
  @override
  void initState() {
    super.initState();

    // 1. Back button click stream
    _subscriptions.add(
      _webApp.eventHandler.backButtonClicked.listen((_) {
        debugPrint('Telegram back button clicked');
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }),
    );

    // 2. Viewport height/state change stream (returns record: ($1 bool isStateStable, $2 double height))
    _subscriptions.add(
      _webApp.eventHandler.viewportChanged.listen((record) {
        debugPrint('Stable: ${record.$1}, New Height: ${record.$2}');
      }),
    );

    // 3. Theme change stream (returns record: ($1 WebAppColorScheme, $2 ThemeParams))
    _subscriptions.add(
      _webApp.eventHandler.themeChanged.listen((themeRecord) {
        debugPrint('New scheme: ${themeRecord.$1.name}');
      }),
    );
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const Placeholder();
}