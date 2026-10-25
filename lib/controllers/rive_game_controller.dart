import 'package:flutter/foundation.dart';
import 'package:rive/rive.dart';
import '../physics/camera_3d.dart';

/// Dedicated Rive Controller and State Machine Bridge for Hay Bale Stacking Game.
/// Connects Flutter game physics, 3D camera (-55° Pitch, 45° FOV), warm lighting,
/// and touch inputs directly to the Rive Artboard and State Machine.
class RiveGameController extends ChangeNotifier {
  // Asset path
  static const String riveAssetPath = 'assets/rive/hay_bale_game.riv';
  static const String stateMachineName = 'FarmGameStateMachine';

  Artboard? _artboard;
  StateMachineController? _stateMachineController;

  // 3D Scene Camera & Lighting Configuration (Matches Rive Script Nodes)
  Rive3DSceneConfig _sceneConfig = Rive3DSceneConfig.cozyFarmDefault();

  // Bound Core Gameplay State Machine Inputs
  SMIInput<double>? _moveXInput;
  SMITrigger? _stunTrigger;
  SMITrigger? _catchSuccessTrigger;
  SMIInput<double>? _healthValueInput;
  SMIInput<double>? _gameModeInput;
  SMIInput<double>? _trailerWobbleInput;

  // Bound 3D Camera & Lighting Script Inputs
  SMIInput<double>? _cameraPitchInput;
  SMIInput<double>? _cameraFovInput;
  SMIInput<double>? _keyLightIntensityInput;
  SMIInput<double>? _shadowDarknessInput;
  SMIInput<double>? _baleLandingXInput;
  SMIInput<double>? _baleLandingZInput;

  bool _isRiveAvailable = false;
  bool _isInitialized = false;
  String? _errorMessage;

  // Getters
  bool get isRiveAvailable => _isRiveAvailable;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  Artboard? get artboard => _artboard;
  Rive3DSceneConfig get sceneConfig => _sceneConfig;

  // Exposed inputs for inspection
  SMIInput<double>? get moveXInput => _moveXInput;
  SMITrigger? get stunTrigger => _stunTrigger;
  SMITrigger? get catchSuccessTrigger => _catchSuccessTrigger;
  SMIInput<double>? get healthValueInput => _healthValueInput;
  SMIInput<double>? get gameModeInput => _gameModeInput;
  SMIInput<double>? get trailerWobbleInput => _trailerWobbleInput;
  SMIInput<double>? get cameraPitchInput => _cameraPitchInput;
  SMIInput<double>? get cameraFovInput => _cameraFovInput;
  SMIInput<double>? get keyLightIntensityInput => _keyLightIntensityInput;
  SMIInput<double>? get shadowDarknessInput => _shadowDarknessInput;

