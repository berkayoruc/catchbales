import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';
import '../models/bale.dart';
import '../models/game_mode.dart';
import '../models/stack_slot.dart';

/// Dynamic wave events altering spawn rhythms and atmospheric behaviors.
enum WaveEventType {
  normal,
  frenzy,
  animalStampede,
  crosswind,
}

/// Handles spawning and 3D ballistic trajectory generation of straw bales
/// emerging from the baler chute toward the 3x3x5 rear wagon grid.
/// Coordinates are synchronized with the -55° Pitch, 45° FOV 3D Camera.
class BaleSpawner {
  final math.Random _random = math.Random();

  // 3D World space coordinates synchronized with Rive 3D Camera (-55° pitch):
  // Baler ejection pipe origin (front-center elevated)
  static final Vector3 balerChuteOrigin = Vector3(0.0, 3.2, 5.0);

  // Wagon 3D interior boundaries for 3x3x5 grid:
  // X: -1.35 (left wooden wall) to +1.35 (right wooden wall) -> 3 columns
  // Y: 0.60 (elevated wooden wagon floor above Y=0 dirt road) -> 5 tiers high
  // Z: -3.20 (rear tailgate) to -1.10 (front wagon bulkhead) -> 3 depth rows
  static const double wagonMinX = -1.35;
  static const double wagonMaxX = 1.35;
  static const double wagonFloorY = 0.6;
  static const double wagonWallHeight = 0.72;
  static const double wagonMinZ = -3.2;
  static const double wagonMaxZ = -1.1;
  static const double playerCatchZ = -2.08;

  // Spawning timer state
  double _timeSinceLastSpawn = 0.0;
  double _currentSpawnInterval = 2.2; // seconds
  int _baleCounter = 0;
  ThrownObjectType _nextUpcomingType = ThrownObjectType.bale;
  WaveEventType _activeWave = WaveEventType.normal;
  double _windStrength = 0.0;

  static const List<ThrownObjectType> animalTypes = [
    ThrownObjectType.chicken,
    ThrownObjectType.rooster,
    ThrownObjectType.duck,
    ThrownObjectType.sheep,
    ThrownObjectType.cow,
    ThrownObjectType.cat,
    ThrownObjectType.dog,
    ThrownObjectType.bird,
  ];

  double get currentSpawnInterval => _currentSpawnInterval;
  ThrownObjectType get nextUpcomingType => _nextUpcomingType;
  WaveEventType get activeWave => _activeWave;
  double get windStrength => _windStrength;

  void setWaveEvent(WaveEventType wave, {double wind = 0.0}) {
    _activeWave = wave;
    _windStrength = wind;
  }

  void _pickNextUpcomingType({GameModeType mode = GameModeType.arcade}) {
    if (_baleCounter == 0) {
      _nextUpcomingType = ThrownObjectType.bale;
      return;
    }

    if (_activeWave == WaveEventType.frenzy) {
      // Frenzy wave: 80% normal bales, 20% golden bales, NO animals or hazards!
      _nextUpcomingType = _random.nextDouble() < 0.20
          ? ThrownObjectType.goldenBale
          : ThrownObjectType.bale;
      return;
    }

    if (_activeWave == WaveEventType.animalStampede) {
      // Animal stampede: 75% animals, 25% golden bales!
      _nextUpcomingType = _random.nextDouble() < 0.25
          ? ThrownObjectType.goldenBale
          : animalTypes[_random.nextInt(animalTypes.length)];
      return;
    }

    if (mode == GameModeType.puzzle) {
      // Puzzle mode: 75% bales, 25% animals
      _nextUpcomingType = _random.nextDouble() < 0.25
          ? animalTypes[_random.nextInt(animalTypes.length)]
          : ThrownObjectType.bale;
      return;
    }

    // Arcade mode: diverse rich variety of special bales and power-ups
    final double roll = _random.nextDouble();
    if (roll < 0.12) {
      _nextUpcomingType = ThrownObjectType.burningBale;
    } else if (roll < 0.20) {
      _nextUpcomingType = ThrownObjectType.goldenBale;
    } else if (roll < 0.24) {
      _nextUpcomingType = ThrownObjectType.magnetPowerUp;
    } else if (roll < 0.28) {
      _nextUpcomingType = ThrownObjectType.slowMoPowerUp;
    } else if (roll < 0.52) {
      _nextUpcomingType = animalTypes[_random.nextInt(animalTypes.length)];
    } else {
      _nextUpcomingType = ThrownObjectType.bale;
    }
  }

