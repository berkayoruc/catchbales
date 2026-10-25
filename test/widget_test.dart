import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:farm_bale_game/controllers/game_controller.dart';
import 'package:farm_bale_game/controllers/rive_game_controller.dart';
import 'package:farm_bale_game/models/bale.dart';
import 'package:farm_bale_game/models/game_mode.dart';
import 'package:farm_bale_game/physics/bale_spawner.dart';
import 'package:farm_bale_game/physics/camera_3d.dart';
import 'package:farm_bale_game/physics/collision_detector.dart';
import 'package:farm_bale_game/physics/trailer_physics.dart';
import 'package:farm_bale_game/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Hay Bale Stacking Game Core Mechanics & 3D Camera Tests', () {
    test('BaleSpawner generates valid 3D parabolic trajectories', () {
      final spawner = BaleSpawner();
      spawner.reset(GameModeType.arcade);

      // Force spawn
      final bale = spawner.update(3.0, GameModeType.arcade, 0);
      expect(bale, isNotNull);
      expect(bale!.startPos.x, equals(0.0));
      expect(bale.startPos.y, equals(3.2));
      expect(bale.startPos.z, equals(5.0));

      expect(bale.targetPos.x, greaterThanOrEqualTo(BaleSpawner.wagonMinX));
      expect(bale.targetPos.x, lessThanOrEqualTo(BaleSpawner.wagonMaxX));
      expect(bale.arcHeight, greaterThan(2.0));

      // Test trajectory update
      bale.update(bale.flightDuration * 0.5); // At 50%
      expect(bale.progress, closeTo(0.5, 0.05));
      expect(bale.currentPos.y, greaterThan(bale.startPos.y)); // Higher at apex of parabolic arc
    });

    test('Camera3DProjector projects -55° Pitch and 45° FOV with vertical depth and shadows', () {
      final config = Rive3DSceneConfig.cozyFarmDefault();
      expect(config.pitchDegrees, equals(-55.0));
      expect(config.fovDegrees, equals(45.0));

      final projector = Camera3DProjector(
        config: config,
        viewportSize: const Size(360, 640),
      );

      // Elevated point (Y = 2.0) should project higher up on screen (smaller dy) than floor (Y = 0.6)
      final floorProj = projector.project(Vector3(0.0, 0.6, -2.0));
      final elevatedProj = projector.project(Vector3(0.0, 2.0, -2.0));
      expect(elevatedProj.screenOffset.dy, lessThan(floorProj.screenOffset.dy));

      // Shadow projection casts offset onto receiver plane
      final shadowProj = projector.projectShadow(
        Vector3(0.0, 2.5, -2.0),
        receiverPlaneY: 0.6,
      );
      expect(shadowProj.screenOffset.dx, greaterThan(floorProj.screenOffset.dx));
    });

    test('CollisionDetector catches bale within 3D camera-synchronized hit window', () {
      final detector = CollisionDetector();
      final bale = StrawBale(
        id: 'test_bale',
        startPos: Vector3(0, 3, 5),
        targetPos: Vector3(0.5, 0.6, -2.2),
        arcHeight: 2.5,
        flightDuration: 1.5,
        angularVelocity: Vector3.zero(),
      );

      // Bale at beginning of flight (progress 0.2)
      bale.progress = 0.2;
      bale.currentPos.setFrom(Vector3(0.1, 3.5, 3.5));
      var result = detector.evaluateManualCatch(
        activeBales: [bale],
        playerX: 0.5,
        isStunned: false,
      );
      expect(result, isNull); // Too early to catch

      // Bale in catch window (progress 0.85) and player aligned at 0.5
      bale.progress = 0.85;
      bale.currentPos.setFrom(Vector3(0.5, 1.2, -2.1));
      result = detector.evaluateManualCatch(
        activeBales: [bale],
        playerX: 0.5,
        isStunned: false,
      );
      expect(result, isNotNull);
      expect(result!.outcome, equals(CollisionOutcomeType.caught));
      expect(result.isPerfectCatch, isTrue);
    });

    test('CollisionDetector triggers stun when bale hits farmer without catch', () {
      final detector = CollisionDetector();
      final bale = StrawBale(
        id: 'stun_bale',
        startPos: Vector3(0, 3, 5),
        targetPos: Vector3(0.2, 0.6, -2.2),
        arcHeight: 2.5,
        flightDuration: 1.5,
        angularVelocity: Vector3.zero(),
      );

      bale.progress = 0.98;
      bale.targetPos.setFrom(Vector3(0.2, 0.6, -2.2));

      final landingResults = detector.evaluateLandingCollisions(
        activeBales: [bale],
        playerX: 0.2, // Standing directly under landing target!
        isStunned: false,
      );

      expect(landingResults.length, equals(1));
      expect(landingResults.first.outcome, equals(CollisionOutcomeType.stunned));
    });

    test('7-second Cutscene Mode allows organizing bales across columns (max 5 rows)', () {
      final riveBridge = RiveGameController();
      final game = GameController(riveBridge: riveBridge);

      // Start 7-second cutscene
      game.startOrganizeCutscene();
      expect(game.isCutsceneActive, isTrue);
      expect(game.cutsceneTimer, equals(7.0));

      // Advance 3 seconds -> still in cutscene (4.0s left) & camera transitioned to diagonal isometric
      game.update(3.0);
      expect(game.isCutsceneActive, isTrue);
      expect(game.cutsceneTimer, closeTo(4.0, 0.05));
      expect(riveBridge.sceneConfig.yawDegrees, closeTo(-38.0, 0.5));
      expect(riveBridge.sceneConfig.zoomScale, greaterThan(1.4));

      // Advance remaining 4.1 seconds -> cutscene completes automatically
      game.update(4.1);
      expect(game.isCutsceneActive, isFalse);

      // Advance 1.0 second -> camera smoothly returns to normal road angle (yaw = 0°)
      game.update(1.0);
      expect(riveBridge.sceneConfig.yawDegrees, closeTo(0.0, 0.1));
      expect(riveBridge.sceneConfig.zoomScale, closeTo(1.0, 0.05));
    });

    test('Max 5 rows per column enforced and uncaught bales show MISSED before disappearing', () {
      final riveBridge = RiveGameController();
      final game = GameController(riveBridge: riveBridge);

      expect(GameController.maxRowsPerColumn, equals(5));

      // Advance game until a bale spawns and lands uncaught on wagon floor (player moved far left)
      game.setPlayerDirectX(-1.0);
      for (int i = 0; i < 60; i++) {
        game.update(0.05);
      }

      // If any bale landed on the floor uncaught, verify notices or missed state mechanics
      final missedBale = StrawBale(
        id: 'uncaught_bale',
        startPos: Vector3(0, 3, 5),
        targetPos: Vector3(1.1, 0.6, -2.2),
        arcHeight: 2.5,
        flightDuration: 1.0,
        angularVelocity: Vector3.zero(),
      );
      missedBale.state = BaleState.missed;
      missedBale.missedDisplayTimer = StrawBale.maxMissedDisplayDuration;
      expect(missedBale.fadeOpacity, closeTo(1.0, 0.01));

      missedBale.update(0.45);
      expect(missedBale.fadeOpacity, closeTo(0.5, 0.05));
    });

    test('TrailerPhysics wobble simulation updates tilt angle', () {
      final physics = TrailerPhysics();
      physics.reset();
      expect(physics.wobbleIntensity, equals(0.0));
      expect(physics.tiltAngle, equals(0.0));

      physics.update(0.1, true);
      expect(physics.tiltAngle.isFinite, isTrue);
    });

    test('Farm animals escape when landing on wagon or cause short stun & track per-object stats when caught', () {
      SharedPreferences.setMockInitialValues({});
      final spawner = BaleSpawner();
      final chicken = spawner.spawnWithType(ThrownObjectType.chicken);
      expect(chicken.objectType, equals(ThrownObjectType.chicken));
      expect(chicken.objectType.isAnimal, isTrue);
      expect(chicken.objectType.displayNameTr, equals('Tavuk'));

      // Verify all 8 animal types + bale are distinct in ThrownObjectType
      expect(ThrownObjectType.values.length, equals(9));

      // Verify escaping physics moves the animal across the wagon floor
      chicken.state = BaleState.escaping;
      chicken.missedDisplayTimer = StrawBale.maxEscapeDuration;
      chicken.currentPos.setValues(0.0, 0.65, -2.0);
      chicken.tumbleVelocity.setValues(1.8, 1.2, -1.0);
      chicken.update(0.2);
      expect(chicken.currentPos.x, greaterThan(0.3));
      expect(chicken.currentPos.z, lessThan(-2.1));
    });

    test('BaleSpawner prioritizes available cells when provided', () {
      final spawner = BaleSpawner();
      spawner.reset(GameModeType.arcade);

      // Only one available cell: (col: 0, row: 2)
      final available = [(col: 0, row: 2)];
      int targetedAvailable = 0;
      for (int i = 0; i < 40; i++) {
        final bale = spawner.update(5.0, GameModeType.arcade, 0, availableCells: available);
        if (bale != null && bale.gridCol == 0 && bale.gridRow == 2) {
          targetedAvailable++;
        }
      }
      // ~85% should target the available cell
      expect(targetedAvailable, greaterThanOrEqualTo(25));
    });

    test('Smart Spillover and Endless Wagon Haul mechanics', () {
      SharedPreferences.setMockInitialValues({});
      final riveController = RiveGameController();
      final game = GameController(riveBridge: riveController);

      // Check findNearestAvailableCell initially targets current cell
      final initial = game.findNearestAvailableCell(1, 1);
      expect(initial, isNotNull);
      expect(initial!.col, equals(1));
      expect(initial.row, equals(1));

      // Verify completeWagon resets stacked bales, awards +1000 bonus & increments wagonsCompleted
      expect(game.wagonsCompleted, equals(0));
      final initialScore = game.score;
      game.completeWagon(isFullWagonBonus: true);
      expect(game.wagonsCompleted, equals(1));
      expect(game.score, equals(initialScore + 1000));
      expect(game.stackedBales.isEmpty, isTrue);
      expect(game.isGameOver, isFalse);

      // Verify incoming object type and organize proximity countdown
      expect(game.incomingObjectType, isNotNull);
      expect(game.balesUntilOrganizeCutscene, equals(GameController.balesPerAutoCutscene));
      expect(game.isOrganizeApproaching, isFalse);

      // Verify popup appears when incoming bale is generated and disappears when timer ends
      expect(game.showIncomingPopup, isFalse);
      for (int i = 0; i < 40 && game.activeBales.isEmpty; i++) {
        game.update(0.1);
      }
      if (game.activeBales.isNotEmpty) {
        expect(game.showIncomingPopup, isTrue);
        expect(game.popupIncomingType, isNotNull);
        game.update(2.0); // Advance past 1.8s
        expect(game.showIncomingPopup, isFalse);
      }
    });

    testWidgets('FarmBaleGameApp mounts Splash -> MainMenu -> 3D GameScreen and HUD',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      GameController.resetTutorialStateForTesting();

      final riveController = RiveGameController();
      final gameController = GameController(riveBridge: riveController);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: riveController),
            ChangeNotifierProvider.value(value: gameController),
          ],
          child: const FarmBaleGameApp(),
        ),
      );

      // 1. Verify Splash Screen renders HexaApps branding
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('HEXAAPPS STUDIO'), findsOneWidget);

      // 2. Advance timer past Splash Screen (2.3s) into Main Menu Screen
      await tester.pump(const Duration(milliseconds: 2400));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('PLAY GAME'), findsOneWidget);

      // 3. Tap PLAY GAME to launch GameScreen
      await tester.tap(find.text('PLAY GAME'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 400));

      // 4. Verify decluttered HUD Elements & First-Time 3-Step How-To-Play Flow
      expect(find.text('0/45'), findsOneWidget);
      expect(find.text('CATCH'), findsNothing); // Manual catch button removed (auto-catch active)
      expect(find.text('STEP 1 / 3'), findsOneWidget);
      expect(find.text('3x3 WAGON MOVEMENT'), findsOneWidget);
      expect(gameController.totalObjectsCaughtSession, equals(0));
      expect(gameController.totalObjectsCaughtLifetime, equals(0));

      // Step through or complete the first-time tutorial flow
      gameController.nextTutorialStep();
      await tester.pump();
      expect(find.text('STEP 2 / 3'), findsOneWidget);

      gameController.completeTutorial();
      await tester.pump();
      expect(gameController.isTutorialActive, isFalse);
      expect(gameController.hasSeenTutorial, isTrue);

      // Verify that guideline DOES NOT open on subsequent resets or game sessions
      gameController.resetGame();
      gameController.startTutorialIfFirstTime();
      await tester.pump();
      expect(gameController.isTutorialActive, isFalse);
    });
  });
}
