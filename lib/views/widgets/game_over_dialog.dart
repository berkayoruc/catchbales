import 'package:flutter/material.dart';
import '../../models/bale.dart';
import '../../models/game_mode.dart';
import '../../controllers/game_controller.dart';
import '../../utils/farm_theme.dart';
import '../main_menu_screen.dart';
import 'stats_dialog.dart';

/// Game Over and 3x3x5 Wagon Full Victory modal dialog.
class GameOverDialog extends StatelessWidget {
  final GameController game;

  const GameOverDialog({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final bool isVictory = game.isVictory;
    final bool isHighScore = game.score >= game.highScore && game.score > 0;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 28),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: FarmTheme.uiPillBg,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: isVictory ? FarmTheme.sunWarmYellow : FarmTheme.uiPillBorder,
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.65),
              blurRadius: 30,
              spreadRadius: 8,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon Badge
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isVictory || isHighScore
                    ? FarmTheme.sunWarmYellow.withValues(alpha: 0.22)
                    : FarmTheme.heartRed.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isVictory
                    ? Icons.workspace_premium_rounded
                    : (isHighScore
                        ? Icons.emoji_events_rounded
                        : Icons.agriculture_rounded),
                color: isVictory || isHighScore
                    ? FarmTheme.sunWarmYellow
                    : FarmTheme.heartRed,
                size: 46,
              ),
            ),
            const SizedBox(height: 12),

            // Title
            Text(
              isVictory
                  ? 'WAGON FULL! (45/45)'
                  : (isHighScore ? 'NEW HIGH SCORE!' : 'GAME OVER'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: FarmTheme.displayFontFamily,
                color: isVictory || isHighScore
                    ? FarmTheme.sunWarmYellow
                    : Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isVictory
                  ? 'All 3x3x5 wagon slots stacked!'
                  : 'Out of lives! Mode: ${game.gameMode.displayName}',
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),

            // Stats Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
                  _buildStatRow(
                    'Final Score',
                    '${game.score}',
                    FarmTheme.uiTextGold,
                  ),
                  const Divider(color: Colors.white12, height: 14),
                  _buildStatRow(
                    'Best Score',
                    '${game.highScore}',
                    Colors.white,
                  ),
                  const Divider(color: Colors.white12, height: 14),
                  _buildStatRow(
                    '3x3x5 Wagon Load',
                    '${game.stackedBales.length}/${GameController.maxWagonCapacity}',
                    FarmTheme.sunWarmYellow,
                  ),
                  const Divider(color: Colors.white12, height: 14),
                  _buildStatRow(
                    'Missed Bales',
                    '${game.missedCount}',
                    FarmTheme.heartRed,
                  ),
                  const Divider(color: Colors.white12, height: 14),
                  _buildStatRow(
                    'Completed Wagons',
                    '${game.wagonsCompleted} (Total: ${game.lifetimeWagonsCompleted})',
                    FarmTheme.sunWarmYellow,
                  ),
                  const Divider(color: Colors.white12, height: 14),
                  _buildStatRow(
                    'Total Objects Caught',
                    '${game.totalObjectsCaughtSession} (Total: ${game.totalObjectsCaughtLifetime})',
                    FarmTheme.grassSoftGreen,
                  ),
                  const Divider(color: Colors.white12, height: 14),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final type in ThrownObjectType.values)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: game.getSessionCaughtCount(type) > 0
                                  ? FarmTheme.sunWarmYellow.withValues(alpha: 0.7)
                                  : Colors.white12,
                            ),
                          ),
                          child: Text(
                            '${type.emoji} ${game.getSessionCaughtCount(type)}',
                            style: TextStyle(
                              color: game.getSessionCaughtCount(type) > 0
                                  ? FarmTheme.sunWarmYellow
                                  : Colors.white54,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Detailed Object Stats Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: FarmTheme.sunWarmYellow,
                  side: const BorderSide(
                    color: FarmTheme.sunWarmYellow,
                    width: 1.5,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => CaughtStatsDialog(game: game),
                  );
                },
                icon: const Icon(Icons.bar_chart_rounded, size: 18),
                label: const Text(
                  'OBJECT STATS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Play Again & Main Menu Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: FarmTheme.goldenStraw,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 6,
                  shadowColor: FarmTheme.goldenStraw.withValues(alpha: 0.5),
                ),
                onPressed: () {
                  game.resetGame();
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.replay_rounded, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      isVictory ? 'NEXT HAUL' : 'PLAY AGAIN',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white38, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
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
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
