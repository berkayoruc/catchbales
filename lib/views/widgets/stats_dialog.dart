import 'package:flutter/material.dart';
import '../../controllers/game_controller.dart';
import '../../models/bale.dart';
import '../../utils/farm_theme.dart';

/// Displays detailed per-object caught statistics (both current session & persistent lifetime)
/// for straw bales and all 8 farm animals (chicken, rooster, duck, sheep, cow, cat, dog, bird).
class CaughtStatsDialog extends StatelessWidget {
  final GameController game;

  const CaughtStatsDialog({
    super.key,
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380, maxHeight: 540),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: FarmTheme.uiPillBg,
          borderRadius: BorderRadius.circular(26),
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
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bar_chart_rounded,
                      color: FarmTheme.sunWarmYellow,
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'YAKALANAN OBJELER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white70,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Grand Total Summary Banner (All Objects Combined)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: FarmTheme.sunWarmYellow.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: FarmTheme.sunWarmYellow.withValues(alpha: 0.75),
                  width: 1.4,
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    '📦',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    flex: 5,
                    child: Text(
                      'TOPLAM YAKALANAN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${game.totalObjectsCaughtSession}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: FarmTheme.sunWarmYellow,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${game.totalObjectsCaughtLifetime}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: FarmTheme.grassSoftGreen,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),

            // Completed Wagons Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white12,
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    '🚛',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    flex: 5,
                    child: Text(
                      'SEVK EDİLEN RÖMORK',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${game.wagonsCompleted}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: FarmTheme.sunWarmYellow,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${game.lifetimeWagonsCompleted}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: FarmTheme.grassSoftGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Column headers (Objeler | Bu Oyun | Toplam)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(
                      'OBJE / HAYVAN',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'BU OYUN',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: FarmTheme.sunWarmYellow,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'TOPLAM',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: FarmTheme.grassSoftGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Scrollable list of all 9 ThrownObjectTypes
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final type in ThrownObjectType.values)
                      _buildStatRow(type),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Close Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: FarmTheme.goldenStraw,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'TAMAM',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(ThrownObjectType type) {
    final int sessionCount = game.getSessionCaughtCount(type);
    final int lifetimeCount = game.getLifetimeCaughtCount(type);
    final bool isAnimal = type.isAnimal;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: sessionCount > 0
              ? (isAnimal
                  ? FarmTheme.comboOrange.withValues(alpha: 0.65)
                  : FarmTheme.sunWarmYellow.withValues(alpha: 0.65))
              : Colors.white12,
        ),
      ),
      child: Row(
        children: [
          Text(
            type.emoji,
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  type.displayNameTr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  isAnimal ? 'Tutulursa: Kısa Stun' : 'Römorka İstiflenir',
                  style: TextStyle(
                    color: isAnimal ? Colors.orangeAccent : Colors.white54,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '$sessionCount',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: sessionCount > 0
                    ? FarmTheme.sunWarmYellow
                    : Colors.white54,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '$lifetimeCount',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: lifetimeCount > 0
                    ? FarmTheme.grassSoftGreen
                    : Colors.white54,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
