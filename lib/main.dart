

import 'package:terna/screens/app_drawer_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:flutter_telegram_miniapp/flutter_telegram_miniapp.dart';

import 'package:flutter/services.dart';
import 'core/widgets/telegram_safe_area.dart';
late AudioSource flipping;
late SoLoud soloud;
late AudioSource spins;
late WebApp webapp;
late AudioSource startMatch;
late AudioSource bombEnd;
late AudioSource notBomb;
Future<void> main()async {

 WidgetsFlutterBinding.ensureInitialized();


  SystemChrome.setSystemUIOverlayStyle(

    const SystemUiOverlayStyle(

      statusBarColor: Colors.transparent,

      statusBarIconBrightness: Brightness.light,

      systemNavigationBarColor: Colors.black,

      systemNavigationBarIconBrightness: Brightness.light,

    ),

  );
  try {
    soloud = SoLoud.instance;
    await soloud.init();
    flipping = await soloud.loadAsset('assets/sounds/sun_or_moon/flip.mp3');
    spins = await soloud.loadAsset('assets/sounds/roulette/spin.mp3');
        startMatch = await soloud.loadAsset('assets/sounds/shared/short_tick.wav');
                notBomb = await soloud.loadAsset('assets/sounds/shared/plinko_ding.wav');
                                bombEnd = await soloud.loadAsset('assets/sounds/shared/shocked.mp3');



  } catch (e) {
    debugPrint('Audio init warning: $e');
  }

   final webApp = WebApp(); // Singleton instance
  try {
    webApp.init();
    webApp.ready();
    webApp.expand();
    webApp.enableClosingConfirmation(); // Prompts user before closing
    webApp.requestFullscreen();
    webApp.disableVerticalSwipes();
    
  } catch (e) {
    debugPrint('Running outside Telegram WebView: $e');
  }
  runApp(
    LauncherApp());

}

class LauncherApp extends StatelessWidget {
  const LauncherApp({super.key});

  @override
  Widget build(BuildContext context) {
 
    return  MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(

        scaffoldBackgroundColor: Colors.black,

      ),

        builder: (context, child) => TelegramSafeArea(
          child: child ?? const SizedBox.shrink(),
        ),
        home: const AppDrawerScreen(),
      );
  
  }
}