  /// Resets spawner state for a fresh game round.
  void reset(GameModeType mode) {
    _timeSinceLastSpawn = 0.0;
    _baleCounter = 0;
    _activeWave = WaveEventType.normal;
    _windStrength = 0.0;
    _currentSpawnInterval = mode == GameModeType.arcade ? 2.6 : 3.0;
    _pickNextUpcomingType(mode: mode);
  }

  /// Updates spawn timer and optionally spawns a new bale if interval elapsed.
  StrawBale? update(
    double dt,
    GameModeType mode,
    int currentScore, {
    List<({int col, int row})>? availableCells,
  }) {
    _timeSinceLastSpawn += dt;

    // Dynamically adjust spawn interval based on score in Arcade mode
    if (mode == GameModeType.arcade) {
      // Gradually decrease interval from 2.6s down to 1.3s as score rises
      final difficultyFactor = (currentScore / 1800.0).clamp(0.0, 1.0);
      double interval = 2.6 - (difficultyFactor * 1.3);
      if (_activeWave == WaveEventType.frenzy) {
        interval *= 0.55; // 2x faster storm of bales in Frenzy!
      }
      _currentSpawnInterval = interval;
    } else {
      // In Puzzle mode, keep a consistent paced rhythm
      _currentSpawnInterval = 3.0;
    }

    if (_timeSinceLastSpawn >= _currentSpawnInterval) {
      _timeSinceLastSpawn = 0.0;
      return _generateBale(availableCells: availableCells);
    }

    return null;
  }

  /// Calculates a randomized 3D trajectory from the baler pipe into one of the
  /// 3x3 cells of the wagon bed, with slight organic variance.
  /// Randomly spawns either a straw bale (~70%) or one of the 8 farm animals (~30%).
  StrawBale _generateBale({
    ThrownObjectType? forcedType,
    List<({int col, int row})>? availableCells,
  }) {
    _baleCounter++;

    final ThrownObjectType chosenType = forcedType ?? _nextUpcomingType;
    _pickNextUpcomingType();

    // Pick target cell in the 3x3 wagon grid:
    // If availableCells (< 5 rows) are provided, 85% prioritize an available cell
    // so the wagon can be completed without impossible-to-catch traps!
    final int targetCol;
    final int targetRow;
    if (availableCells != null &&
        availableCells.isNotEmpty &&
        _random.nextDouble() < 0.85) {
      final pick = availableCells[_random.nextInt(availableCells.length)];
      targetCol = pick.col;
      targetRow = pick.row;
    } else {
      targetCol = _random.nextInt(3);
      targetRow = _random.nextInt(3);
    }

    final double baseX = StackedBale.worldXForColumn(targetCol);
    final double baseZ = StackedBale.worldZForRow(targetRow);

    final double targetX =
        (baseX + (_random.nextDouble() - 0.5) * 0.32).clamp(wagonMinX, wagonMaxX);
    final double targetZ =
        (baseZ + (_random.nextDouble() - 0.5) * 0.28).clamp(wagonMinZ, wagonMaxZ);

    final Vector3 targetPos = Vector3(targetX, wagonFloorY, targetZ);

    // Random arc height (elevation peak of the parabolic toss in 3D Y space)
    final double arcHeight = 2.3 + _random.nextDouble() * 1.35;

    // Flight duration (1.45 to 1.85 seconds so player can move across 3x3 grid)
    final double flightDuration = 1.45 + _random.nextDouble() * 0.40;

    // Random angular torque (tumble around X, Y, Z axes)
    final Vector3 angularVelocity = Vector3(
      (_random.nextDouble() - 0.5) * 6.0,
      (_random.nextDouble() - 0.5) * 4.0,
      (_random.nextDouble() - 0.5) * 5.0,
    );

    // Slight straw hue variation for cozy low-poly look
    final double hueVariation = (_random.nextDouble() - 0.5) * 0.15;

    final bale = StrawBale(
      id: 'bale_$_baleCounter',
      objectType: chosenType,
      startPos: balerChuteOrigin.clone(),
      targetPos: targetPos,
      arcHeight: arcHeight,
      flightDuration: flightDuration,
      angularVelocity: angularVelocity,
      colorHueVariation: hueVariation,
    );
    bale.gridCol = targetCol;
    bale.gridRow = targetRow;
    bale.windDriftX = _windStrength;
    return bale;
  }

  /// Spawns a specific [ThrownObjectType] (used for deterministic testing or special events).
  StrawBale spawnWithType(ThrownObjectType type) =>
      _generateBale(forcedType: type);
}
