import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vector_math/vector_math_64.dart';
import '../models/game_mode.dart';
import '../models/bale.dart';
import '../models/harvest_order.dart';
import '../models/stack_slot.dart';
import '../physics/bale_spawner.dart';
import '../physics/collision_detector.dart';
import '../physics/trailer_physics.dart';
import '../utils/audio_haptics.dart';
import 'rive_game_controller.dart';

/// Atmospheric day/sunset/night cycle progression as wagons are completed.
enum AtmosphereTimeOfDay {
  day,
  sunset,
  night;

  String get displayName => switch (this) {
        AtmosphereTimeOfDay.day => 'Day',
        AtmosphereTimeOfDay.sunset => 'Sunset',
        AtmosphereTimeOfDay.night => 'Night',
      };
}

/// Floating visual text notification model
class FloatingNotice {
  final String text;
  final double x;
  final double y;
  final bool isSpecial;
  final bool isDamage;
  double lifeTime; // 1.0 -> 0.0

  FloatingNotice({
    required this.text,
    required this.x,
    required this.y,
    this.isSpecial = false,
    this.isDamage = false,
    this.lifeTime = 1.0,
  });
}

/// Main Game Controller coordinating the 3x3x5 wagon grid (45 bales capacity),
/// 3D character movement (Left/Right X, Forward/Backward Z, Stack Elevation Y),
/// 7-second stack organization cutscenes, game-over/victory states, and Rive bridge.
class GameController extends ChangeNotifier {
  final math.Random _random = math.Random();

  // Subsystems
  final BaleSpawner spawner = BaleSpawner();
  final CollisionDetector collisionDetector = CollisionDetector();
  final TrailerPhysics trailerPhysics = TrailerPhysics();
  final RiveGameController riveBridge;

  // 3x3x5 Wagon Grid & Cutscene Constants
  static const int gridColumns = 3; // Left (0), Center (1), Right (2)
  static const int gridDepthRows = 3; // Front (0), Middle (1), Back (2)
  static const int maxRowsPerColumn = 5; // Max 5 vertical tiers per (col, row) cell
  static const int maxWagonCapacity =
      gridColumns * gridDepthRows * maxRowsPerColumn; // 3x3x5 = 45 bales
  static const double cutsceneDuration = 7.0; // 7-second organization cutscene
  static const int balesPerAutoCutscene = 15; // Trigger cutscene every 15 caught bales (reduced frequency)

  // Game Mode, Tutorial & Status
  static const String _prefKeyTutorialSeen = 'catchbales_tutorial_seen';
  static bool _globalTutorialSeen = false;

  GameModeType _gameMode = GameModeType.arcade;
  bool _isPlaying = true;
  bool _isPaused = false;
  bool _isGameOver = false;
  bool _isVictory = false;
  bool _hasSeenTutorial = false;
  bool _isTutorialActive = false;
  int _tutorialStep = 0;
  static const int totalTutorialSteps = 3;

  // 7-Second Cutscene (3x3x5 Bale Organization Mode) & Isometric Camera Transition State
  bool _isCutsceneActive = false;
  double _cutsceneTimer = 0.0;
  double _cameraIsoProgress = 0.0; // 0.0 = Normal 3rd-Person, 1.0 = Diagonal Isometric Wagon Focus
  int? _selectedOrganizeColumn;
  int? _selectedOrganizeDepthRow;
  int _balesSinceLastCutscene = 0;

  // Stats
  static const String _prefKeyCaughtPrefix = 'catchbales_caught_';
  static const String _prefKeyWagonsCompleted = 'catchbales_wagons_completed';
  int _score = 0;
  int _highScore = 0;
  double _health = 100.0; // 0.0 -> 100.0
  int _balesCaught = 0;
  int _missedCount = 0;
  int _targetQuota = 45; // Full 3x3x5 wagon (45 bales)
  int _comboCount = 0;
  int _comboMultiplier = 1;
  int _wagonsCompleted = 0;
  int _lifetimeWagonsCompleted = 0;

  // Incoming Object & Organize Warning Popup Timer State
  double _incomingPopupTimer = 0.0;
  ThrownObjectType? _popupIncomingType;
  double _organizeAlertTimer = 0.0;
  int _organizeAlertRemaining = 0;

  // Hot Potato: Holding Burning Bale
  bool _isHoldingBurningBale = false;
  double _burningBaleTimer = 0.0;
  static const double maxBurningHoldDuration = 3.0;

  // Power-Ups and Wave Events
  double _magnetTimer = 0.0;
  double _slowMoTimer = 0.0;
  double _frenzyTimer = 0.0;
  double _animalStampedeTimer = 0.0;
  double _crosswindTimer = 0.0;
  double _crosswindCooldown = 20.0;
  double _windStrength = 0.0;
  WaveEventType _activeWaveEvent = WaveEventType.normal;

  // Clutch & Perfect Catches (Consecutive center/clutch catches trigger free auto-balance at 5)
  int _consecutivePerfects = 0;

  // Mini Harvest Orders
  HarvestOrder? _currentHarvestOrder;
  int _orderCounter = 0;

  // Per-Object Caught Statistics (Session & Persistent Lifetime)
  final Map<ThrownObjectType, int> _sessionCaughtByType = {
    for (final t in ThrownObjectType.values) t: 0,
  };
  final Map<ThrownObjectType, int> _lifetimeCaughtByType = {
    for (final t in ThrownObjectType.values) t: 0,
  };

  // Player Character 3D Position inside the Wagon:
  // X: -1.35 (Left) to +1.35 (Right)
  // Z: -1.10 (Front near baler) to -3.20 (Back near tailgate)
  // Y: Steps up/down dynamically based on stack height at current (col, depthRow) cell!
  double _playerX = 0.0;
  double _playerZ = BaleSpawner.playerCatchZ; // -2.08 (Middle row)
  double? _targetPlayerX;
  double? _targetPlayerZ;
  static const double playerSpeed = 5.4;

  bool _isStunned = false;
  double _stunTimer = 0.0;
  static const double stunDuration = 3.0; // 3-second stun/ragdoll on direct bale impact
  static const double animalCatchStunDuration = 0.95; // Short stun when catching an animal

  // Smart Auto-Catch & Magnetic Catch Buffer
  bool autoCatchEnabled = true;
  double _catchBufferTimer = 0.0;
  static const double catchBufferDuration = 0.65;

  // Special Ability (Stun Break / Quick Recovery)
  double _specialCooldown = 0.0;
  static const double maxSpecialCooldown = 8.0;

  // Visual feedback, damage flash, world scroll & screen shake
  double _screenShake = 0.0;
  double _damageFlash = 0.0;
  int _lastDamageTaken = 0;
  double _worldScrollZ = 0.0;
  double _animTime = 0.0;
  final List<FloatingNotice> _notices = [];

  // Active Entities
  final List<StrawBale> _activeBales = [];
  final List<StackedBale> _stackedBales = [];

  // Continuous 2D movement flags for directional controls
  bool _isHoldingLeft = false;
  bool _isHoldingRight = false;
  bool _isHoldingForward = false; // Up screen (+Z toward baler)
  bool _isHoldingBackward = false; // Down screen (-Z toward tailgate)

  GameController({required this.riveBridge}) {
    _isHoldingBurningBale = false;
    _burningBaleTimer = 0.0;
    _magnetTimer = 0.0;
    _slowMoTimer = 0.0;
    _frenzyTimer = 0.0;
    _animalStampedeTimer = 0.0;
    _crosswindTimer = 0.0;
    _crosswindCooldown = 20.0;
    _windStrength = 0.0;
    _activeWaveEvent = WaveEventType.normal;
    _consecutivePerfects = 0;
    _orderCounter = 0;
    _currentHarvestOrder = _gameMode == GameModeType.arcade
        ? HarvestOrder.generateRandom(_orderCounter)
        : null;

    spawner.reset(_gameMode);
    riveBridge.setGameMode(_gameMode.riveValue);
    riveBridge.setHealth(_health);
    riveBridge.setMoveX(0.0);
    _hasSeenTutorial = _globalTutorialSeen;
    _loadTutorialSeenState();
    _loadPersistentCaughtStats();
  }

