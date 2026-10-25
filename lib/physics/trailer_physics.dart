import 'dart:math' as math;

/// Simulates wagon suspension, bumpiness, tilt angle, and wobble on the dirt road.
class TrailerPhysics {
  final math.Random _random = math.Random();

  double _time = 0.0;
  double _currentWobble = 0.0;
  double _tiltAngle = 0.0; // Radians
  double _targetWobble = 0.0;
  double _bumpTimer = 0.0;

  // Configuration
  double baseRoadSpeed = 1.0;
  bool isRoughTerrain = false;

  double get wobbleIntensity => _currentWobble;
  double get tiltAngle => _tiltAngle;

  void reset() {
    _time = 0.0;
    _currentWobble = 0.0;
    _tiltAngle = 0.0;
    _targetWobble = 0.0;
    _bumpTimer = 0.0;
    isRoughTerrain = false;
  }

  /// Updates wagon physics simulation based on delta time dt.
  void update(double dt, bool isPuzzleMode) {
    _time += dt;
    _bumpTimer += dt;

    // Periodic road bumps (reduced frequency for more stable trailer balance)
    final bumpInterval = isPuzzleMode ? 5.0 : 8.0;
    if (_bumpTimer > bumpInterval) {
      _bumpTimer = 0.0;
      // Chance of hitting a bump in the dirt road (reduced from 65% to 35%)
      if (_random.nextDouble() > 0.65) {
        _targetWobble = (0.35 + _random.nextDouble() * 0.45).clamp(0.0, 1.0);
      }
    }

    // Smoothly decay wobble toward baseline oscillation
    final baselineOscillation = 0.15 * math.sin(_time * 4.5);
    _currentWobble += (_targetWobble - _currentWobble) * (dt * 3.5);
    _targetWobble *= math.max(0.0, 1.0 - (dt * 1.8));

    // Calculate angular tilt of wagon (-0.12 to +0.12 radians)
    _tiltAngle = (_currentWobble * 0.12 * math.sin(_time * 6.0)) +
        (baselineOscillation * 0.03);
  }
}
