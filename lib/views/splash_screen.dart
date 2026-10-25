import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/farm_theme.dart';
import 'main_menu_screen.dart';

/// Cozy Low-Poly 3D Farm Splash Screen with HexaApps branding and smooth progress bar.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;
  Timer? _navTimer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2100),
    )..forward();

    _scaleAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );

    _navTimer = Timer(const Duration(milliseconds: 2300), _goToMainMenu);
  }

  void _goToMainMenu() {
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MainMenuScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B2E19),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _goToMainMenu,
        child: SizedBox.expand(
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1E3F20),
                  Color(0xFF2D5A27),
                  Color(0xFF1B2E19),
                ],
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                  // Warm Sunlight Radial Glow
                  Positioned(
                    top: -80,
                    left: -60,
                    right: -60,
                    height: 360,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            FarmTheme.sunWarmYellow.withValues(alpha: 0.32),
                            FarmTheme.goldenStraw.withValues(alpha: 0.10),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Center Animated Logo & Progress Bar
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 24,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(flex: 2),

                          // HexaApps Studio Pill
                          FadeTransition(
                            opacity: _fadeAnim,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: FarmTheme.sunWarmYellow
                                      .withValues(alpha: 0.55),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.hexagon_rounded,
                                    color: FarmTheme.sunWarmYellow,
                                    size: 15,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'HEXAAPPS STUDIO',
                                    style: TextStyle(
                                      color: FarmTheme.uiTextGold,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // 3D Emblem Badge
                          ScaleTransition(
                            scale: _scaleAnim,
                            child: Container(
                              width: 132,
                              height: 132,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    FarmTheme.sunWarmYellow,
                                    FarmTheme.goldenStraw,
                                    FarmTheme.deepStraw,
                                  ],
                                ),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: FarmTheme.goldenStraw
                                        .withValues(alpha: 0.55),
                                    blurRadius: 28,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  const Icon(
                                    Icons.agriculture_rounded,
                                    size: 68,
                                    color: FarmTheme.tractorRed,
                                  ),
                                  Positioned(
                                    bottom: 16,
                                    right: 16,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: FarmTheme.uiPillBg,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: FarmTheme.sunWarmYellow,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: const Text(
                                        '3D',
                                        style: TextStyle(
                                          color: FarmTheme.sunWarmYellow,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Game Title
                          FadeTransition(
                            opacity: _fadeAnim,
                            child: const Column(
                              children: [
                                Text(
                                  'CATCH BALES',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.8,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black87,
                                        offset: Offset(0, 3),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'COZY 3D FARM & WAGON STACKER',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: FarmTheme.sunWarmYellow,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Spacer(flex: 2),

                          // Animated Loading Bar
                          AnimatedBuilder(
                            animation: _controller,
                            builder: (context, _) {
                              return Column(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: LinearProgressIndicator(
                                      value: _controller.value,
                                      minHeight: 8,
                                      backgroundColor: Colors.black38,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                        FarmTheme.sunWarmYellow,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'LOADING 3D FARM SCENE... ${(100 * _controller.value).toInt()}%',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
  }
}
