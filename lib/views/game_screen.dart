import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import '../controllers/game_controller.dart';
import '../models/bale.dart';
import '../models/stack_slot.dart';
import '../physics/bale_spawner.dart';
import '../physics/camera_3d.dart';
import '../utils/farm_theme.dart';
import 'widgets/top_hud_panel.dart';
import 'widgets/touch_controls_overlay.dart';
import 'widgets/cutscene_organize_overlay.dart';
import 'widgets/farm_canvas_view.dart';
import 'widgets/rive_layer_view.dart';
import 'widgets/settings_dialog.dart';
import 'widgets/stats_dialog.dart';
import 'widgets/game_over_dialog.dart';
import 'widgets/how_to_play_overlay.dart';
import 'main_menu_screen.dart';

/// Main Mobile 9:16 Game Screen featuring the 3D low-poly farm canvas,
/// Rive state machine layer, top HUD, and bottom touch controls.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  // Showcase target GlobalKeys for pixel-accurate Spotlight cutout alignment
  final GlobalKey _stackKey = GlobalKey();
  final GlobalKey _bottomPadKey = GlobalKey();
  final GlobalKey _organizeButtonKey = GlobalKey();
  final GlobalKey _healthBarKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<GameController>().startTutorialIfFirstTime();
      }
    });
  }

  void _onTick(Duration elapsed) {
    if (_lastElapsed == Duration.zero) {
      _lastElapsed = elapsed;
      return;
    }

    final double dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;

    // Clamp dt to prevent massive jumps when resumed from pause
    final clampedDt = dt.clamp(0.001, 0.05);

    if (mounted) {
      context.read<GameController>().update(clampedDt);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _openSettingsDialog(BuildContext context, GameController game) {
    game.setPaused(true);
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => SettingsDialog(game: game),
    ).then((_) {
      if (mounted && !game.isGameOver) {
        game.setPaused(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();

    // Calculate screen shake offset
    double shakeX = 0.0;
    double shakeY = 0.0;
    if (game.screenShake > 0.0) {
      final double shakeMag = game.screenShake * 10.0;
      final double time = DateTime.now().millisecondsSinceEpoch / 40.0;
      shakeX = math.sin(time) * shakeMag;
      shakeY = math.cos(time * 1.3) * shakeMag;
    }

    return Scaffold(
      backgroundColor: FarmTheme.fieldLushGreen,
      body: SizedBox.expand(
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            color: FarmTheme.fieldLushGreen,
          ),
          child: Transform.translate(
            offset: Offset(shakeX, shakeY),
            child: Stack(
              key: _stackKey,
              fit: StackFit.expand,
              children: [
                  // 1. Primary Low-Poly 3D Isometric Custom Farm Canvas with Full-Screen 2D Touch/Swipe
                  LayoutBuilder(
                    builder: (context, canvasConstraints) {
                      final double w = math.max(1.0, canvasConstraints.maxWidth);
                      final double h = math.max(1.0, canvasConstraints.maxHeight);
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanUpdate: (details) {
                          game.dragPlayer2D(
                            details.delta.dx / w,
                            details.delta.dy / (h * 0.45),
                          );
                        },
                        onTapUp: (details) {
                          if (game.isCutsceneActive) {
                            // Map 2D tap directly to the closest 3x3 cell in the diagonal isometric 3D wagon
                            final cam = Camera3DProjector(
                              config: game.riveBridge.sceneConfig,
                              viewportSize: Size(w, h),
                            );
                            int bestCol = 1;
                            int bestRow = 1;
                            double bestDist = double.infinity;
                            for (int r = 0; r < 3; r++) {
                              for (int c = 0; c < 3; c++) {
                                final proj = cam.project(
                                  Vector3(
                                    StackedBale.worldXForColumn(c),
                                    BaleSpawner.wagonFloorY + 0.25,
                                    StackedBale.worldZForRow(r),
                                  ),
                                );
                                final double d =
                                    (proj.screenOffset - details.localPosition)
                                        .distance;
                                if (d < bestDist) {
                                  bestDist = d;
                                  bestCol = c;
                                  bestRow = r;
                                }
                              }
                            }
                            if (bestDist < w * 0.35) {
                              game.selectOrMoveOrganizeCell(bestCol, bestRow);
                            }
                            return;
                          }

                          final double normX =
                              ((details.localPosition.dx / w) * 2.0 - 1.0)
                                  .clamp(-1.0, 1.0);
                          final int col = normX < -0.33
                              ? 0
                              : (normX > 0.33 ? 2 : 1);

                          // Map vertical tap around wagon area (0.45..0.78 of screen height) to depthRow 0..2
                          final double relY = details.localPosition.dy / h;
                          final int depthRow = relY < 0.56
                              ? 0
                              : (relY > 0.66 ? 2 : 1);

                          game.snapToCell(col, depthRow);
                        },
                        child: FarmCanvasView(game: game),
                      );
                    },
                  ),

                  // 2. Rive State Machine Layer
                  RiveLayerView(game: game),

                  // 2b. Full-Screen Red Vignette & Damage Alert Banner on Health Loss
                  if (game.damageFlash > 0.01)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: game.damageFlash.clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: FarmTheme.heartRed.withValues(alpha: 0.90),
                                width: 6.0 * game.damageFlash,
                              ),
                              gradient: RadialGradient(
                                center: Alignment.center,
                                radius: 0.88,
                                colors: [
                                  Colors.transparent,
                                  FarmTheme.heartRed.withValues(alpha: 0.16),
                                  FarmTheme.heartRed.withValues(alpha: 0.52),
                                ],
                                stops: const [0.45, 0.78, 1.0],
                              ),
                            ),
                            alignment: const Alignment(0.0, -0.58),
                            child: Transform.scale(
                              scale: 0.90 + 0.18 * game.damageFlash,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: FarmTheme.heartRed.withValues(alpha: 0.94),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.8,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.45),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.heart_broken_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '-${game.lastDamageTaken} HP',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // 3. Top HUD Panel Overlay
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: TopHudPanel(
                      onOpenSettings: () => _openSettingsDialog(context, game),
                      healthBarKey: _healthBarKey,
                      organizeButtonKey: _organizeButtonKey,
                    ),
                  ),

                  // 4. Bottom Touch Control Overlay OR 7-Second Cutscene Organize Overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: game.isCutsceneActive
                        ? CutsceneOrganizeOverlay(game: game)
                        : TouchControlsOverlay(
                            bottomPadKey: _bottomPadKey,
                          ),
                  ),

                  // 4b. Non-clickable Incoming Object Banner at Bottom ("Gelen Obje")
                  // Rendered AFTER TouchControlsOverlay with higher z-index, positioned cleanly above the 3x3 touch grid!
                  if (!game.isGameOver && !game.isCutsceneActive)
                    Positioned(
                      bottom: MediaQuery.paddingOf(context).bottom + 106,
                      left: 16,
                      right: 16,
                      child: IgnorePointer(
                        ignoring: true, // Non-clickable so player control is 100% preserved
                        child: Center(
                          child:
                              _buildBottomIncomingObjectBanner(context, game),
                        ),
                      ),
                    ),

                  // 4c. Emergency Hot Potato "THROW AWAY!" Button when holding Burning Bale
                  if (game.isHoldingBurningBale && !game.isGameOver)
                    Positioned(
                      bottom: MediaQuery.paddingOf(context).bottom + 154,
                      left: 20,
                      right: 20,
                      child: _buildThrowBurningBaleButton(game),
                    ),

                  // 5. Interactive How-To-Play Onboarding Overlay (for First-Time Players or Help Button)
                  if (game.isTutorialActive && !game.isGameOver)
                    Positioned.fill(
                      child: HowToPlayOverlay(
                        game: game,
                        ancestorStackKey: _stackKey,
                        bottomPadKey: _bottomPadKey,
                        organizeButtonKey: _organizeButtonKey,
                        healthBarKey: _healthBarKey,
                      ),
                    ),

                  // 6. Pause Overlay (when game is paused)
                  if (game.isPaused && !game.isGameOver)
                    Container(
                      color: Colors.black54,
                      child: Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 28),
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: FarmTheme.uiPillBg,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: FarmTheme.sunWarmYellow,
                              width: 2.2,
                            ),
                            boxShadow: FarmTheme.cozyShadow,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Icon(
                                Icons.pause_circle_filled_rounded,
                                color: FarmTheme.sunWarmYellow,
                                size: 48,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'GAME PAUSED',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Score: ${game.score}  •  Wagon: ${game.stackedBales.length}/${GameController.maxWagonCapacity}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: FarmTheme.uiTextGold,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 18),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: FarmTheme.goldenStraw,
                                  foregroundColor: Colors.black87,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 13,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                onPressed: () => game.setPaused(false),
                                icon: const Icon(Icons.play_arrow_rounded),
                                label: const Text(
                                  'RESUME',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: FarmTheme.uiTextGold,
                                  side: const BorderSide(
                                    color: FarmTheme.uiPillBorder,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) =>
                                        CaughtStatsDialog(game: game),
                                  );
                                },
                                icon: const Icon(
                                  Icons.bar_chart_rounded,
                                  size: 18,
                                ),
                                label: const Text(
                                  'OBJECT STATS',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: FarmTheme.uiTextGold,
                                  side: const BorderSide(
                                    color: FarmTheme.uiPillBorder,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                onPressed: () => game.openTutorial(),
                                icon: const Icon(
                                  Icons.help_outline_rounded,
                                  size: 18,
                                ),
                                label: const Text(
                                  'HOW TO PLAY',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: FarmTheme.sunWarmYellow,
                                  side: const BorderSide(
                                    color: FarmTheme.sunWarmYellow,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                onPressed: () {
                                  game.resetGame();
                                },
                                icon: const Icon(Icons.replay_rounded, size: 18),
                                label: const Text(
                                  'RESTART',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white70,
                                  side: const BorderSide(color: Colors.white30),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                onPressed: () {
                                  game.resetGame();
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => const MainMenuScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.home_rounded, size: 18),
                                label: const Text(
                                  'MAIN MENU',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // 7. Game Over / Level Complete Modal Overlay
                  if (game.isGameOver)
                    Container(
                      color: Colors.black54,
                      child: GameOverDialog(game: game),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
  }

  Widget _buildThrowBurningBaleButton(GameController game) {
    final double ratio =
        (game.burningBaleTimer / GameController.maxBurningHoldDuration)
            .clamp(0.0, 1.0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => game.throwHeldBurningBale(),
        borderRadius: BorderRadius.circular(26),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFF3B30),
                Color(0xFFFF9500),
                Color(0xFFFFCC00),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF3B30).withValues(alpha: 0.75),
                blurRadius: 22,
                spreadRadius: 3,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '🔥 THROW AWAY!',
                    style: TextStyle(
                      fontFamily: FarmTheme.displayFontFamily,
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${game.burningBaleTimer.toStringAsFixed(1)}s',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 6,
                  backgroundColor: Colors.black26,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Non-clickable Incoming Object Banner at Bottom:
  /// Announces in-flight bales / animals / power-ups clearly with emoji and localized text.
  /// 100% click-through (IgnorePointer) so player steering and catches are never obstructed.
  Widget _buildBottomIncomingObjectBanner(
    BuildContext context,
    GameController game,
  ) {
    final type = game.currentIncomingType;
    if (type == null) {
      return const SizedBox.shrink();
    }

    final bool isTr = Localizations.localeOf(context).languageCode == 'tr';
    final bool isAnimal = type.isAnimal;
    final bool isBurning = type == ThrownObjectType.burningBale;
    final bool isGolden = type == ThrownObjectType.goldenBale;
    final bool isPowerUp = type.isPowerUp;

    final Color bgColor;
    final Color borderColor;
    final Color shadowColor;
    final String labelText;
    final String? badgeText;

    if (isBurning) {
      bgColor = const Color(0xFFC62828);
      borderColor = const Color(0xFFFF5722);
      shadowColor = const Color(0xFFFF3D00);
      labelText = isTr ? 'YANMIŞ BALYA GELİYOR!' : 'BURNING BALE INCOMING!';
      badgeText = isTr ? '3s FIRLAT!' : '3s THROW!';
    } else if (isGolden) {
      bgColor = const Color(0xFFF57F17);
      borderColor = const Color(0xFFFFD54F);
      shadowColor = const Color(0xFFFFD700);
      labelText = isTr ? 'ALTIN BALYA GELİYOR!' : 'GOLDEN BALE INCOMING!';
      badgeText = isTr ? '+250 PUAN' : '+250 PTS';
    } else if (isPowerUp) {
      bgColor = const Color(0xFF00695C);
      borderColor = const Color(0xFF80CBC4);
      shadowColor = const Color(0xFF00E5FF);
      labelText = isTr
          ? '${type.displayNameTr.toUpperCase()} GELİYOR!'
          : '${type.displayNameEn.toUpperCase()} INCOMING!';
      badgeText = isTr ? 'GÜÇLENDİRME' : 'POWER-UP';
    } else if (isAnimal) {
      bgColor = const Color(0xFF4E342E);
      borderColor = const Color(0xFFFFB74D);
      shadowColor = const Color(0xFFFF9800);
      labelText = isTr
          ? '${type.displayNameTr.toUpperCase()} GELİYOR!'
          : '${type.displayNameEn.toUpperCase()} INCOMING!';
      badgeText = isTr ? 'SERSEMLETME RİSKİ' : 'STUN RISK';
    } else {
      bgColor = const Color(0xFF1B2834);
      borderColor = FarmTheme.sunWarmYellow;
      shadowColor = const Color(0xFFF4B942).withValues(alpha: 0.35);
      labelText = isTr ? 'SAMAN BALYASI GELİYOR' : 'STRAW BALE INCOMING';
      badgeText = null;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 0.45),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          )),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey('bottom_incoming_${type.name}'),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: borderColor,
            width: 1.8,
          ),
          boxShadow: [
            BoxShadow(
              color: shadowColor.withValues(alpha: 0.60),
              blurRadius: 14,
              spreadRadius: 2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              type.emoji,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(width: 6),
            Text(
              labelText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
            ),
            if (badgeText != null) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: isBurning
                        ? Colors.amberAccent
                        : (isGolden
                            ? Colors.white
                            : (isAnimal
                                ? Colors.yellowAccent
                                : const Color(0xFF80D8FF))),
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
