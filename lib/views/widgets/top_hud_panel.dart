import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/game_controller.dart';
import '../../utils/farm_theme.dart';

/// Minimalist, single-row Top HUD Panel with icon+number pills (no text clutter):
/// 1. Score & Wagon Load Pill (tappable to trigger isometric stack organization)
/// 2. Discrete Hearts Pill (flashes on damage)
/// 3. Pause Icon Button
class TopHudPanel extends StatelessWidget {
  final VoidCallback onOpenSettings;
  final GlobalKey? healthBarKey;
  final GlobalKey? organizeButtonKey;

  const TopHudPanel({
    super.key,
    required this.onOpenSettings,
    this.healthBarKey,
    this.organizeButtonKey,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<GameController>(
      builder: (context, game, child) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 1. Compact Score + Wagon Capacity Pill (tap to organize wagon)
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: game.isCutsceneActive
                          ? null
                          : () => game.startOrganizeCutscene(),
                      child: Container(
                        key: organizeButtonKey,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: FarmTheme.uiPillBg,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: FarmTheme.uiPillBorder,
                            width: 1.5,
                          ),
                          boxShadow: FarmTheme.cozyShadow,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.stars_rounded,
                              color: FarmTheme.sunWarmYellow,
                              size: 17,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${game.score}',
                              style: const TextStyle(
                                color: FarmTheme.uiTextGold,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              width: 1.2,
                              height: 13,
                              color: Colors.white24,
                            ),
                            if (game.wagonsCompleted > 0) ...[
                              const Text('🚛', style: TextStyle(fontSize: 13)),
                              const SizedBox(width: 3),
                              Text(
                                '${game.wagonsCompleted}',
                                style: const TextStyle(
                                  color: FarmTheme.sunWarmYellow,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                width: 1.2,
                                height: 13,
                                color: Colors.white24,
                              ),
                            ],
                            const Icon(
                              Icons.view_in_ar_rounded,
                              color: FarmTheme.goldenStraw,
                              size: 15,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${game.stackedBales.length}/${GameController.maxWagonCapacity}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (game.comboMultiplier > 1) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: FarmTheme.comboOrange,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${game.comboMultiplier}x',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // 2. Clean Hearts Pill (no text labels)
                KeyedSubtree(
                  key: healthBarKey,
                  child: _buildCompactHeartsPill(game),
                ),
                const SizedBox(width: 8),

                // 3. Single Pause Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => game.togglePause(),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: game.isPaused
                            ? FarmTheme.goldenStraw
                            : FarmTheme.uiPillBg,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: game.isPaused
                              ? Colors.white
                              : FarmTheme.uiPillBorder,
                          width: 1.5,
                        ),
                        boxShadow: FarmTheme.cozyShadow,
                      ),
                      child: Icon(
                        game.isPaused
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded,
                        color: game.isPaused
                            ? Colors.black87
                            : FarmTheme.sunWarmYellow,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactHeartsPill(GameController game) {
    final int lives = game.lives;
    final bool isFlashing = game.damageFlash > 0.05;
    final double flashAlpha = game.damageFlash.clamp(0.0, 1.0);

    final Color pillBg = isFlashing
        ? Color.lerp(
            FarmTheme.uiPillBg,
            FarmTheme.heartRed.withValues(alpha: 0.92),
            flashAlpha * 0.75,
          )!
        : FarmTheme.uiPillBg;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 90),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: pillBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isFlashing ? Colors.white : FarmTheme.uiPillBorder,
          width: isFlashing ? 2.0 : 1.5,
        ),
        boxShadow: isFlashing
            ? [
                BoxShadow(
                  color:
                      FarmTheme.heartRed.withValues(alpha: 0.75 * flashAlpha),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : FarmTheme.cozyShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < 4; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: Icon(
                i < lives
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                size: 16,
                color: i < lives
                    ? (isFlashing ? Colors.white : FarmTheme.heartRed)
                    : Colors.white30,
              ),
            ),
        ],
      ),
    );
  }
}