  /// Called when the Rive Artboard is initialized by RiveAnimation widget
  void onRiveInit(Artboard artboard) {
    try {
      _artboard = artboard;

      // Try finding the dedicated state machine or fallback to the first available
      StateMachineController? controller = StateMachineController.fromArtboard(
        artboard,
        stateMachineName,
      );

      controller ??= StateMachineController.fromArtboard(
        artboard,
        artboard.stateMachines.isNotEmpty
            ? artboard.stateMachines.first.name
            : 'State Machine 1',
      );

      if (controller != null) {
        artboard.addController(controller);
        _stateMachineController = controller;

        // Bind all required inputs per specification:
        // 1. MoveX: Character X position (-1.0 to 1.0 or -100 to 100)
        _moveXInput = controller.findInput<double>('MoveX');

        // 2. StunTrigger: Fired when bale hits character to activate ragdoll/stun
        final stunInput = controller.findInput<bool>('StunTrigger');
        if (stunInput is SMITrigger) {
          _stunTrigger = stunInput;
        }

        // 3. CatchSuccess: Fired when bale is successfully caught
        final catchInput = controller.findInput<bool>('CatchSuccess') ??
            controller.findInput<bool>('CatchTrigger');
        if (catchInput is SMITrigger) {
          _catchSuccessTrigger = catchInput;
        }

        // 4. HealthValue: Current health (0.0 to 100.0)
        _healthValueInput = controller.findInput<double>('HealthValue') ??
            controller.findInput<double>('Health');

        // 5. GameMode: 0 for Arcade Mode, 1 for Puzzle/Jenga Mode
        _gameModeInput = controller.findInput<double>('GameMode');

        // 6. TrailerWobble: Amount of trailer shake applied during bumpy terrain
        _trailerWobbleInput = controller.findInput<double>('TrailerWobble') ??
            controller.findInput<double>('WobbleIntensity');

        // 7. 3D Camera & Lighting Script Node Inputs:
        _cameraPitchInput = controller.findInput<double>('CameraPitch') ??
            controller.findInput<double>('Pitch');
        _cameraFovInput = controller.findInput<double>('CameraFOV') ??
            controller.findInput<double>('FOV');
        _keyLightIntensityInput =
            controller.findInput<double>('KeyLightIntensity');
        _shadowDarknessInput = controller.findInput<double>('ShadowDarkness');
        _baleLandingXInput = controller.findInput<double>('BaleLandingX');
        _baleLandingZInput = controller.findInput<double>('BaleLandingZ');

        // Apply Cozy 3D Camera & Lighting defaults (-55° Pitch, 45° FOV, Soft Shadows)
        _apply3DCameraAndLightingDefaults();

        _isRiveAvailable = true;
        _isInitialized = true;
        _errorMessage = null;
        debugPrint(
          '[RiveBridge] Bound state machine & 3D Camera (Pitch: ${_sceneConfig.pitchDegrees}°, FOV: ${_sceneConfig.fovDegrees}°)',
        );
      } else {
        debugPrint('[RiveBridge] No state machine controller found in artboard.');
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('[RiveBridge] Error initializing Rive artboard: $e');
    }
    notifyListeners();
  }

  void _apply3DCameraAndLightingDefaults() {
    _cameraPitchInput?.value = _sceneConfig.pitchDegrees; // -55.0°
    _cameraFovInput?.value = _sceneConfig.fovDegrees; // 45.0°
    _keyLightIntensityInput?.value = _sceneConfig.keyLightIntensity; // 1.25
    _shadowDarknessInput?.value = _sceneConfig.shadowDarkness; // 0.34
  }

  /// Updates the 3D Camera Pitch, Yaw, FOV, and Zoom
  void updateCamera3D({
    double? pitchDegrees,
    double? yawDegrees,
    double? fovDegrees,
    double? zoomScale,
    double? wagonCenterYRatio,
  }) {
    _sceneConfig = Rive3DSceneConfig(
      pitchDegrees: pitchDegrees ?? _sceneConfig.pitchDegrees,
      yawDegrees: yawDegrees ?? _sceneConfig.yawDegrees,
      fovDegrees: fovDegrees ?? _sceneConfig.fovDegrees,
      cameraPosition: _sceneConfig.cameraPosition,
      keyLightDirection: _sceneConfig.keyLightDirection,
      keyLightColor: _sceneConfig.keyLightColor,
      keyLightIntensity: _sceneConfig.keyLightIntensity,
      ambientLightColor: _sceneConfig.ambientLightColor,
      shadowDarkness: _sceneConfig.shadowDarkness,
      shadowSoftness: _sceneConfig.shadowSoftness,
      zoomScale: zoomScale ?? _sceneConfig.zoomScale,
      wagonCenterYRatio: wagonCenterYRatio ?? _sceneConfig.wagonCenterYRatio,
    );
    _apply3DCameraAndLightingDefaults();
    notifyListeners();
  }

  /// Smoothly interpolates the 3D camera between normal 3rd-person road view (0.0)
  /// and diagonal isometric wagon-focus view (1.0).
  void setCameraIsometricBlend(double blend) {
    _sceneConfig = Rive3DSceneConfig.lerp(
      Rive3DSceneConfig.cozyFarmDefault(),
      Rive3DSceneConfig.wagonIsometricFocus(),
      blend,
    );
    _apply3DCameraAndLightingDefaults();
  }

  /// Syncs the incoming bale's 3D landing target coordinates with the Rive 3D scene
  void syncBaleLandingTarget(double targetX, double targetZ) {
    _baleLandingXInput?.value = targetX;
    _baleLandingZInput?.value = targetZ;
  }

  /// Updates MoveX input (-1.0 to +1.0)
  void setMoveX(double normalizedX) {
    if (_moveXInput != null) {
      _moveXInput!.value = normalizedX;
    }
  }

  /// Fires the StunTrigger input to activate ragdoll animation
  void triggerStun() {
    if (_stunTrigger != null) {
      _stunTrigger!.fire();
      debugPrint('[RiveBridge] StunTrigger fired!');
    }
  }

  /// Fires the CatchSuccess trigger
  void triggerCatchSuccess() {
    if (_catchSuccessTrigger != null) {
      _catchSuccessTrigger!.fire();
      debugPrint('[RiveBridge] CatchSuccess fired!');
    }
  }

  /// Updates current health (0.0 to 100.0)
  void setHealth(double health) {
    if (_healthValueInput != null) {
      _healthValueInput!.value = health.clamp(0.0, 100.0);
    }
  }

  /// Updates current game mode (0.0 = Arcade, 1.0 = Puzzle)
  void setGameMode(double mode) {
    if (_gameModeInput != null) {
      _gameModeInput!.value = mode;
    }
  }

  /// Updates trailer wobble intensity (0.0 to 1.0)
  void setTrailerWobble(double wobble) {
    if (_trailerWobbleInput != null) {
      _trailerWobbleInput!.value = wobble.clamp(0.0, 1.0);
    }
  }

  @override
  void dispose() {
    _stateMachineController?.dispose();
    super.dispose();
  }
}
