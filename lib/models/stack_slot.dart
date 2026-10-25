/// Representation of a stacked bale in the 3x3x5 wagon bed grid.
/// - [column]: 0 (Left), 1 (Center), 2 (Right)
/// - [depthRow]: 0 (Front near baler), 1 (Middle), 2 (Back near tailgate)
/// - [tier]: 0 (Floor) to 4 (5th row max)
class StackedBale {
  final int column;
  final int depthRow;
  final int tier;
  final double xOffset;
  final double yOffset;
  final double zOffset;
  double tiltAngle;
  final double colorHueVariation;

  StackedBale({
    required this.column,
    this.depthRow = 1,
    required this.tier,
    required this.xOffset,
    required this.yOffset,
    this.zOffset = -2.08,
    this.tiltAngle = 0.0,
    this.colorHueVariation = 0.0,
  });

  /// World Z coordinate for a given depthRow (0: Front, 1: Middle, 2: Back).
  static double worldZForRow(int depthRow) {
    switch (depthRow.clamp(0, 2)) {
      case 0:
        return -1.28; // Front row (closer to baler)
      case 1:
        return -2.08; // Middle row
      case 2:
      default:
        return -2.88; // Back row (closer to rear tailgate)
    }
  }

  /// World X coordinate for a given column (0: Left, 1: Center, 2: Right).
  static double worldXForColumn(int column) {
    return (column.clamp(0, 2) - 1) * 0.86;
  }
}
