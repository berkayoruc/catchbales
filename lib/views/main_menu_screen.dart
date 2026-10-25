import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/game_controller.dart';
import '../models/game_mode.dart';
import '../utils/audio_haptics.dart';
import '../utils/farm_theme.dart';
import 'game_screen.dart';
import 'widgets/farm_canvas_view.dart';
import 'widgets/settings_dialog.dart';
import 'widgets/stats_dialog.dart';

/// Clean, visual-first Main Menu Screen rendered over the live 3D Low-Poly Farm Canvas.
class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  void _startGame(BuildContext context, GameController game) {
    AudioHapticsService.triggerSpecialHaptic();
    game.resetGame();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const GameScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _openSettings(BuildContext context, GameController game) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => SettingsDialog(game: game),
    );
  }

  void _openStats(BuildContext context, GameController game) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => CaughtStatsDialog(game: game),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();

    return Scaffold(
      backgroundColor: FarmTheme.fieldLushGreen,
      body: SizedBox.expand(
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            color: FarmTheme.fieldLushGreen,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
                // 1. Live Animated 3D Low-Poly Farm Background Preview
                IgnorePointer(
                  child: FarmCanvasView(
                    game: game,
                    isMenuPreview: true,
                  ),
                ),

                // 2. Soft Vignette Overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.45),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.68),
                      ],
                    ),
                  ),
                ),

                // 3. Minimalist Game Menu Foreground
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top Bar: Trophy High Score + Settings Gear
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: FarmTheme.uiPillBg,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: FarmTheme.uiPillBorder,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.emoji_events_rounded,
                                    color: FarmTheme.sunWarmYellow,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${game.highScore}',
                                    style: const TextStyle(
                                      color: FarmTheme.uiTextGold,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  tooltip: 'İstatistikler',
                                  onPressed: () => _openStats(context, game),
                                  style: IconButton.styleFrom(
                                    backgroundColor: FarmTheme.uiPillBg,
                                    side: const BorderSide(
                                      color: FarmTheme.uiPillBorder,
                                      width: 1.5,
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.bar_chart_rounded,
                                    color: FarmTheme.sunWarmYellow,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => _openSettings(context, game),
                                  style: IconButton.styleFrom(
                                    backgroundColor: FarmTheme.uiPillBg,
                                    side: const BorderSide(
                                      color: FarmTheme.uiPillBorder,
                                      width: 1.5,
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.settings_rounded,
                                    color: FarmTheme.sunWarmYellow,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const Spacer(flex: 2),

                        // Clean Game Logo Badge
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: FarmTheme.uiPillBg,
                              borderRadius: BorderRadius.circular(26),
                              border: Border.all(
                                color: FarmTheme.sunWarmYellow,
                                width: 2.2,
                              ),
                              boxShadow: FarmTheme.cozyShadow,
                            ),
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.agriculture_rounded,
                                    color: FarmTheme.tractorRed,
                                    size: 32,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'CATCH BALES',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const Spacer(flex: 3),

                        // Compact Mode Selector Pills (ARCADE vs JENGA)
                        Row(
                          children: [
                            Expanded(
                              child: _buildModeCard(
                                game: game,
                                mode: GameModeType.arcade,
                                icon: Icons.bolt_rounded,
                                title: 'ARCADE',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildModeCard(
                                game: game,
                                mode: GameModeType.puzzle,
                                icon: Icons.grid_on_rounded,
                                title: 'JENGA',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Big PLAY Button
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: FarmTheme.goldenStraw,
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                              side: const BorderSide(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            elevation: 10,
                            shadowColor:
                                FarmTheme.goldenStraw.withValues(alpha: 0.65),
                          ),
                          onPressed: () => _startGame(context, game),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.play_arrow_rounded, size: 28),
                              SizedBox(width: 6),
                              Text(
                                'PLAY GAME',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }

  Widget _buildModeCard({
    required GameController game,
    required GameModeType mode,
    required IconData icon,
    required String title,
  }) {
    final bool isSelected = game.gameMode == mode;
    return GestureDetector(
      onTap: () {
        AudioHapticsService.triggerCatchHaptic();
        game.switchMode(mode);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? FarmTheme.uiPillBg
              : Colors.black.withValues(alpha: 0.48),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? FarmTheme.sunWarmYellow : Colors.white24,
            width: isSelected ? 2.2 : 1.2,
          ),
          boxShadow:
              isSelected ? FarmTheme.buttonGlow(FarmTheme.goldenStraw) : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? FarmTheme.sunWarmYellow : Colors.white60,
              size: 20,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? FarmTheme.sunWarmYellow : Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
