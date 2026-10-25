import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/game_controller.dart';
import '../../utils/farm_theme.dart';

/// Centered Bottom 3x3 Wagon Joystick / Touchpad Overlay:
/// Supports smooth 2D thumb sliding (Up/Down/Left/Right) and direct cell tapping.
/// Catching is automatic when the farmer is positioned on the landing cell.
class TouchControlsOverlay extends StatelessWidget {
  final GlobalKey? bottomPadKey;

  const TouchControlsOverlay({
    super.key,
    this.bottomPadKey,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<GameController>(
      builder: (context, game, child) {
        final bool isStunned = game.isStunned;

        return SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double maxWidth = constraints.maxWidth;
              final bool isCompact = maxWidth < 340;
              final double padWidth =
                  math.min(maxWidth * 0.62, 224.0).clamp(160.0, 230.0);

              return Padding(
                padding: const EdgeInsets.only(bottom: 10.0, top: 4.0),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    width: padWidth,
                    child: _build3x3WagonTouchpad(
                      game: game,
                      isDisabled: isStunned,
                      isCompact: isCompact,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// Interactive 3x3 Wagon Joystick Pad centered at the bottom of the screen.
  Widget _build3x3WagonTouchpad({
    required GameController game,
    required bool isDisabled,
    required bool isCompact,
  }) {
    final int activeCol = game.currentPlayerColumn;
    final int activeRow = game.currentPlayerDepthRow;
    final double padHeight = isCompact ? 80.0 : 88.0;

    return LayoutBuilder(
      builder: (context, padConstraints) {
        final double padWidth = padConstraints.maxWidth;

        void updateFromLocalOffset(Offset localPos) {
          if (isDisabled || padWidth <= 0) return;
          final double normX =
              ((localPos.dx / padWidth) * 2.0 - 1.0).clamp(-1.0, 1.0);
          final double normZ =
              (1.0 - (localPos.dy / padHeight) * 2.0).clamp(-1.0, 1.0);
          game.setPlayerDirect2D(normX, normZ);
        }

        return GestureDetector(
          onPanStart: (details) => updateFromLocalOffset(details.localPosition),
          onPanUpdate: (details) =>
              updateFromLocalOffset(details.localPosition),
          child: Container(
            key: bottomPadKey,
            height: padHeight,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDisabled
                  ? Colors.grey.withValues(alpha: 0.25)
                  : FarmTheme.uiPillBg.withValues(alpha: 0.90),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDisabled
                    ? Colors.white24
                    : FarmTheme.sunWarmYellow.withValues(alpha: 0.78),
                width: 1.8,
              ),
              boxShadow: isDisabled ? [] : FarmTheme.cozyShadow,
            ),
            child: Column(
              children: [
                for (int r = 0; r < 3; r++)
                  Expanded(
                    child: Row(
                      children: [
                        for (int c = 0; c < 3; c++)
                          _buildGridCellButton(
                            game: game,
                            colIndex: c,
                            rowIndex: r,
                            isActive:
                                activeCol == c && activeRow == r && !isDisabled,
                            isDisabled: isDisabled,
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridCellButton({
    required GameController game,
    required int colIndex,
    required int rowIndex,
    required bool isActive,
    required bool isDisabled,
  }) {
    final int cellBales = game.getCellCount(colIndex, rowIndex);
    final bool isFull = cellBales >= GameController.maxRowsPerColumn;
    final Color rowColor = FarmTheme.rowColor(rowIndex);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: isDisabled ? null : () => game.snapToCell(colIndex, rowIndex),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          margin: const EdgeInsets.all(2.0),
          decoration: BoxDecoration(
            color: isActive
                ? rowColor.withValues(alpha: 0.88)
                : (isFull
                    ? FarmTheme.heartRed.withValues(alpha: 0.35)
                    : rowColor.withValues(alpha: 0.24)),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: isActive
                  ? Colors.white
                  : (isFull
                      ? FarmTheme.heartRed.withValues(alpha: 0.85)
                      : rowColor.withValues(alpha: 0.45)),
              width: isActive ? 1.5 : 0.8,
            ),
          ),
          child: Center(
            child: cellBales > 0
                ? Text(
                    '$cellBales',
                    style: TextStyle(
                      color: isActive
                          ? Colors.black87
                          : (isFull ? FarmTheme.heartRed : Colors.white),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  )
                : Container(
                    width: isActive ? 7 : 4,
                    height: isActive ? 7 : 4,
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.black87
                          : rowColor.withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
