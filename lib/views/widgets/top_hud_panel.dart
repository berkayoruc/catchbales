import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/game_controller.dart';
import '../../models/harvest_order.dart';
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
                                StreakPopupBadge(
                                  comboCount: game.comboCount,
                                  comboMultiplier: game.comboMultiplier,
                                ),
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

                    // 2b. Time of Day & Multiplier Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: FarmTheme.uiPillBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: game.timeOfDay == AtmosphereTimeOfDay.night
                              ? const Color(0xFF80D8FF)
                              : (game.timeOfDay == AtmosphereTimeOfDay.sunset
                                  ? FarmTheme.comboOrange
                                  : FarmTheme.uiPillBorder),
                          width: 1.5,
                        ),
                        boxShadow: FarmTheme.cozyShadow,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            switch (game.timeOfDay) {
                              AtmosphereTimeOfDay.day => '☀️',
                              AtmosphereTimeOfDay.sunset => '🌅',
                              AtmosphereTimeOfDay.night => '🌙',
                            },
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${game.atmosphereMultiplier}x',
                            style: TextStyle(
                              color: game.timeOfDay == AtmosphereTimeOfDay.night
                                  ? const Color(0xFF80D8FF)
                                  : (game.timeOfDay == AtmosphereTimeOfDay.sunset
                                      ? FarmTheme.comboOrange
                                      : FarmTheme.sunWarmYellow),
                              fontSize: 11,
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

                // ROW 1b: Active Power-Ups & Wave Events Indicator Row (Magnet, Slow-Mo, Frenzy, Wind)
                if (game.isMagnetActive ||
                    game.isSlowMoActive ||
                    game.isFrenzyActive ||
                    game.windStrength.abs() > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 5.0),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      alignment: WrapAlignment.center,
                      children: [
                        if (game.isMagnetActive)
                          _buildStatusPill(
                            '🧲 MAGNET',
                            '${game.magnetTimer.toStringAsFixed(1)}s',
                            const Color(0xFF00E5FF),
                          ),
                        if (game.isSlowMoActive)
                          _buildStatusPill(
                            '⏳ SLOW-MO',
                            '${game.slowMoTimer.toStringAsFixed(1)}s',
                            const Color(0xFF80D8FF),
                          ),
                        if (game.isFrenzyActive)
                          _buildStatusPill(
                            '🌪️ FRENZY',
                            '2x PTS',
                            FarmTheme.comboOrange,
                          ),
                        if (game.windStrength.abs() > 0)
                          _buildStatusPill(
                            '💨 WIND',
                            game.windStrength > 0 ? '>>>' : '<<<',
                            FarmTheme.sunWarmYellow,
                          ),
                      ],
                    ),
                  ),

                // ROW 1c: Active Mini Harvest Order Pill (Arcade Mode)
                if (game.currentHarvestOrder != null)
                  _buildHarvestOrderPill(game.currentHarvestOrder!),

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
                  child: game.showOrganizeAlert
                      ? _buildOrganizePopup(game)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusPill(String title, String value, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: FarmTheme.uiPillBg.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.35),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              color: accent,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHarvestOrderPill(HarvestOrder order) {
    return Container(
      margin: const EdgeInsets.only(top: 5),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: FarmTheme.uiPillBg.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: FarmTheme.sunWarmYellow.withValues(alpha: 0.6),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📋', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 5),
          Text(
            order.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            decoration: BoxDecoration(
              color: FarmTheme.grassSoftGreen.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${order.progress}/${order.target}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '+${order.rewardPoints}',
            style: const TextStyle(
              color: FarmTheme.uiTextGold,
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
            ),
          ),
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

/// Dynamic, non-static Streak/Combo Popup Badge ("steak sayısı aynı yerinde popup mantığında"):
/// - Collapses smoothly when streak < 2
/// - Springs into view in its designated HUD pill slot when streak starts (>= 2)
/// - Triggers a punchy scale-and-glow bounce pop (1.0 -> 1.36 -> 1.0) on every consecutive catch
/// - Clearly displays the active streak count (e.g. "🔥 3 STREAK", "🔥 5 STREAK")
/// - Intensifies gradient & shadow as streak grows into Frenzy
/// - Fades & scales away cleanly when the streak ends or resets
class StreakPopupBadge extends StatefulWidget {
  final int comboCount;
  final int comboMultiplier;

  const StreakPopupBadge({
    super.key,
    required this.comboCount,
    required this.comboMultiplier,
  });

  @override
  State<StreakPopupBadge> createState() => _StreakPopupBadgeState();
}

class _StreakPopupBadgeState extends State<StreakPopupBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _popController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.36)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.36, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 60,
      ),
    ]).animate(_popController);

    if (widget.comboCount >= 2) {
      _popController.forward(from: 0.0);
    }
  }

  @override
  void didUpdateWidget(covariant StreakPopupBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.comboCount != oldWidget.comboCount) {
      if (widget.comboCount > oldWidget.comboCount && widget.comboCount >= 2) {
        _popController.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    _popController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isActive = widget.comboCount >= 2;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: isActive
          ? AnimatedBuilder(
              key: ValueKey('streak_badge_${widget.comboCount}'),
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  alignment: Alignment.center,
                  child: child,
                );
              },
              child: _buildBadgeContent(),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildBadgeContent() {
    final int count = widget.comboCount;
    final int mult = widget.comboMultiplier;

    // Dynamic gradient and shadow progression based on streak intensity
    final List<Color> gradientColors;
    final Color shadowColor;
    if (count >= 10) {
      // Frenzy overdrive: electric magenta to blazing orange
      gradientColors = const [Color(0xFFFF007F), Color(0xFFFF9100)];
      shadowColor = const Color(0xFFFF007F);
    } else if (count >= 5) {
      // Hot streak: fiery red-orange to deep amber
      gradientColors = const [Color(0xFFFF3D00), Color(0xFFFF9100)];
      shadowColor = const Color(0xFFFF3D00);
    } else {
      // Energetic combo starter: vibrant sunny orange
      gradientColors = const [Color(0xFFFF8500), Color(0xFFFFA000)];
      shadowColor = const Color(0xFFFF8500);
    }

    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.65),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '🔥',
            style: TextStyle(fontSize: 11),
          ),
          const SizedBox(width: 3),
          Text(
            '$count STREAK',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
          if (mult > 1) ...[
            const SizedBox(width: 3),
            Text(
              '${mult}x',
              style: const TextStyle(
                color: Color(0xFFFFF176),
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
