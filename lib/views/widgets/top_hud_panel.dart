import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/game_controller.dart';
import '../../models/bale.dart';
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
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ROW 1: Score & Capacity | Total Filled Wagons | Hearts | Pause
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 1. Score + Wagon Capacity Pill (tap to organize)
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
                              horizontal: 10,
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
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${game.score}',
                                  style: const TextStyle(
                                    color: FarmTheme.uiTextGold,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Container(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  width: 1.2,
                                  height: 12,
                                  color: Colors.white24,
                                ),
                                const Icon(
                                  Icons.view_in_ar_rounded,
                                  color: FarmTheme.goldenStraw,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${game.stackedBales.length}/${GameController.maxWagonCapacity}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                if (game.comboMultiplier > 1) ...[
                                  const SizedBox(width: 5),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: FarmTheme.comboOrange,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${game.comboMultiplier}x',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9.5,
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
                    const SizedBox(width: 6),

                    // 2. Prominent Total Filled Wagons Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: FarmTheme.uiPillBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: game.wagonsCompleted > 0
                              ? FarmTheme.sunWarmYellow
                              : FarmTheme.uiPillBorder,
                          width: 1.5,
                        ),
                        boxShadow: FarmTheme.cozyShadow,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🚛', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          Text(
                            '${game.wagonsCompleted}',
                            style: TextStyle(
                              color: game.wagonsCompleted > 0
                                  ? FarmTheme.sunWarmYellow
                                  : Colors.white70,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),

                    // 3. Clean Hearts Pill
                    KeyedSubtree(
                      key: healthBarKey,
                      child: _buildCompactHeartsPill(game),
                    ),
                    const SizedBox(width: 6),

                    // 4. Single Pause Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => game.togglePause(),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(7),
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
                            size: 19,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Animated Floating Popup Toast (Only pops up when incoming object or organize warning, then slides away!)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.0, -0.6),
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
                  child: game.showIncomingPopup
                      ? _buildIncomingPopup(game)
                      : (game.showOrganizeAlert
                          ? _buildOrganizePopup(game)
                          : const SizedBox.shrink()),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIncomingPopup(GameController game) {
    final type = game.popupIncomingType ?? ThrownObjectType.bale;
    final bool isAnimal = type.isAnimal;

    return Container(
      key: ValueKey('incoming_${type.name}'),
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: isAnimal
            ? FarmTheme.comboOrange.withValues(alpha: 0.95)
            : FarmTheme.uiPillBg.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAnimal ? Colors.white : FarmTheme.sunWarmYellow,
          width: 1.6,
        ),
        boxShadow: [
          BoxShadow(
            color: (isAnimal ? FarmTheme.comboOrange : FarmTheme.sunWarmYellow)
                .withValues(alpha: 0.55),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            type.emoji,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 6),
          Text(
            isAnimal
                ? '⚠️ ${type.displayNameEn.toUpperCase()} INCOMING!'
                : '${type.displayNameEn.toUpperCase()} INCOMING!',
            style: TextStyle(
              color: isAnimal ? Colors.white : FarmTheme.sunWarmYellow,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          if (isAnimal) ...[
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'STUN RISK',
                style: TextStyle(
                  color: Colors.yellowAccent,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrganizePopup(GameController game) {
    return GestureDetector(
      key: ValueKey('organize_alert_${game.organizeAlertRemaining}'),
      onTap: () => game.startOrganizeCutscene(),
      child: Container(
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: FarmTheme.sunWarmYellow.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white,
            width: 1.6,
          ),
          boxShadow: [
            BoxShadow(
              color: FarmTheme.sunWarmYellow.withValues(alpha: 0.65),
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.bolt_rounded,
              color: Colors.black87,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              '⚡ ORGANIZE SOON! (${game.organizeAlertRemaining} Left)',
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
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
