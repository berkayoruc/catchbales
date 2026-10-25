import 'package:flutter/material.dart';
import '../../controllers/game_controller.dart';
import '../../utils/farm_theme.dart';

/// 7-Second Interactive Cutscene Overlay allowing the player to freely organize
/// and move stacked bales across the 3x3x5 wagon grid (9 cells, max 5 tiers each).
class CutsceneOrganizeOverlay extends StatelessWidget {
  final GameController game;

  const CutsceneOrganizeOverlay({
    super.key,
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
    final double ratio =
        (game.cutsceneTimer / GameController.cutsceneDuration).clamp(0.0, 1.0);
    final int? selCol = game.selectedOrganizeColumn;
    final int? selRow = game.selectedOrganizeDepthRow;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: FarmTheme.uiPillBg.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: FarmTheme.sunWarmYellow,
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.55),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header & 7s Countdown Timer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.grid_view_rounded,
                            color: FarmTheme.sunWarmYellow,
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'ORGANIZE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: FarmTheme.comboOrange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${game.cutsceneTimer.toStringAsFixed(1)}s',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // 7-Second Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 5,
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        FarmTheme.sunWarmYellow,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 3x3 Interactive Wagon Matrix
                  for (int r = 0; r < 3; r++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5.0),
                      child: Row(
                        children: [
                          for (int c = 0; c < 3; c++) ...[
                            if (c > 0) const SizedBox(width: 6),
                            Expanded(
                              child: _buildCellOrganizer(
                                colIndex: c,
                                rowIndex: r,
                                isSelected: selCol == c && selRow == r,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 6),

                  // Action Buttons: Balance, optional Early Haul, & Done
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: FarmTheme.sunWarmYellow,
                            side: const BorderSide(
                              color: FarmTheme.sunWarmYellow,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => game.autoBalanceStack(),
                          icon: const Icon(Icons.balance_rounded, size: 15),
                          label: const Text(
                            'BALANCE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      if (game.stackedBales.length >= 30) ...[
                        const SizedBox(width: 6),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: FarmTheme.comboOrange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => game.completeWagon(
                              isFullWagonBonus: game.stackedBales.length >=
                                  GameController.maxWagonCapacity,
                            ),
                            icon: const Icon(Icons.local_shipping_rounded,
                                size: 15),
                            label: Text(
                              game.stackedBales.length >=
                                      GameController.maxWagonCapacity
                                  ? 'HAUL (45/45)'
                                  : 'EARLY HAUL',
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 6),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: FarmTheme.grassSoftGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => game.endOrganizeCutscene(),
                          icon: const Icon(Icons.play_arrow_rounded, size: 16),
                          label: const Text(
                            'DONE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCellOrganizer({
    required int colIndex,
    required int rowIndex,
    required bool isSelected,
  }) {
    final int count = game.getCellCount(colIndex, rowIndex);
    final bool isFull = count >= GameController.maxRowsPerColumn;

    return GestureDetector(
      onTap: () => game.selectOrMoveOrganizeCell(colIndex, rowIndex),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? FarmTheme.goldenStraw.withValues(alpha: 0.30)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? FarmTheme.sunWarmYellow
                : isFull
                    ? FarmTheme.heartRed.withValues(alpha: 0.75)
                    : Colors.white24,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$count/5',
              style: TextStyle(
                color: isFull ? FarmTheme.heartRed : FarmTheme.sunWarmYellow,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                for (int t = 0; t < GameController.maxRowsPerColumn; t++)
                  Expanded(
                    child: Container(
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: t < count
                            ? (t == count - 1 && isSelected
                                ? FarmTheme.sunWarmYellow
                                : FarmTheme.goldenStraw)
                            : Colors.white12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
