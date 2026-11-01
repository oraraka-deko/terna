import 'package:terna/screens/games/mines_arena_game.dart';
import 'package:terna/screens/games/upgrade_game_screen.dart';
import 'package:terna/screens/games/tower_game_screen.dart';
import 'package:terna/screens/games/plinko_game_screen.dart';
import 'package:terna/screens/games/territory_game_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_telegram_miniapp/flutter_telegram_miniapp.dart';
import 'package:terna/screens/games/american_roulette_game.dart';
import 'package:terna/screens/games/sun_or_moon.dart';
import 'package:terna/features/telegram_app_root.dart';


import 'package:terna/models/ui_models/app_item.dart';
import 'package:terna/widgets/app_elements/context_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';

class AppDrawerScreen extends StatefulWidget {
  const AppDrawerScreen({super.key});

  @override
  State<AppDrawerScreen> createState() => _AppDrawerScreenState();
}

class _AppDrawerScreenState extends State<AppDrawerScreen> {
  // Sample dataset replicating the screenshot
  String _colorScheme = 'Not initialized';
  double _viewportHeight = 0.0;
  String _initData = "Empty";
  String _headerColor = "No color set";
  final String _mainButtonText = "Main Button";
  late final List<AppItem> _apps;

  @override
  void initState() {
    super.initState();
     _initMiniApp();

    _apps = [
      AppItem(
        name: 'Telegram',
        hasDot: true,
        iconWidget: Container(
          width: 58,
          height: 58,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFF2AABEE), Color(0xFF229ED9)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Center(
            child: Image.asset(
              'assets/telegram/app_icons/Style=Default.png',
              width: 58,
              height: 58,
              fit: BoxFit.cover,
            ),
          ),
        ),
        screen: const TelegramAppRoot(),
      ),
      AppItem(
        name: 'Roulette',
        hasDot: true,
        iconWidget: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF0E2E18), Color(0xFF06180D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: const Color(0xFFFFD700), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.casino_rounded,
              color: Color(0xFFFFD700),
              size: 30,
            ),
          ),
        ),
        screen: const RouletteGameScreen(),
      ),
      AppItem(
        name: 'Sun or Moon',
        hasDot: true,
        iconWidget: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFFFB300), Color(0xFF673AB7), Color(0xFF1B142F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white70, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFB300).withValues(alpha: 0.35),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 10,
                  top: 12,
                  child: Icon(
                    Icons.wb_sunny_rounded,
                    color: Color(0xFFFFD700),
                    size: 20,
                  ),
                ),
                Positioned(
                  right: 10,
                  bottom: 12,
                  child: Icon(
                    Icons.nightlight_round,
                    color: Color(0xFFE1BEE7),
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
        screen: const SunOrMoonGameScreen(),
      ),
      AppItem(
        name: 'Mines Arena',
        hasDot: true,
        iconWidget: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF261010), Color(0xFF070B14)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: const Color(0xFFFF9800), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF9800).withValues(alpha: 0.35),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Image.asset(
              'assets/mines_bomb_game/UI_assets/slice_16.png',
              width: 36,
              height: 36,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                Icons.brightness_low_rounded,
                color: Color(0xFFFF9800),
                size: 28,
              ),
            ),
          ),
        ),
        screen: const MinesArenaGameScreen(),
      ),
      AppItem(
        name: 'Upgrade Game',
        hasDot: true,
        iconWidget: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF1E2810), Color(0xFF0D121B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: const Color(0xFFA3E635), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFA3E635).withValues(alpha: 0.35),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.change_circle_rounded,
              color: Color(0xFFA3E635),
              size: 32,
            ),
          ),
        ),
        screen: const UpgradeGameScreen(),
      ),
      AppItem(
        name: 'Tower',
        hasDot: true,
        iconWidget: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF2E1065), Color(0xFF0F172A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: const Color(0xFFA855F7), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFA855F7).withValues(alpha: 0.35),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.stairs_rounded,
              color: Color(0xFFC084FC),
              size: 32,
            ),
          ),
        ),
        screen: const TowerGameScreen(),
      ),
      AppItem(
        name: 'Plinko',
        hasDot: true,
        iconWidget: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF162B0A), Color(0xFF090D1A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: const Color(0xFFCCFF00), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFCCFF00).withValues(alpha: 0.35),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.blur_on_rounded,
              color: Color(0xFFCCFF00),
              size: 32,
            ),
          ),
        ),
        screen: const PlinkoGameScreen(),
      ),
      AppItem(
        name: 'Territory Jackpot',
        hasDot: true,
        iconWidget: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF0F3B37), Color(0xFF0D121F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: const Color(0xFF2DD4BF), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2DD4BF).withValues(alpha: 0.35),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.pie_chart_rounded,
              color: Color(0xFF2DD4BF),
              size: 30,
            ),
          ),
        ),
        screen: const TerritoryGameScreen(),
      ),
      AppItem(
        name: 'YouTube',

        iconWidget: _buildCircleIcon(
          bgColor: Colors.white,

          child: const Icon(
            Icons.play_arrow_rounded,
            color: Colors.red,
            size: 32,
          ),
        ),
      ),

      AppItem(
        name: 'YT Music',

        iconWidget: _buildCircleIcon(
          bgColor: const Color(0xFFFF0000),

          child: const Icon(
            Icons.play_circle_fill_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),

      AppItem(
        name: 'Gemini',

        iconWidget: _buildCircleIcon(
          bgColor: Colors.white,

          child: const Icon(
            Icons.auto_awesome,
            color: Colors.blueAccent,
            size: 28,
          ),
        ),
      ),

      AppItem(
        name: 'Play Store',

        iconWidget: _buildCircleIcon(
          bgColor: Colors.white,

          child: const Icon(Icons.play_arrow, color: Colors.green, size: 28),
        ),
      ),

      AppItem(
        name: 'AB DM',

        iconWidget: _buildCircleIcon(
          bgColor: const Color(0xFF2C1B4D),

          child: const Icon(
            Icons.file_download_outlined,
            color: Colors.purpleAccent,
            size: 28,
          ),
        ),
      ),

      AppItem(
        name: 'AmneziaVPN',

        iconWidget: _buildCircleIcon(
          bgColor: const Color(0xFF1A1A1A),

          child: const Icon(Icons.security, color: Colors.orange, size: 28),
        ),
      ),

      AppItem(
        name: 'App vault',

        iconWidget: _buildCircleIcon(
          bgColor: const Color(0xFF26E07F),

          child: const Icon(
            Icons.layers_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),

      AppItem(
        name: 'Authenticator',

        iconWidget: _buildCircleIcon(
          bgColor: Colors.white,

          child: const Icon(Icons.tag, color: Colors.blue, size: 28),
        ),
      ),

      AppItem(
        name: 'Bike Mayhem',

        iconWidget: _buildCircleIcon(
          bgColor: const Color(0xFFC3E600),

          child: const Icon(
            Icons.directions_bike,
            color: Colors.black,
            size: 28,
          ),
        ),
      ),

      AppItem(
        name: 'Calculator',

        iconWidget: _buildCircleIcon(
          bgColor: const Color(0xFFFF6B35),

          child: const Icon(Icons.drag_handle, color: Colors.white, size: 28),
        ),
      ),

      AppItem(
        name: 'Camera',

        iconWidget: _buildGradientIcon(
          colors: [Colors.blue, Colors.purple, Colors.yellow],

          child: const Icon(Icons.camera_alt, color: Colors.white, size: 24),
        ),
      ),

      AppItem(
        name: 'ChatGPT',

        iconWidget: _buildCircleIcon(
          bgColor: Colors.white,

          child: const Icon(
            Icons.filter_vintage_rounded,
            color: Colors.black,
            size: 28,
          ),
        ),
      ),

      AppItem(
        name: 'Chrome Beta',

        iconWidget: _buildCircleIcon(
          bgColor: Colors.white,

          child: const Icon(Icons.public, color: Colors.redAccent, size: 28),
        ),
      ),

      AppItem(
        name: 'Contacts',

        iconWidget: _buildCircleIcon(
          bgColor: Colors.white,

          child: const Icon(Icons.person, color: Colors.blue, size: 30),
        ),
      ),

      AppItem(
        name: 'Downloads',

        iconWidget: _buildCircleIcon(
          bgColor: const Color(0xFF00C853),

          child: const Icon(
            Icons.shield_outlined,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),

      AppItem(
        name: 'Drive',

        iconWidget: _buildCircleIcon(
          bgColor: Colors.white,

          child: const Icon(Icons.add_to_drive, color: Colors.amber, size: 28),
        ),
      ),

      AppItem(
        name: 'Emby',

        hasDot: true,

        iconWidget: _buildCircleIcon(
          bgColor: const Color(0xFF4CAF50),

          child: const Icon(Icons.play_arrow, color: Colors.white, size: 28),
        ),
      ),

      AppItem(
        name: 'Exclave',

        iconWidget: _buildCircleIcon(
          bgColor: const Color(0xFFC2185B),

          child: const Icon(Icons.blur_circular, color: Colors.white, size: 28),
        ),
      ),

      AppItem(
        name: 'Fditor',

        hasDot: true,

        iconWidget: _buildCircleIcon(
          bgColor: Colors.white,

          child: const Icon(Icons.code_rounded, color: Colors.blue, size: 28),
        ),
      ),

      AppItem(
        name: 'File Manager',

        iconWidget: _buildCircleIcon(
          bgColor: const Color(0xFF42A5F5),

          child: const Icon(Icons.folder, color: Colors.white, size: 28),
        ),
      
      ),

      AppItem(
        name: 'Flutter Build',

        hasDot: true,

        iconWidget: _buildCircleIcon(
          bgColor: Colors.black,

          child: const Icon(Icons.flutter_dash, color: Colors.cyan, size: 28),
        ),
      ),

      AppItem(
        name: 'Fortnite',

        iconWidget: _buildCircleIcon(
          bgColor: const Color(0xFF8E24AA),

          child: const Icon(
            Icons.sports_esports,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),

      AppItem(
        name: 'Gallery',

        iconWidget: _buildCircleIcon(
          bgColor: Colors.white,

          child: const Icon(
            Icons.photo_size_select_actual,
            color: Colors.lightBlue,
            size: 28,
          ),
        ),
      ),

      AppItem(
        name: 'Game Center',

        iconWidget: _buildCircleIcon(
          bgColor: Colors.white,

          child: const Icon(
            Icons.gamepad,
            color: Colors.orangeAccent,
            size: 28,
          ),
        ),
      ),
      AppItem(
        name: 'Player',
      
        iconWidget: _buildCircleIcon(
          bgColor: Colors.blue,
          child: const Icon(
            Icons.play_circle_rounded,
            color: Colors.pinkAccent,
            size: 28,
          ),
        ),
      ),
    ];
  }

  // Circular Icon Helper

  Widget _buildCircleIcon({required Color bgColor, required Widget child}) {
    return Container(
      width: 58,

      height: 58,

      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),

      child: Center(child: child),
    );
  }

  // Gradient Icon Helper for camera/special app icons

  Widget _buildGradientIcon({
    required List<Color> colors,
    required Widget child,
  }) {
    return Container(
      width: 58,

      height: 58,

      decoration: BoxDecoration(
        shape: BoxShape.circle,

        gradient: LinearGradient(
          colors: colors,

          begin: Alignment.topLeft,

          end: Alignment.bottomRight,
        ),
      ),

      child: Center(child: child),
    );
  }
  Future<void> _initMiniApp() async {
    try {
      WebApp().init();
      setState(() {
        _colorScheme = WebApp().colorScheme.name;
        _viewportHeight = WebApp().viewportHeight;
        _initData = WebApp().initData;
        _headerColor = WebApp().headerColorRaw ?? "No color set";
      });
      _setupEventListeners();
      if (kDebugMode) {
        print('MiniApp ready: $_colorScheme, $_viewportHeight, $_initData, $_headerColor, $_mainButtonText');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing Mini App: $e');
      }
      setState(() {
        _colorScheme = 'Initialization error';
      });
    }
  }

  void _setupEventListeners() {
    final eventHandler = WebApp().eventHandler;

    eventHandler.themeChanged.listen((theme) {
      setState(() {
        _colorScheme = theme.$1.name;
      });
      if (kDebugMode) {
        print("Theme changed: ${theme.$1.name}");
      }
    });

    eventHandler.viewportChanged.listen((data) {
      setState(() {
        _viewportHeight = data.$2;
      });
      if (kDebugMode) {
        print("Viewport changed: ${data.$2}");
      }
    });

    eventHandler.mainButtonClicked.listen((event) {
      if (kDebugMode) {
        print('Main button clicked');
      }
      _showPopup();
    });
  }

  Future<void> _showPopup() async {
    final popupParams = PopupParams(
      message: "Some message",
      buttons: [PopupButton(text: "OK", type: PopupButtonType.ok)],
    );

    final buttonId = await WebApp().showPopup(params: popupParams);
    if (kDebugMode) {
      print("Button clicked: $buttonId");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Top Header Row
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 12.0,
                  ),

                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,

                    crossAxisAlignment: CrossAxisAlignment.center,

                    children: [
                      // Active Tab "All" with Indicator
                      Column(
                        mainAxisSize: MainAxisSize.min,

                        crossAxisAlignment: CrossAxisAlignment.center,

                        children: [
                          const Text(
                            'All',

                            style: TextStyle(
                              color: Color(0xFF2196F3),

                              fontSize: 16,

                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Container(
                            height: 2.5,

                            width: 18,

                            decoration: BoxDecoration(
                              color: const Color(0xFF2196F3),

                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),

                      // Settings Icon
                      IconButton(
                        onPressed: () {},

                        icon: const Icon(
                          Icons.settings_outlined,

                          color: Colors.white70,

                          size: 24,
                        ),

                        padding: EdgeInsets.zero,

                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),

                // Smooth Scrolling Grid of Apps
                Expanded(
                  child: GridView.builder(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),

                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),

                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,

                          mainAxisSpacing: 18,

                          crossAxisSpacing: 8,

                          childAspectRatio: 0.78,
                        ),

                    itemCount: _apps.length,

                    itemBuilder: (context, index) {
                      final app = _apps[index];

                      return _buildAppItemWidget(app);
                    },
                  ),
                ),
              ],
            ),

            // Floating Bottom Search Bar
            Align(
              alignment: Alignment.bottomCenter,

              child: Container(
                margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),

                height: 52,

                decoration: BoxDecoration(
                  color: const Color(0xFF141414),

                  borderRadius: BorderRadius.circular(26),

                  border: Border.all(
                    color: Colors.white.withAlpha(20),

                    width: 1,
                  ),
                ),

                child: Row(
                  children: [
                    const SizedBox(width: 18),

                    const Icon(
                      Icons.search_rounded,

                      color: Colors.white70,

                      size: 22,
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: TextField(
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),

                        cursorColor: const Color(0xFF2196F3),

                        decoration: InputDecoration(
                          hintText: 'Search for apps',

                          hintStyle: TextStyle(
                            color: Colors.white.withAlpha(100),

                            fontSize: 15,
                          ),

                          border: InputBorder.none,

                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Individual App Tile

  Widget _buildAppItemWidget(AppItem app) {
    return Hero(
      tag: app.name,
      child: ContextMenuRegion(
        contextMenu: menu,
        onItemSelected: (value) {
          //     print(value);
        },
        child: InkWell(
          onTap: () async {
            if (app.screen != null) {
              if (app.screenaction != null) {
                await app.screenaction!();
              }
              if (!mounted) return;
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => app.screen!),
              );
              if (app.screenaction != null) {
              //  await phoneStyle();
              }
            }
          },
      
          borderRadius: BorderRadius.circular(16),
      
          splashColor: Colors.white10,
      
          highlightColor: Colors.transparent,
      
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
      
            children: [
              app.iconWidget,
      
              const SizedBox(height: 8),
      
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
      
                mainAxisSize: MainAxisSize.min,
      
                children: [
                  if (app.hasDot) ...[
                    Container(
                      width: 5,
      
                      height: 5,
      
                      margin: const EdgeInsets.only(right: 4),
      
                      decoration: const BoxDecoration(
                        color: Color(0xFF2196F3),
      
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
      
                  Flexible(
                    child: Text(
                      app.name,
      
                      maxLines: 1,
      
                      overflow: TextOverflow.ellipsis,
      
                      textAlign: TextAlign.center,
      
                      style: const TextStyle(
                        color: Colors.white,
      
                        fontSize: 12,
      
                        fontWeight: FontWeight.w400,
      
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
