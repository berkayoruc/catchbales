/// The primary game modes as specified in the game blueprint.
enum GameModeType {
  /// Infinite / high-score runner with auto-grid alignment and ramping speed.
  arcade,

  /// Level-based quota with manual placement and terrain balance wobble (Jenga).
  puzzle,
}

extension GameModeTypeExtension on GameModeType {
  double get riveValue => this == GameModeType.arcade ? 0.0 : 1.0;

  String get displayName {
    switch (this) {
      case GameModeType.arcade:
        return 'Arcade Runner';
      case GameModeType.puzzle:
        return 'Jenga Stacker';
    }
  }

  String get description {
    switch (this) {
      case GameModeType.arcade:
        return 'Endless speed runner! Catch incoming bales and build huge combos!';
      case GameModeType.puzzle:
        return 'Carefully stack bales to meet the quota without tipping over on bumpy roads!';
    }
  }
}