  Future<void> _loadTutorialSeenState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_prefKeyTutorialSeen) == true) {
        _hasSeenTutorial = true;
        _globalTutorialSeen = true;
      }
    } catch (_) {}
  }

  Future<void> _persistTutorialSeen() async {
    _hasSeenTutorial = true;
    _globalTutorialSeen = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyTutorialSeen, true);
    } catch (_) {}
  }

  Future<void> _loadPersistentCaughtStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _lifetimeWagonsCompleted = prefs.getInt(_prefKeyWagonsCompleted) ?? 0;
      for (final type in ThrownObjectType.values) {
        final int saved = prefs.getInt('$_prefKeyCaughtPrefix${type.name}') ?? 0;
        if (saved > (_lifetimeCaughtByType[type] ?? 0)) {
          _lifetimeCaughtByType[type] = saved;
        }
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _persistWagonsCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefKeyWagonsCompleted, _lifetimeWagonsCompleted);
    } catch (_) {}
  }

  void _recordObjectCaught(ThrownObjectType type) {
    _sessionCaughtByType[type] = (_sessionCaughtByType[type] ?? 0) + 1;
    final int newLifetime = (_lifetimeCaughtByType[type] ?? 0) + 1;
    _lifetimeCaughtByType[type] = newLifetime;
    _persistObjectStat(type, newLifetime, totalObjectsCaughtLifetime);
  }

  Future<void> _persistObjectStat(
    ThrownObjectType type,
    int count,
    int grandTotal,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('$_prefKeyCaughtPrefix${type.name}', count);
      await prefs.setInt('${_prefKeyCaughtPrefix}total', grandTotal);
    } catch (_) {}
  }

  // Getters
  GameModeType get gameMode => _gameMode;
  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;
  bool get isGameOver => _isGameOver;
  bool get isVictory => _isVictory;
  bool get hasSeenTutorial => _hasSeenTutorial;
  bool get isTutorialActive => _isTutorialActive;
  int get tutorialStep => _tutorialStep;
  bool get isCutsceneActive => _isCutsceneActive;
  double get cutsceneTimer => _cutsceneTimer;
  double get cameraIsoProgress => _cameraIsoProgress;

  /// Smooth S-curve (3t^2 - 2t^3) for diagonal isometric camera transition (0.0 -> 1.0).
  double get cameraIsoCurved {
    final double t = _cameraIsoProgress.clamp(0.0, 1.0);
    return t * t * (3.0 - 2.0 * t);
  }
  int? get selectedOrganizeColumn => _selectedOrganizeColumn;
  int? get selectedOrganizeDepthRow => _selectedOrganizeDepthRow;
  int get score => _score;
  int get highScore => _highScore;
  double get health => _health;
  int get lives => (_health / 25.0).ceil().clamp(0, 4);
  int get balesCaught => _balesCaught;
  int get missedCount => _missedCount;
  int get targetQuota => _targetQuota;
  int get comboCount => _comboCount;
  int get comboMultiplier => _comboMultiplier;
  int get wagonsCompleted => _wagonsCompleted;
  int get lifetimeWagonsCompleted => _lifetimeWagonsCompleted;

  /// Returns the actively in-flight incoming bale (closest to landing), or null if none.
  StrawBale? get currentIncomingBale {
    final inFlight =
        _activeBales.where((b) => b.state == BaleState.inFlight).toList();
    if (inFlight.isEmpty) return null;
    inFlight.sort((a, b) => b.progress.compareTo(a.progress));
    return inFlight.first;
  }

  /// Returns the current incoming object type (either in-flight or next to be thrown).
  ThrownObjectType get incomingObjectType =>
      currentIncomingBale?.objectType ?? spawner.nextUpcomingType;

  /// Atmospheric Day / Sunset / Night time-of-day progression.
  AtmosphereTimeOfDay get timeOfDay {
    if (_wagonsCompleted < 2) return AtmosphereTimeOfDay.day;
    if (_wagonsCompleted < 4) return AtmosphereTimeOfDay.sunset;
    return AtmosphereTimeOfDay.night;
  }

  double get atmosphereMultiplier => switch (timeOfDay) {
        AtmosphereTimeOfDay.day => 1.0,
        AtmosphereTimeOfDay.sunset => 1.25,
        AtmosphereTimeOfDay.night => 1.50,
      };

  // Hot Potato: Holding Burning Bale
  bool get isHoldingBurningBale => _isHoldingBurningBale;
  double get burningBaleTimer => _burningBaleTimer;

  // Power-Ups and Wave Events
  bool get isMagnetActive => _magnetTimer > 0.0;
  double get magnetTimer => _magnetTimer;
  bool get isSlowMoActive => _slowMoTimer > 0.0;
  double get slowMoTimer => _slowMoTimer;
  bool get isFrenzyActive => _activeWaveEvent == WaveEventType.frenzy;
  WaveEventType get activeWaveEvent => _activeWaveEvent;
  double get windStrength => _windStrength;

  // Mini Harvest Orders
  HarvestOrder? get currentHarvestOrder => _currentHarvestOrder;

  /// Number of bales caught since the last organize cutscene.
  int get balesSinceLastCutscene => _balesSinceLastCutscene;

  /// Number of bales remaining until the next automatic 7s organize cutscene.
  int get balesUntilOrganizeCutscene =>
      math.max(0, balesPerAutoCutscene - _balesSinceLastCutscene);

  /// True when organize mode is approaching (within 3 bales) and wagon has bales.
  bool get isOrganizeApproaching =>
      balesUntilOrganizeCutscene <= 3 && _stackedBales.isNotEmpty;
  /// True when an incoming object popup banner is actively displaying (pops up for ~1.8s then disappears).
  bool get showIncomingPopup =>
      _incomingPopupTimer > 0.0 && _popupIncomingType != null;
  ThrownObjectType? get popupIncomingType => _popupIncomingType;
  double get incomingPopupTimer => _incomingPopupTimer;

  /// Type of the object currently incoming towards the wagon (in-flight or newly ejected).
  ThrownObjectType? get currentIncomingType {
    for (final bale in _activeBales) {
      if (bale.state == BaleState.inFlight) {
        return bale.objectType;
      }
    }
    if (_incomingPopupTimer > 0.0) {
      return _popupIncomingType;
    }
    return null;
  }

  /// True when organize countdown alert is displaying (pops up briefly then disappears).
  bool get showOrganizeAlert => _organizeAlertTimer > 0.0;
  int get organizeAlertRemaining => _organizeAlertRemaining;

  Map<ThrownObjectType, int> get sessionCaughtStats =>
      Map.unmodifiable(_sessionCaughtByType);
  Map<ThrownObjectType, int> get lifetimeCaughtStats =>
      Map.unmodifiable(_lifetimeCaughtByType);

  int getSessionCaughtCount(ThrownObjectType type) =>
      _sessionCaughtByType[type] ?? 0;
  int getLifetimeCaughtCount(ThrownObjectType type) =>
      _lifetimeCaughtByType[type] ?? 0;

  int get totalAnimalsCaughtSession => ThrownObjectType.values
      .where((t) => t.isAnimal)
      .fold(0, (sum, t) => sum + (_sessionCaughtByType[t] ?? 0));

  int get totalAnimalsCaughtLifetime => ThrownObjectType.values
      .where((t) => t.isAnimal)
      .fold(0, (sum, t) => sum + (_lifetimeCaughtByType[t] ?? 0));

  int get totalObjectsCaughtSession => ThrownObjectType.values
      .fold(0, (sum, t) => sum + (_sessionCaughtByType[t] ?? 0));

  int get totalObjectsCaughtLifetime => ThrownObjectType.values
      .fold(0, (sum, t) => sum + (_lifetimeCaughtByType[t] ?? 0));
  double get playerX => _playerX;
  double get playerZ => _playerZ;

  /// Dynamic vertical elevation Y of the farmer (steps up onto stacked bales at current cell!).
  double get playerY {
    final int tiersUnderFeet =
        getCellCount(currentPlayerColumn, currentPlayerDepthRow);
    // Farmer stands on the wagon floor or climbs atop the bales in their cell (up to 4 tiers)
    return BaleSpawner.wagonFloorY + math.min(tiersUnderFeet, 4) * 0.34;
  }

  double get normalizedPlayerX =>
      (_playerX / BaleSpawner.wagonMaxX).clamp(-1.0, 1.0);

  /// Normalized Z position (-1.0 = Back tailgate, +1.0 = Front bulkhead)
  double get normalizedPlayerZ {
    const double midZ = (BaleSpawner.wagonMaxZ + BaleSpawner.wagonMinZ) * 0.5;
    const double halfSpanZ =
        (BaleSpawner.wagonMaxZ - BaleSpawner.wagonMinZ) * 0.5;
    return ((_playerZ - midZ) / halfSpanZ).clamp(-1.0, 1.0);
  }

  int get currentPlayerColumn {
    if (_playerX < -0.45) return 0;
    if (_playerX > 0.45) return 2;
    return 1;
  }

  int get currentPlayerDepthRow {
    if (_playerZ > -1.68) return 0; // Front row (ÖN)
    if (_playerZ < -2.48) return 2; // Back row (ARKA)
    return 1; // Middle row (ORTA)
  }

  bool get isCatchMagnetActive => _catchBufferTimer > 0.0;
  bool get isStunned => _isStunned;
  double get stunTimer => _stunTimer;
  double get specialCooldown => _specialCooldown;
  double get screenShake => _screenShake;
  double get damageFlash => _damageFlash;
  int get lastDamageTaken => _lastDamageTaken;
  double get worldScrollZ => _worldScrollZ;
  double get animTime => _animTime;
  List<StrawBale> get activeBales => List.unmodifiable(_activeBales);
  List<StackedBale> get stackedBales => List.unmodifiable(_stackedBales);
  List<FloatingNotice> get notices => List.unmodifiable(_notices);
  double get wagonTilt => trailerPhysics.tiltAngle;
  double get wagonWobble => trailerPhysics.wobbleIntensity;

  /// Returns the number of stacked bales (0..5) in a specific 3x3 cell `(column, depthRow)`.
  int getCellCount(int column, int depthRow) {
    return _stackedBales
        .where((b) => b.column == column && b.depthRow == depthRow)
        .length;
  }

  /// Returns the number of stacked bales in [column] at the player's current depth row.
  int getColumnCount(int column) {
    return getCellCount(column, currentPlayerDepthRow);
  }

  // ===========================================================================
  // 2D / 3D PLAYER MOVEMENT CONTROLS (LEFT/RIGHT X, FORWARD/BACKWARD Z)
  // ===========================================================================

  void startMovingLeft() {
    _targetPlayerX = null;
    _isHoldingLeft = true;
  }

  void stopMovingLeft() => _isHoldingLeft = false;

  void startMovingRight() {
    _targetPlayerX = null;
    _isHoldingRight = true;
  }

  void stopMovingRight() => _isHoldingRight = false;

  void startMovingForward() {
    _targetPlayerZ = null;
    _isHoldingForward = true;
  }

  void stopMovingForward() => _isHoldingForward = false;

  void startMovingBackward() {
    _targetPlayerZ = null;
    _isHoldingBackward = true;
  }

  void stopMovingBackward() => _isHoldingBackward = false;

  /// Smoothly glides the farmer to any cell `(col, depthRow)` in the 3x3 wagon grid!
  void snapToCell(int col, int depthRow) {
    if (_isStunned || _isGameOver || _isPaused || _isCutsceneActive) return;
    _targetPlayerX = StackedBale.worldXForColumn(col.clamp(0, 2));
    _targetPlayerZ = StackedBale.worldZForRow(depthRow.clamp(0, 2));
    AudioHapticsService.triggerCatchHaptic();
    notifyListeners();
  }

  /// Smoothly glides the farmer to the specified wagon column (0: Left, 1: Center, 2: Right).
  void snapToColumn(int col) {
    snapToCell(col, currentPlayerDepthRow);
  }

  /// Moves the farmer in 2D (X and Z) via finger drag delta on screen or joystick.
  void dragPlayer2D(double deltaNormX, double deltaNormZ) {
    if (_isStunned || _isGameOver || _isPaused || _isCutsceneActive) return;
    _targetPlayerX = null;
    _targetPlayerZ = null;

    _playerX = (_playerX + deltaNormX * BaleSpawner.wagonMaxX * 2.2)
        .clamp(BaleSpawner.wagonMinX, BaleSpawner.wagonMaxX);

    // Dragging finger UP on screen (negative dy) moves farmer FORWARD (+Z toward baler)
    final double zSpan = BaleSpawner.wagonMaxZ - BaleSpawner.wagonMinZ;
    _playerZ = (_playerZ - deltaNormZ * zSpan * 1.8)
        .clamp(BaleSpawner.wagonMinZ, BaleSpawner.wagonMaxZ);

    riveBridge.setMoveX(normalizedPlayerX);
    notifyListeners();
  }

  void dragPlayerByNormalizedDelta(double deltaNorm) {
    dragPlayer2D(deltaNorm, 0.0);
  }

  void setPlayerDirectX(double normalizedVal) {
    if (_isStunned || _isGameOver || _isPaused || _isCutsceneActive) return;
    _targetPlayerX = null;
    _playerX = (normalizedVal * BaleSpawner.wagonMaxX)
        .clamp(BaleSpawner.wagonMinX, BaleSpawner.wagonMaxX);
    riveBridge.setMoveX(normalizedPlayerX);
    notifyListeners();
  }

  void setPlayerDirect2D(double normX, double normZ) {
    if (_isStunned || _isGameOver || _isPaused || _isCutsceneActive) return;
    _targetPlayerX = null;
    _targetPlayerZ = null;
    _playerX = (normX.clamp(-1.0, 1.0) * BaleSpawner.wagonMaxX)
        .clamp(BaleSpawner.wagonMinX, BaleSpawner.wagonMaxX);

    const double midZ = (BaleSpawner.wagonMaxZ + BaleSpawner.wagonMinZ) * 0.5;
    const double halfSpanZ =
        (BaleSpawner.wagonMaxZ - BaleSpawner.wagonMinZ) * 0.5;
    _playerZ = (midZ + normZ.clamp(-1.0, 1.0) * halfSpanZ)
        .clamp(BaleSpawner.wagonMinZ, BaleSpawner.wagonMaxZ);

    riveBridge.setMoveX(normalizedPlayerX);
    notifyListeners();
  }

  @visibleForTesting
  void setPlayerPositionForTesting(double x, double z) {
    _playerX = x;
    _playerZ = z;
    _targetPlayerX = null;
    _targetPlayerZ = null;
  }

  @visibleForTesting
  void addActiveBaleForTesting(StrawBale bale) {
    _activeBales.add(bale);
  }

  void setTargetQuota(int quota) {
    _targetQuota = quota;
    notifyListeners();
  }

  void switchMode(GameModeType newMode) {
    _gameMode = newMode;
    _isHoldingBurningBale = false;
    _burningBaleTimer = 0.0;
    _magnetTimer = 0.0;
    _slowMoTimer = 0.0;
    _frenzyTimer = 0.0;
    _animalStampedeTimer = 0.0;
    _crosswindTimer = 0.0;
    _crosswindCooldown = 20.0;
    _windStrength = 0.0;
    _activeWaveEvent = WaveEventType.normal;
    _consecutivePerfects = 0;
    _orderCounter = 0;
    _currentHarvestOrder = _gameMode == GameModeType.arcade
        ? HarvestOrder.generateRandom(_orderCounter)
        : null;

    spawner.reset(_gameMode);
    riveBridge.setGameMode(_gameMode.riveValue);
    resetGame();
  }

  void togglePause() {
    if (_isGameOver) return;
    _isPaused = !_isPaused;
    _isHoldingLeft = false;
    _isHoldingRight = false;
    _isHoldingForward = false;
    _isHoldingBackward = false;
    notifyListeners();
  }

  void setPaused(bool paused) {
    if (_isGameOver) return;
    if (_isPaused == paused) return;
    _isPaused = paused;
    if (_isPaused) {
      _isHoldingLeft = false;
      _isHoldingRight = false;
      _isHoldingForward = false;
      _isHoldingBackward = false;
    }
    notifyListeners();
  }

  /// Automatically opens the 4-step How-To-Play onboarding flow ONLY ONCE on the player's very first game.
  void startTutorialIfFirstTime() {
    if (!_hasSeenTutorial && !_globalTutorialSeen && !_isTutorialActive) {
      _isTutorialActive = true;
      _tutorialStep = 0;
      _hasSeenTutorial = true; // Mark as seen immediately so it NEVER auto-pops again
      _globalTutorialSeen = true;
      _persistTutorialSeen();
      _activeBales.clear();
      notifyListeners();
    }
  }

  /// Manually opens the 4-step How-To-Play flow anytime from the HUD or Pause menu.
  void openTutorial() {
    _isPaused = false;
    _isTutorialActive = true;
    _tutorialStep = 0;
    _hasSeenTutorial = true;
    _globalTutorialSeen = true;
    _persistTutorialSeen();
    _isHoldingLeft = false;
    _isHoldingRight = false;
    _isHoldingForward = false;
    _isHoldingBackward = false;
    AudioHapticsService.triggerCatchHaptic();
    notifyListeners();
  }

  void nextTutorialStep() {
    if (!_isTutorialActive) return;
    AudioHapticsService.triggerCatchHaptic();
    if (_tutorialStep < totalTutorialSteps - 1) {
      _tutorialStep++;
      notifyListeners();
    } else {
      completeTutorial();
    }
  }

  void previousTutorialStep() {
    if (!_isTutorialActive || _tutorialStep <= 0) return;
    AudioHapticsService.triggerCatchHaptic();
    _tutorialStep--;
    notifyListeners();
  }

  void completeTutorial() {
    _isTutorialActive = false;
    _hasSeenTutorial = true;
    _globalTutorialSeen = true;
    _persistTutorialSeen();
    _tutorialStep = 0;
    AudioHapticsService.triggerSpecialHaptic();
    _addFloatingNotice('LET\'S GO! CATCH BALES!', 0.0, -0.25, true);
    notifyListeners();
  }

  /// Helper to reset tutorial state for test environments.
  @visibleForTesting
  static void resetTutorialStateForTesting() {
    _globalTutorialSeen = false;
  }

  void resetGame() {
    _score = 0;
    _health = 100.0;
    _balesCaught = 0;
    _missedCount = 0;
    _comboCount = 0;
    _comboMultiplier = 1;
    _wagonsCompleted = 0;
    for (final t in ThrownObjectType.values) {
      _sessionCaughtByType[t] = 0;
    }
    _playerX = 0.0;
    _playerZ = BaleSpawner.playerCatchZ;
    _targetPlayerX = null;
    _targetPlayerZ = null;
    _isStunned = false;
    _stunTimer = 0.0;
    _specialCooldown = 0.0;
    _catchBufferTimer = 0.0;
    _screenShake = 0.0;
    _damageFlash = 0.0;
    _lastDamageTaken = 0;
    _isGameOver = false;
    _isVictory = false;
    _isPaused = false;
    _isPlaying = true;
    _isCutsceneActive = false;
    _cutsceneTimer = 0.0;
    _cameraIsoProgress = 0.0;
    _selectedOrganizeColumn = null;
    _selectedOrganizeDepthRow = null;
    _balesSinceLastCutscene = 0;
    _incomingPopupTimer = 0.0;
    _popupIncomingType = null;
    _organizeAlertTimer = 0.0;
    _organizeAlertRemaining = 0;
    _isHoldingLeft = false;
    _isHoldingRight = false;
    _isHoldingForward = false;
    _isHoldingBackward = false;
    _activeBales.clear();
    _stackedBales.clear();
    _notices.clear();

    _isHoldingBurningBale = false;
    _burningBaleTimer = 0.0;
    _magnetTimer = 0.0;
    _slowMoTimer = 0.0;
    _frenzyTimer = 0.0;
    _animalStampedeTimer = 0.0;
    _crosswindTimer = 0.0;
    _crosswindCooldown = 20.0;
    _windStrength = 0.0;
    _activeWaveEvent = WaveEventType.normal;
    _consecutivePerfects = 0;
    _orderCounter = 0;
    _currentHarvestOrder = _gameMode == GameModeType.arcade
        ? HarvestOrder.generateRandom(_orderCounter)
        : null;

    spawner.reset(_gameMode);
    trailerPhysics.reset();

    riveBridge.setCameraIsometricBlend(0.0);
    riveBridge.setHealth(_health);
    riveBridge.setMoveX(0.0);
    riveBridge.setTrailerWobble(0.0);
    notifyListeners();
  }

  // ===========================================================================
  // 7-SECOND CUTSCENE: 3x3x5 STACK ORGANIZATION MODE
  // ===========================================================================

  /// Starts the 7-second Cutscene where the player can freely organize stacked bales across the 3x3 grid.
  void startOrganizeCutscene() {
    if (_isGameOver || _isCutsceneActive) return;

    _isCutsceneActive = true;
    _cutsceneTimer = cutsceneDuration;
    _selectedOrganizeColumn = null;
    _selectedOrganizeDepthRow = null;
    _balesSinceLastCutscene = 0;
    _incomingPopupTimer = 0.0;
    _popupIncomingType = null;
    _organizeAlertTimer = 0.0;
    _organizeAlertRemaining = 0;
    _isHoldingLeft = false;
    _isHoldingRight = false;
    _isHoldingForward = false;
    _isHoldingBackward = false;

    // Clear any in-flight bales so none hit the farmer during the cutscene
    _activeBales.removeWhere((b) => b.state == BaleState.inFlight);

    AudioHapticsService.triggerSpecialHaptic();
    _addFloatingNotice('ORGANIZE (7s)', 0.0, -0.3, true);
    notifyListeners();
  }

  /// Finishes the 7-second Cutscene and smoothly transitions camera back to normal driving angle.
  void endOrganizeCutscene() {
    if (!_isCutsceneActive) return;

    _isCutsceneActive = false;
    _cutsceneTimer = 0.0;
    _selectedOrganizeColumn = null;
    _selectedOrganizeDepthRow = null;

    AudioHapticsService.playCatchSound();
    _addFloatingNotice('READY!', 0.0, -0.2, true);
    notifyListeners();
  }

  /// Interactive 3x3 cell tap handler during the 7-second Cutscene:
  /// Tap source cell `(col, depthRow)` -> Tap destination cell to move its top bale.
  void selectOrMoveOrganizeCell(int col, int depthRow) {
    if (!_isCutsceneActive) return;

    if (_selectedOrganizeColumn == null || _selectedOrganizeDepthRow == null) {
      if (getCellCount(col, depthRow) > 0) {
        _selectedOrganizeColumn = col;
        _selectedOrganizeDepthRow = depthRow;
        AudioHapticsService.triggerCatchHaptic();
        notifyListeners();
      }
      return;
    }

    if (_selectedOrganizeColumn == col &&
        _selectedOrganizeDepthRow == depthRow) {
      _selectedOrganizeColumn = null;
      _selectedOrganizeDepthRow = null;
      notifyListeners();
      return;
    }

    final bool moved = moveTopBaleBetweenCells(
      _selectedOrganizeColumn!,
      _selectedOrganizeDepthRow!,
      col,
      depthRow,
    );
    if (moved) {
      _selectedOrganizeColumn = null;
      _selectedOrganizeDepthRow = null;
    } else if (getCellCount(col, depthRow) > 0) {
      _selectedOrganizeColumn = col;
      _selectedOrganizeDepthRow = depthRow;
    }
    notifyListeners();
  }

  void selectOrMoveOrganizeColumn(int col) {
    selectOrMoveOrganizeCell(col, _selectedOrganizeDepthRow ?? currentPlayerDepthRow);
  }

  /// Moves the top bale from `(fromCol, fromRow)` to `(toCol, toRow)` if `< 5` tiers.
  bool moveTopBaleBetweenCells(
    int fromCol,
    int fromRow,
    int toCol,
    int toRow,
  ) {
    if (fromCol == toCol && fromRow == toRow) return false;

    final fromBales = _stackedBales
        .where((b) => b.column == fromCol && b.depthRow == fromRow)
        .toList();
    final toCount = getCellCount(toCol, toRow);

    if (fromBales.isEmpty) return false;
    if (toCount >= maxRowsPerColumn) {
      _addFloatingNotice('CELL FULL (MAX 5)!', StackedBale.worldXForColumn(toCol), -0.2, false);
      return false;
    }

    fromBales.sort((a, b) => a.tier.compareTo(b.tier));
    final StackedBale topBale = fromBales.last;
    _stackedBales.remove(topBale);

    final int newTier = toCount;
    _stackedBales.add(
      StackedBale(
        column: toCol,
        depthRow: toRow,
        tier: newTier,
        xOffset: StackedBale.worldXForColumn(toCol),
        yOffset: newTier * 0.45,
        zOffset: StackedBale.worldZForRow(toRow),
        tiltAngle: trailerPhysics.tiltAngle,
        colorHueVariation: topBale.colorHueVariation,
      ),
    );

    AudioHapticsService.playCatchSound();
    AudioHapticsService.triggerCatchHaptic();
    notifyListeners();
    return true;
  }

  bool moveTopBaleBetweenColumns(int fromCol, int toCol) {
    return moveTopBaleBetweenCells(
      fromCol,
      currentPlayerDepthRow,
      toCol,
      currentPlayerDepthRow,
    );
  }

  /// Automatically distributes all stacked bales evenly across the 3x3x5 wagon grid (9 cells, max 5 each).
  void autoBalanceStack() {
    if (_stackedBales.isEmpty) return;

    final List<double> hues =
        _stackedBales.map((b) => b.colorHueVariation).toList();
    _stackedBales.clear();

    for (int i = 0; i < hues.length; i++) {
      final int cellIndex = i % 9; // 9 cells in 3x3 grid
      final int col = cellIndex % 3;
      final int depthRow = cellIndex ~/ 3;
      final int tier = i ~/ 9;
      if (tier >= maxRowsPerColumn) break;

      _stackedBales.add(
        StackedBale(
          column: col,
          depthRow: depthRow,
          tier: tier,
          xOffset: StackedBale.worldXForColumn(col),
          yOffset: tier * 0.45,
          zOffset: StackedBale.worldZForRow(depthRow),
          tiltAngle: 0.0,
          colorHueVariation: hues[i],
        ),
      );
    }

    _selectedOrganizeColumn = null;
    _selectedOrganizeDepthRow = null;
    AudioHapticsService.triggerSpecialHaptic();
    _addFloatingNotice('3x3x5 BALANCED!', 0.0, -0.25, true);
    notifyListeners();
  }

  // ===========================================================================
  // CORE CATCH, 3x3x5 OVERFLOW PHYSICS, AND GAME-OVER / VICTORY LOGIC
  // ===========================================================================

  /// Catch Action triggered by the Hand Button or Screen Tap:
  /// Activates a 0.65-second Magnetic Catch Window so timing is forgiving and responsive!
  void handleCatchAction() {
    if (_isStunned || _isGameOver || _isPaused || _isCutsceneActive) return;

    _catchBufferTimer = catchBufferDuration;

    final result = collisionDetector.evaluateManualCatch(
      activeBales: _activeBales,
      playerX: _playerX,
      playerZ: _playerZ,
      isStunned: _isStunned,
    );

    if (result != null && result.outcome == CollisionOutcomeType.caught) {
      _catchBufferTimer = 0.0;
      _executeSuccessfulCatch(result.bale, true);
    } else {
      AudioHapticsService.triggerCatchHaptic();
    }
    notifyListeners();
  }

  /// Special Ability: Instant Stun Recovery or Golden Grab
  void handleSpecialAbility() {
    if (_specialCooldown > 0.0 || _isGameOver || _isPaused || _isCutsceneActive) {
      return;
    }

    AudioHapticsService.triggerSpecialHaptic();
    _specialCooldown = maxSpecialCooldown;

    if (_isStunned) {
      _isStunned = false;
      _stunTimer = 0.0;
      _addFloatingNotice('RECOVERED!', 0.0, -0.2, true);
    } else {
      StrawBale? caughtAny;
      for (final bale in _activeBales) {
        if (bale.state == BaleState.inFlight && bale.progress >= 0.45) {
          caughtAny = bale;
          break;
        }
      }
      if (caughtAny != null) {
        _executeSuccessfulCatch(caughtAny, true);
        _addFloatingNotice('GOLDEN GRAB!', 0.0, -0.2, true);
      } else {
        _addFloatingNotice('SPEED BOOST!', 0.0, -0.2, true);
      }
    }
    notifyListeners();
  }

  /// Finds the closest (col, row) cell that has room (< maxRowsPerColumn) using Manhattan distance.
  ({int col, int row})? findNearestAvailableCell(int targetCol, int targetRow) {
    ({int col, int row})? bestCell;
    int bestDist = 999;
    int bestCount = 999;

    for (int r = 0; r < gridDepthRows; r++) {
      for (int c = 0; c < gridColumns; c++) {
        final count = getCellCount(c, r);
        if (count < maxRowsPerColumn) {
          final dist = (c - targetCol).abs() + (r - targetRow).abs();
          if (dist < bestDist || (dist == bestDist && count < bestCount)) {
            bestDist = dist;
            bestCount = count;
            bestCell = (col: c, row: r);
          }
        }
      }
    }
    return bestCell;
  }

  /// Completes the current wagon in Arcade mode (or via manual early haul in cutscene),
  /// grants bonus points & health (+25 HP / 1 Heart), and brings the next fresh wagon in the endless loop!
  void completeWagon({bool isFullWagonBonus = true}) {
    if (_isGameOver) return;

    _wagonsCompleted++;
    _lifetimeWagonsCompleted++;
    _persistWagonsCompleted();

    final int bonusPoints = isFullWagonBonus
        ? 1000
        : (_stackedBales.length * 20);
    _score += bonusPoints;
    if (_score > _highScore) {
      _highScore = _score;
    }

    // Health reward (+25 HP / 1 heart, capped at 100)
    _health = math.min(100.0, _health + 25.0);
    riveBridge.setHealth(_health);

    AudioHapticsService.triggerSpecialHaptic();

    // Clear active in-flight bales to provide a clean transition
    _activeBales.clear();
    _stackedBales.clear();
    _balesSinceLastCutscene = 0;

    if (_isCutsceneActive) {
      _isCutsceneActive = false;
      _cutsceneTimer = 0.0;
    }

    _addFloatingNotice(
      isFullWagonBonus
          ? '🚛 WAGON #$_wagonsCompleted FULL! +$bonusPoints'
          : '🚛 HAUL #$_wagonsCompleted! +$bonusPoints',
      0.0,
      -0.25,
      true,
    );

    // 25% chance to trigger an Animal Stampede wave event in Arcade mode!
    if (_gameMode == GameModeType.arcade && _random.nextDouble() < 0.25) {
      _animalStampedeTimer = 10.0;
      _activeWaveEvent = WaveEventType.animalStampede;
      spawner.setWaveEvent(WaveEventType.animalStampede);
      _addFloatingNotice('🐔 ANIMAL STAMPEDE! (10s)', 0.0, -0.2, true);
    }

    notifyListeners();
  }

  /// Throws away the held burning bale out of the wagon into the meadow before it explodes!
  void throwHeldBurningBale() {
    if (!_isHoldingBurningBale) return;
    _isHoldingBurningBale = false;
    _burningBaleTimer = 0.0;

    // Spawn a high flying thrown-away burning bale trajectory out into the distance
    final tossed = StrawBale(
      id: 'thrown_burning_${DateTime.now().microsecondsSinceEpoch}',
      objectType: ThrownObjectType.burningBale,
      startPos: Vector3(_playerX, playerY + 0.6, _playerZ),
      targetPos: Vector3(_playerX * 2.5, 0.2, -6.5),
      arcHeight: 2.8,
      flightDuration: 0.95,
      angularVelocity: Vector3(8.0, 5.0, 6.0),
    );
    tossed.state = BaleState.thrownAway;
    tossed.missedDisplayTimer = 0.85;
    tossed.tumbleVelocity = Vector3(
      (_random.nextDouble() - 0.5) * 2.2,
      5.4,
      -5.0,
    );
    _activeBales.add(tossed);

    _score += 150;
    if (_score > _highScore) _highScore = _score;
    AudioHapticsService.triggerCatchHaptic();
    _addFloatingNotice('🔥 THROWN AWAY! +150', _playerX, -0.3, true);

    _advanceHarvestOrder(HarvestOrderType.firefighter);
    notifyListeners();
  }

  /// Clears all stacked bales in the given (col, row) cell due to fire damage,
  /// triggers screen shake, and returns the number of bales destroyed.
  int _burnCellBales(int col, int row) {
    final int countBefore = getCellCount(col, row);
    _stackedBales.removeWhere((b) => b.column == col && b.depthRow == row);
    AudioHapticsService.playStunSound();
    AudioHapticsService.triggerStunHaptic();
    _screenShake = math.max(_screenShake, 0.75);
    _damageFlash = 1.0;
    return countBefore;
  }

  /// Advances progress on the current active harvest order, rewarding points and health if completed.
  void _advanceHarvestOrder(HarvestOrderType type, [int amount = 1]) {
    final order = _currentHarvestOrder;
    if (order == null || order.type != type || order.isCompleted) return;

    order.progress = math.min(order.target, order.progress + amount);
    if (order.isCompleted) {
      _score += order.rewardPoints;
      if (_score > _highScore) _highScore = _score;
      if (order.rewardHealth > 0.0) {
        _health = math.min(100.0, _health + order.rewardHealth);
        riveBridge.setHealth(_health);
      }
      AudioHapticsService.triggerSpecialHaptic();
      _addFloatingNotice('📋 ORDER COMPLETE! +${order.rewardPoints}', 0.0, -0.25, true);

      // Generate next random order
      _orderCounter++;
      _currentHarvestOrder = HarvestOrder.generateRandom(_orderCounter);
    }
  }

  /// Handles game mechanics on successful bale or animal catch in the 3x3x5 wagon grid.
  void _executeSuccessfulCatch(StrawBale bale, bool isPerfect) {
    // 1. If player caught a burning bale (Hot Potato mode!):
    if (bale.objectType == ThrownObjectType.burningBale) {
      bale.state = BaleState.caught;
      _isHoldingBurningBale = true;
      _burningBaleTimer = maxBurningHoldDuration;
      _incomingPopupTimer = 0.0;
      AudioHapticsService.triggerSpecialHaptic();
      _addFloatingNotice('🔥 HOT POTATO! THROW! (3s)', _playerX, -0.35, true, isDamage: true);
      _recordObjectCaught(bale.objectType);
      notifyListeners();
      return;
    }

    // 2. If the player caught a farm animal (chicken, rooster, duck, sheep, cow, cat, dog, bird):
    if (bale.objectType.isAnimal) {
      _handleAnimalCaught(bale);
      return;
    }

    // 3. If Magnet Power-Up:
    if (bale.objectType == ThrownObjectType.magnetPowerUp) {
      bale.state = BaleState.caught;
      _magnetTimer = 6.0;
      _incomingPopupTimer = 0.0;
      _recordObjectCaught(bale.objectType);
      AudioHapticsService.triggerSpecialHaptic();
      _addFloatingNotice('🧲 MAGNET ACTIVE (6s)!', _playerX, -0.3, true);
      notifyListeners();
      return;
    }

    // 4. If Slow-Mo Power-Up:
    if (bale.objectType == ThrownObjectType.slowMoPowerUp) {
      bale.state = BaleState.caught;
      _slowMoTimer = 5.0;
      _incomingPopupTimer = 0.0;
      _recordObjectCaught(bale.objectType);
      AudioHapticsService.triggerSpecialHaptic();
      _addFloatingNotice('⏳ SLOW-MO ACTIVE (5s)!', _playerX, -0.3, true);
      notifyListeners();
      return;
    }

    final int targetCol = currentPlayerColumn;
    final int targetRow = currentPlayerDepthRow;
    final int existingInCell = getCellCount(targetCol, targetRow);

    int placeCol = targetCol;
    int placeRow = targetRow;
    int placeTier = existingInCell;
    bool wasSpillover = false;

    // Check if this (col, depthRow) cell already has the maximum 5 rows!
    if (existingInCell >= maxRowsPerColumn) {
      final nearest = findNearestAvailableCell(targetCol, targetRow);
      if (nearest != null) {
        // Smart Spillover: place bale in the nearest incomplete cell without penalty!
        placeCol = nearest.col;
        placeRow = nearest.row;
        placeTier = getCellCount(placeCol, placeRow);
        wasSpillover = true;
      } else {
        // Entire 3x3x5 wagon (45 bales) is completely full!
        if (_gameMode == GameModeType.arcade) {
          _balesCaught++;
          _recordObjectCaught(ThrownObjectType.bale);
          completeWagon(isFullWagonBonus: true);
          return;
        } else {
          _handleColumnOverflowPhysics(bale, targetCol, targetRow);
          return;
        }
      }
    }

    bale.state = BaleState.caught;
    _balesCaught++;
    _balesSinceLastCutscene++;
    _incomingPopupTimer = 0.0;
    final remainingCutscene = balesPerAutoCutscene - _balesSinceLastCutscene;
    if (remainingCutscene > 0 && remainingCutscene <= 3) {
      _organizeAlertTimer = 2.0;
      _organizeAlertRemaining = remainingCutscene;
    }
    _recordObjectCaught(bale.objectType);

    // Increment combo
    _comboCount++;
    if (_comboCount >= 8) {
      _comboMultiplier = 4;
    } else if (_comboCount >= 5) {
      _comboMultiplier = 3;
    } else if (_comboCount >= 2) {
      _comboMultiplier = 2;
    } else {
      _comboMultiplier = 1;
    }

    if (_comboCount >= 2) {
      _addFloatingNotice('🔥 $_comboCount STREAK! (${_comboMultiplier}x)', playerX, 0.45, true);
    }

    // Trigger Frenzy Time when combo hits 10+ in Arcade mode!
    if (_comboCount >= 10 &&
        _activeWaveEvent == WaveEventType.normal &&
        _gameMode == GameModeType.arcade) {
      _activeWaveEvent = WaveEventType.frenzy;
      _frenzyTimer = 8.0;
      spawner.setWaveEvent(WaveEventType.frenzy);
      _addFloatingNotice('🌪️ FRENZY TIME! 2x PTS', 0.0, -0.2, true);
    }

    // Clutch / Perfect catch combo tracking
    if (isPerfect) {
      _consecutivePerfects++;
      if (_consecutivePerfects >= 5) {
        _consecutivePerfects = 0;
        autoBalanceStack();
        _addFloatingNotice('⚡ 5x PERFECT! AUTO-BALANCED!', 0.0, -0.2, true);
      }
    } else {
      _consecutivePerfects = 0;
    }

    final bool isGolden = bale.objectType == ThrownObjectType.goldenBale;
    final int basePoints = isGolden ? 250 : (isPerfect ? 150 : 100);
    final double atmMult = atmosphereMultiplier;
    final int frenzyMult = isFrenzyActive ? 2 : 1;
    final int points = (basePoints * _comboMultiplier * atmMult * frenzyMult).round();
    _score += points;
    if (_score > _highScore) {
      _highScore = _score;
    }

    if (isGolden) {
      _health = math.min(100.0, _health + 20.0);
      riveBridge.setHealth(_health);
      _advanceHarvestOrder(HarvestOrderType.goldenHunter);
    }

    _advanceHarvestOrder(HarvestOrderType.cleanHands);
    if (placeRow == 0) _advanceHarvestOrder(HarvestOrderType.frontRowRush);
    if (_comboMultiplier >= 5 || _comboCount >= 5) {
      _advanceHarvestOrder(HarvestOrderType.comboMaster);
    }

    AudioHapticsService.playCatchSound();
    AudioHapticsService.triggerCatchHaptic();
    riveBridge.triggerCatchSuccess();

    // Stack the caught bale into the 3x3x5 grid at (placeCol, placeRow, placeTier)
    _placeBaleInWagon(bale, placeCol, placeRow, placeTier);

    final noticeText = isGolden
        ? '🌟 GOLDEN +$points'
        : (wasSpillover ? '+$points (SPILLOVER)' : '+$points');
    _addFloatingNotice(noticeText, _playerX, -0.3, isPerfect || isGolden);

    // Check Victory Condition: Full 3x3x5 Wagon (45 Bales) or Quota Met!
    if (_stackedBales.length >= maxWagonCapacity) {
      if (_gameMode == GameModeType.puzzle) {
        _isVictory = true;
        _isGameOver = true;
        _isPlaying = false;
        _score += 500; // Full wagon completion bonus!
        if (_score > _highScore) _highScore = _score;
        _addFloatingNotice('WAGON FULL! 3x3x5 COMPLETE!', 0.0, 0.0, true);
        notifyListeners();
        return;
      } else {
        // ARCADE ENDLESS LOOP: Complete current wagon, award bonuses, clear stacked bales, and bring next wagon!
        completeWagon(isFullWagonBonus: true);
        return;
      }
    }

    if (_gameMode == GameModeType.puzzle && _balesCaught >= _targetQuota) {
      _isVictory = true;
      _isGameOver = true;
      _isPlaying = false;
      _score += 500;
      if (_score > _highScore) _highScore = _score;
      _addFloatingNotice('PUZZLE TARGET COMPLETE!', 0.0, 0.0, true);
      notifyListeners();
      return;
    }

    // Trigger 7-second organization cutscene every 15 caught bales
    // or when a cell reaches 5 rows and at least 15 bales have been caught
    final bool hasRoomToOrganize = _stackedBales.length < maxWagonCapacity;
    if (hasRoomToOrganize &&
        (_balesSinceLastCutscene >= balesPerAutoCutscene ||
            (existingInCell + 1 == maxRowsPerColumn &&
                _balesSinceLastCutscene >= 10 &&
                _stackedBales.length >= 15))) {
      startOrganizeCutscene();
    }

    notifyListeners();
  }

  /// Places a caught bale into the 3x3x5 wagon grid at `(targetCol, targetRow, tier)`.
  void _placeBaleInWagon(
    StrawBale bale,
    int targetCol,
    int targetRow,
    int tier,
  ) {
    final double cellX = StackedBale.worldXForColumn(targetCol);
    final double cellZ = StackedBale.worldZForRow(targetRow);

    final stacked = StackedBale(
      column: targetCol,
      depthRow: targetRow,
      tier: tier,
      xOffset: cellX,
      yOffset: tier * 0.45,
      zOffset: cellZ,
      tiltAngle: trailerPhysics.tiltAngle,
      colorHueVariation: bale.colorHueVariation,
      isGolden: bale.objectType == ThrownObjectType.goldenBale,
    );

    _stackedBales.add(stacked);
  }

  /// When a (col, depthRow) cell already has 5 rows, the 6th bale tumbles
  /// based on 3D physics either OUTSIDE the wagon or INSIDE the wagon floor!
  void _handleColumnOverflowPhysics(
    StrawBale bale,
    int targetCol,
    int targetRow,
  ) {
    final double cellX = StackedBale.worldXForColumn(targetCol);
    final double cellZ = StackedBale.worldZForRow(targetRow);
    final double topOfFiveRowsY =
        BaleSpawner.wagonFloorY + (maxRowsPerColumn * 0.36);

    bale.currentPos.setValues(cellX, topOfFiveRowsY, cellZ);
    bale.missedDisplayTimer = StrawBale.maxMissedDisplayDuration;

    final double tiltPush = trailerPhysics.tiltAngle * 4.5;
    final double colOutwardBias = (targetCol - 1) * 0.55;
    final double randomTorque = (_random.nextDouble() - 0.5) * 0.9;
    final double netLateral = colOutwardBias + tiltPush + randomTorque;

    final bool fallsOutside = (targetCol == 0 && netLateral < -0.1) ||
        (targetCol == 2 && netLateral > 0.1) ||
        (targetRow == 2 && _random.nextBool()) ||
        netLateral.abs() > 0.48;

    if (fallsOutside) {
      bale.state = BaleState.overflowOutside;
      final double outDir = targetCol == 0
          ? -1.0
          : (targetCol == 2 ? 1.0 : (netLateral >= 0 ? 1.0 : -1.0));
      bale.tumbleVelocity.setValues(outDir * 2.3, 1.8, -0.6);
      AudioHapticsService.triggerSpecialHaptic();
      _applyMissedBaleDamage('5 ROW MAX! FELL OUTSIDE! -15 HP', cellX);
    } else {
      // Check if an adjacent cell in the 3x3 grid has < 5 rows to catch the roll,
      // otherwise it falls onto the wagon floor as MISSED!
      bale.state = BaleState.overflowInside;
      final double inDir = targetCol == 0
          ? 1.1
          : (targetCol == 2 ? -1.1 : (_random.nextBool() ? 0.8 : -0.8));
      bale.tumbleVelocity.setValues(inDir, 1.5, -0.9);
      AudioHapticsService.triggerSpecialHaptic();
      _applyMissedBaleDamage('5 ROW MAX! MISSED! -15 HP', cellX);
    }

    notifyListeners();
  }

  /// Reduces health when a bale is missed or falls off, triggering Game Over if health reaches 0.
  void _applyMissedBaleDamage(String noticeMessage, double noticeX) {
    _missedCount++;
    _comboCount = 0;
    _comboMultiplier = 1;
    _incomingPopupTimer = 0.0;

    _health = math.max(0.0, _health - 15.0);
    _lastDamageTaken = 15;
    _damageFlash = 1.0;
    _screenShake = math.max(_screenShake, 0.65);

    AudioHapticsService.playStunSound();
    AudioHapticsService.triggerStunHaptic();
    riveBridge.setHealth(_health);
    _addFloatingNotice(noticeMessage, noticeX, -0.35, false, isDamage: true);

    if (_health <= 0.0) {
      _isVictory = false;
      _isGameOver = true;
      _isPlaying = false;
      _addFloatingNotice('GAME OVER!', 0.0, 0.0, true, isDamage: true);
    }
  }

  /// Handles catching a farm animal: records per-animal caught statistic,
  /// applies a short-duration stun (~0.95s), and lets the animal scurry away!
  void _handleAnimalCaught(StrawBale animal) {
    _recordObjectCaught(animal.objectType);
    animal.wasCaughtBeforeEscape = true;
    _startAnimalEscapeOnWagon(animal);

    _isStunned = true;
    _stunTimer = animalCatchStunDuration;
    _incomingPopupTimer = 0.0;
    _comboCount = 0;
    _comboMultiplier = 1;
    _screenShake = math.max(_screenShake, 0.45);

    AudioHapticsService.playStunSound();
    AudioHapticsService.triggerStunHaptic();
    riveBridge.triggerStun();

    _addFloatingNotice(
      '${animal.objectType.emoji} STUN!',
      _playerX,
      -0.38,
      true,
      isDamage: true,
    );
    notifyListeners();
  }

  /// Starts the running/hopping escape animation for a farm animal on the wagon floor.
  void _startAnimalEscapeOnWagon(StrawBale animal) {
    animal.state = BaleState.escaping;
    animal.missedDisplayTimer = StrawBale.maxEscapeDuration;
    animal.currentPos.setValues(
      animal.targetPos.x,
      BaleSpawner.wagonFloorY + 0.14,
      animal.targetPos.z,
    );
    // Run toward nearest side or rear edge of the wagon
    final double dirX = animal.targetPos.x >= 0.0
        ? (1.6 + _random.nextDouble() * 0.7)
        : -(1.6 + _random.nextDouble() * 0.7);
    final double dirZ = -1.2 - _random.nextDouble() * 0.9;
    animal.tumbleVelocity.setValues(dirX, 1.4, dirZ);
  }

  /// Handles direct hit on player -> 3-second stun penalty & -25 HP damage (or animal catch if animal)
  void _handleStunPenalty(StrawBale bale) {
    if (bale.objectType.isAnimal) {
      _handleAnimalCaught(bale);
      return;
    }

    bale.state = BaleState.stunHit;
    _isStunned = true;
    _stunTimer = stunDuration;
    _incomingPopupTimer = 0.0;

    _comboCount = 0;
    _comboMultiplier = 1;

    _health = math.max(0.0, _health - 25.0);
    _lastDamageTaken = 25;
    _damageFlash = 1.0;
    riveBridge.setHealth(_health);

    if (bale.objectType == ThrownObjectType.burningBale) {
      _burnCellBales(currentPlayerColumn, currentPlayerDepthRow);
      _score = math.max(0, _score - 250);
      _addFloatingNotice('🔥 BURNED ON IMPACT! -250 PTS', _playerX, -0.35, true, isDamage: true);
    }

    AudioHapticsService.playStunSound();
    AudioHapticsService.triggerStunHaptic();
    _screenShake = 1.0;
    riveBridge.triggerStun();

    _addFloatingNotice('STUNNED! -25 HP', _playerX, -0.4, true, isDamage: true);

    if (_health <= 0.0) {
      _isVictory = false;
      _isGameOver = true;
      _isPlaying = false;
      _addFloatingNotice('GAME OVER', 0.0, 0.0, true, isDamage: true);
    }

    notifyListeners();
  }

  void _addFloatingNotice(
    String text,
    double x,
    double y,
    bool isSpecial, {
    bool isDamage = false,
  }) {
    _notices.add(FloatingNotice(
      text: text,
      x: x,
      y: y,
      isSpecial: isSpecial,
      isDamage: isDamage,
    ));
  }

  /// Core Game Loop update called by Ticker / AnimationController on each frame.
  void update(double dt) {
    if (!_isPlaying || _isPaused || _isGameOver) return;

    for (final notice in _notices) {
      notice.lifeTime -= dt * 1.35;
    }
    _notices.removeWhere((n) => n.lifeTime <= 0.0);

    // Smoothly animate 3D camera between Normal Road View (0.0) and Diagonal Isometric Wagon View (1.0)
    final double targetIso = _isCutsceneActive ? 1.0 : 0.0;
    if ((_cameraIsoProgress - targetIso).abs() > 0.0005) {
      if (_cameraIsoProgress < targetIso) {
        _cameraIsoProgress = math.min(1.0, _cameraIsoProgress + dt * 2.2);
      } else {
        _cameraIsoProgress = math.max(0.0, _cameraIsoProgress - dt * 2.2);
      }
      riveBridge.setCameraIsometricBlend(cameraIsoCurved);
    }

    // Handle 7-Second Cutscene (3x3x5 Bale Organization Mode) countdown
    if (_isCutsceneActive) {
      _cutsceneTimer -= dt;
      _worldScrollZ += dt * 1.4; // Slow-motion road scroll during cutscene
      _animTime += dt;
      trailerPhysics.update(dt * 0.25, false);
      if (_cutsceneTimer <= 0.0) {
        endOrganizeCutscene();
      } else {
        notifyListeners();
      }
      return;
    }

    // Advance continuous 3D road & environment scroll
    _worldScrollZ += dt * 3.4;
    _animTime += dt;

    // While interactive How-To-Play Tutorial is active, allow 3D scene & farmer movement preview without spawning bales
    if (_isTutorialActive) {
      trailerPhysics.update(dt * 0.3, false);
      notifyListeners();
      return;
    }

    // 1. Process 2D Player Movement (Left/Right X & Forward/Backward Z) + Smooth Cell Glide
    if (!_isStunned) {
      if (_isHoldingLeft) {
        _playerX = math.max(
          BaleSpawner.wagonMinX,
          _playerX - (playerSpeed * dt),
        );
        riveBridge.setMoveX(normalizedPlayerX);
      } else if (_isHoldingRight) {
        _playerX = math.min(
          BaleSpawner.wagonMaxX,
          _playerX + (playerSpeed * dt),
        );
        riveBridge.setMoveX(normalizedPlayerX);
      } else if (_targetPlayerX != null) {
        final double diffX = _targetPlayerX! - _playerX;
        if (diffX.abs() < 0.04) {
          _playerX = _targetPlayerX!;
          _targetPlayerX = null;
        } else {
          _playerX += diffX.sign * math.min(diffX.abs(), playerSpeed * 1.5 * dt);
        }
        riveBridge.setMoveX(normalizedPlayerX);
      }

      if (_isHoldingForward) {
        _playerZ = math.min(
          BaleSpawner.wagonMaxZ,
          _playerZ + (playerSpeed * 0.85 * dt),
        );
      } else if (_isHoldingBackward) {
        _playerZ = math.max(
          BaleSpawner.wagonMinZ,
          _playerZ - (playerSpeed * 0.85 * dt),
        );
      } else if (_targetPlayerZ != null) {
        final double diffZ = _targetPlayerZ! - _playerZ;
        if (diffZ.abs() < 0.04) {
          _playerZ = _targetPlayerZ!;
          _targetPlayerZ = null;
        } else {
          _playerZ += diffZ.sign * math.min(diffZ.abs(), playerSpeed * 1.3 * dt);
        }
      }
    }

    // 1b. Update Magnetic Catch Buffer Timer
    if (_catchBufferTimer > 0.0) {
      _catchBufferTimer = math.max(0.0, _catchBufferTimer - dt);
    }

    // 2. Update stun countdown timer
    if (_isStunned) {
      _stunTimer -= dt;
      if (_stunTimer <= 0.0) {
        _isStunned = false;
        _stunTimer = 0.0;
        _addFloatingNotice('READY!', _playerX, -0.2, false);
      }
    }

    // 3. Update special cooldown
    if (_specialCooldown > 0.0) {
      _specialCooldown = math.max(0.0, _specialCooldown - dt);
    }

    // 4. Update screen shake and damage flash decay
    if (_screenShake > 0.0) {
      _screenShake = math.max(0.0, _screenShake - (dt * 3.0));
    }
    if (_damageFlash > 0.0) {
      _damageFlash = math.max(0.0, _damageFlash - (dt * 1.65));
    }

    // 4b. Update incoming object and organize alert popup timers
    if (_incomingPopupTimer > 0.0) {
      _incomingPopupTimer = math.max(0.0, _incomingPopupTimer - dt);
    }
    if (_organizeAlertTimer > 0.0) {
      _organizeAlertTimer = math.max(0.0, _organizeAlertTimer - dt);
    }

    // 4c. Update Burning Bale Hot Potato timer
    if (_isHoldingBurningBale) {
      _burningBaleTimer -= dt;
      if (_burningBaleTimer <= 0.0) {
        _isHoldingBurningBale = false;
        _burningBaleTimer = 0.0;
        final burned = _burnCellBales(currentPlayerColumn, currentPlayerDepthRow);
        final int penalty = 150 + (burned * 50);
        _score = math.max(0, _score - penalty);
        _applyMissedBaleDamage('💥 EXPLODED! -$penalty PTS', _playerX);
        _isStunned = true;
        _stunTimer = 1.0;
      }
    }

    // 4d. Update Power-Up & Wave Event timers
    if (_magnetTimer > 0.0) _magnetTimer = math.max(0.0, _magnetTimer - dt);
    if (_slowMoTimer > 0.0) _slowMoTimer = math.max(0.0, _slowMoTimer - dt);
    if (_frenzyTimer > 0.0) {
      _frenzyTimer = math.max(0.0, _frenzyTimer - dt);
      if (_frenzyTimer <= 0.0 && _activeWaveEvent == WaveEventType.frenzy) {
        _activeWaveEvent = WaveEventType.normal;
        spawner.setWaveEvent(WaveEventType.normal);
      }
    }
    if (_animalStampedeTimer > 0.0) {
      _animalStampedeTimer = math.max(0.0, _animalStampedeTimer - dt);
      if (_animalStampedeTimer <= 0.0 && _activeWaveEvent == WaveEventType.animalStampede) {
        _activeWaveEvent = WaveEventType.normal;
        spawner.setWaveEvent(WaveEventType.normal);
      }
    }
    if (_crosswindTimer > 0.0) {
      _crosswindTimer = math.max(0.0, _crosswindTimer - dt);
      if (_crosswindTimer <= 0.0 && _activeWaveEvent == WaveEventType.crosswind) {
        _activeWaveEvent = WaveEventType.normal;
        _windStrength = 0.0;
        spawner.setWaveEvent(WaveEventType.normal);
      }
    } else if (_wagonsCompleted >= 2 &&
        _activeWaveEvent == WaveEventType.normal &&
        _gameMode == GameModeType.arcade) {
      _crosswindCooldown -= dt;
      if (_crosswindCooldown <= 0.0) {
        _crosswindCooldown = 32.0;
        _crosswindTimer = 12.0;
        _windStrength = _random.nextBool() ? 1.0 : -1.0;
        _activeWaveEvent = WaveEventType.crosswind;
        spawner.setWaveEvent(WaveEventType.crosswind, wind: _windStrength);
        _addFloatingNotice(_windStrength > 0 ? '💨 WIND >>>' : '<<< WIND 💨', 0.0, -0.2, true);
      }
    }

    // 5. Update trailer physics and sync to Rive
    trailerPhysics.update(dt, _gameMode == GameModeType.puzzle);
    riveBridge.setTrailerWobble(trailerPhysics.wobbleIntensity);

    if (_gameMode == GameModeType.puzzle && _stackedBales.isNotEmpty) {
      for (final bale in _stackedBales) {
        bale.tiltAngle = trailerPhysics.tiltAngle * (1.0 + bale.tier * 0.4);
      }
    }

    // 6. Spawn new bales and sync 3D landing target with Rive Camera
    // (Wait until camera finishes returning from isometric cutscene view before throwing next bale)
    final availableCells = <({int col, int row})>[];
    for (int r = 0; r < gridDepthRows; r++) {
      for (int c = 0; c < gridColumns; c++) {
        if (getCellCount(c, r) < maxRowsPerColumn) {
          availableCells.add((col: c, row: r));
        }
      }
    }

    final newBale = _cameraIsoProgress > 0.15
        ? null
        : spawner.update(
            dt,
            _gameMode,
            _score,
            availableCells: availableCells,
          );
    if (newBale != null) {
      _activeBales.add(newBale);
      riveBridge.syncBaleLandingTarget(
        newBale.targetPos.x,
        newBale.targetPos.z,
      );
      _popupIncomingType = newBale.objectType;
      _incomingPopupTimer = 1.8;
    }

    // 7. Update in-flight and missed/overflow bales (with slow-mo multiplier if active)
    final double baleDt = _slowMoTimer > 0.0 ? dt * 0.5 : dt;
    for (final bale in _activeBales) {
      bale.update(baleDt);
    }

    // 7b. Automatic Hands-Zone Catch in 3D (X, Z) when farmer is aligned with target cell (+ Magnet pull)
    if (!_isStunned) {
      for (final bale in _activeBales) {
        if (bale.state != BaleState.inFlight) continue;
        final double dx = (_playerX - bale.targetPos.x).abs();
        final double dz = (_playerZ - bale.targetPos.z).abs() * 0.65;
        final double dist3D = math.sqrt(dx * dx + dz * dz);
        final bool sameGridCell = bale.gridCol != null &&
            bale.gridRow != null &&
            bale.gridCol == currentPlayerColumn &&
            bale.gridRow == currentPlayerDepthRow;

        // Magnet Power-Up effect: draws stackable bales within wider radius
        final bool isMagnetPulled = _magnetTimer > 0.0 &&
            bale.objectType.isBaleLike &&
            dist3D <= 1.25 &&
            bale.progress >= 0.70;

        if (_catchBufferTimer > 0.0 &&
            bale.progress >= 0.58 &&
            dist3D <= 0.90) {
          _catchBufferTimer = 0.0;
          _executeSuccessfulCatch(bale, true);
          break;
        }

        if (isMagnetPulled) {
          _executeSuccessfulCatch(bale, true);
          break;
        }

        if (autoCatchEnabled &&
            bale.progress >= 0.76 &&
            bale.progress < 0.96 &&
            (sameGridCell || dist3D <= 0.60)) {
          final bool isClutch = bale.progress >= 0.82;
          _executeSuccessfulCatch(bale, isClutch || dist3D <= 0.30 || sameGridCell);
          break;
        }
      }
    }

    // 8. Evaluate passive landing collisions (landing on floor or hitting player)
    final landingEvents = collisionDetector.evaluateLandingCollisions(
      activeBales: _activeBales,
      playerX: _playerX,
      playerZ: _playerZ,
      isStunned: _isStunned,
    );

    for (final event in landingEvents) {
      if (event.outcome == CollisionOutcomeType.stunned) {
        _handleStunPenalty(event.bale);
      } else if (event.outcome == CollisionOutcomeType.missedFloor) {
        if (event.bale.objectType == ThrownObjectType.burningBale) {
          // Burning bale landed uncaught on the wagon floor:
          // It scorches the cell and burns all stacked bales in it!
          final int tCol = event.bale.gridCol ?? 1;
          final int tRow = event.bale.gridRow ?? 1;
          final int burnedCount = _burnCellBales(tCol, tRow);

          event.bale.state = BaleState.burnedCell;
          event.bale.missedDisplayTimer = 0.85;
          event.bale.currentPos.setValues(
            event.bale.targetPos.x,
            BaleSpawner.wagonFloorY + 0.18,
            event.bale.targetPos.z,
          );

          final int penalty = 150 + (burnedCount * 50);
          _score = math.max(0, _score - penalty);
          _comboCount = 0;
          _comboMultiplier = 1;
          _addFloatingNotice(
            burnedCount > 0
                ? '🔥 BURNED $burnedCount BALES! -$penalty PTS'
                : '🔥 SCORCHED! -$penalty PTS',
            event.bale.targetPos.x,
            -0.35,
            true,
            isDamage: true,
          );
        } else if (event.bale.objectType.isAnimal) {
          // Farm animal landed on the wagon floor uncaught:
          // It immediately runs/hops away off the wagon without hurting player health!
          _startAnimalEscapeOnWagon(event.bale);
        } else {
          // Bale landed inside the wagon without being caught:
          final int tCol = event.bale.gridCol ?? 1;
          final int tRow = event.bale.gridRow ?? 1;
          final bool wasTargetCellFull =
              getCellCount(tCol, tRow) >= maxRowsPerColumn;

          event.bale.state = BaleState.missed;
          event.bale.missedDisplayTimer = StrawBale.maxMissedDisplayDuration;
          event.bale.currentPos.setValues(
            event.bale.targetPos.x,
            BaleSpawner.wagonFloorY + 0.18,
            event.bale.targetPos.z,
          );
          event.bale.tumbleVelocity = Vector3(
            (_random.nextDouble() - 0.5) * 0.5,
            1.4,
            -0.3,
          );

          if (!wasTargetCellFull) {
            if (_activeWaveEvent == WaveEventType.frenzy) {
              // During Frenzy wave, missed bales do not deduct health!
              AudioHapticsService.triggerCatchHaptic();
              _addFloatingNotice('FRENZY (NO DAMAGE)', event.bale.targetPos.x, -0.35, false);
            } else {
              _applyMissedBaleDamage('-15 HP', event.bale.targetPos.x);
            }
          } else {
            // Target was already full (5/5) - bounce off without unfair penalty!
            AudioHapticsService.triggerCatchHaptic();
            _addFloatingNotice('BOUNCED', event.bale.targetPos.x, -0.35, false);
          }
        }
      }
    }

    // 9. Remove inactive bales only after their missed/overflow/escape display timer finishes
    _activeBales.removeWhere((b) =>
        b.state == BaleState.caught ||
        b.state == BaleState.stunHit ||
        ((b.state == BaleState.missed ||
                b.state == BaleState.escaping ||
                b.state == BaleState.thrownAway ||
                b.state == BaleState.burnedCell ||
                b.state == BaleState.overflowOutside ||
                b.state == BaleState.overflowInside) &&
            b.missedDisplayTimer <= 0.0));

    notifyListeners();
  }
}
