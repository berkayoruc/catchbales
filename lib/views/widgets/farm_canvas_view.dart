import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import '../../controllers/game_controller.dart';
import '../../models/bale.dart';
import '../../models/stack_slot.dart';
import '../../physics/bale_spawner.dart';
import '../../physics/camera_3d.dart';
import '../../utils/farm_theme.dart';

/// Renders a Cozy Low-Poly 3D Isometric / 3rd-Person Perspective (-55° Pitch, 45° FOV)
/// scene featuring warm directional sunlight, soft shadows, scrolling low-poly trees,
/// 3D wooden fences, golden wheat fields, 3D tractor, baler, wooden wagon with
/// visible interior walls, 3D stacked bales, farmer character, and parabolic flying bales.
class FarmCanvasView extends StatefulWidget {
  final GameController game;
  final bool isMenuPreview;

  const FarmCanvasView({
    super.key,
    required this.game,
    this.isMenuPreview = false,
  });

  @override
  State<FarmCanvasView> createState() => _FarmCanvasViewState();
}

class _FarmCanvasViewState extends State<FarmCanvasView>
    with SingleTickerProviderStateMixin {
  late AnimationController _previewController;
  double _previewScrollZ = 0.0;
  double _previewAnimTime = 0.0;

  @override
  void initState() {
    super.initState();
    _previewController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    if (widget.isMenuPreview) {
      _previewController.repeat();
      _previewController.addListener(() {
        if (mounted) {
          setState(() {
            _previewScrollZ += 0.055;
            _previewAnimTime += 0.016;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _previewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double scrollZ =
        widget.isMenuPreview ? _previewScrollZ : widget.game.worldScrollZ;
    final double animT =
        widget.isMenuPreview ? _previewAnimTime : widget.game.animTime;

    return ClipRect(
      child: CustomPaint(
        painter: FarmScene3DPainter(
          game: widget.game,
          worldScrollZ: scrollZ,
          animTime: animT,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class FarmScene3DPainter extends CustomPainter {
  final GameController game;
  final double worldScrollZ;
  final double animTime;

  // Surface normals for 3D low-poly directional lighting
  static final Vector3 _normalTop = Vector3(0.0, 1.0, 0.0);
  static final Vector3 _normalFront = Vector3(0.0, 0.2, -1.0);
  static final Vector3 _normalLeft = Vector3(-1.0, 0.2, 0.0);
  static final Vector3 _normalRight = Vector3(1.0, 0.1, 0.0);
  static final Vector3 _normalInteriorLeft = Vector3(1.0, 0.3, 0.0);
  static final Vector3 _normalInteriorRight = Vector3(-1.0, 0.3, 0.0);

  FarmScene3DPainter({
    required this.game,
    required this.worldScrollZ,
    required this.animTime,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cam = Camera3DProjector(
      config: game.riveBridge.sceneConfig,
      viewportSize: size,
    );

    // 1. Draw Cozy Pasture Terrain, Golden Wheat Fields & Perspective Dirt Road
    _drawTerrainAndWheatFields(canvas, size, cam);

    // 2. Draw Scrolling 3D Wooden Fences & Low-Poly Trees (Back-to-Front Z order)
    _drawEnvironmentProps3D(canvas, cam);

    // 3. Draw Tow Hitches connecting Tractor -> Baler -> Wagon
    _drawTowConnections(canvas, cam);

    // 4. Draw 3D Red Tractor (Z ≈ 6.4) with Soft Directional Shadows
    _drawTractor3D(canvas, cam);

    // 5. Draw 3D Baler Machine (Z ≈ 3.9) with Ejection Chute & Shadows
    _drawBaler3D(canvas, cam);

    // 6. Draw 3D Wooden Wagon, Interior Walls, Stacked Bales & Farmer
    _drawWagonAndContents3D(canvas, cam);

    // 6b. Draw Hitched Full Wagons attached to rear tailgate in tractor train convoy
    if (game.wagonsCompleted > 0) {
      _drawHitchedWagons3D(canvas, cam);
    }

    // 7. Draw 3D Parabolic Flying Bales, Ground/Wagon Shadows & Landing Target Rings
    _drawFlyingBales3D(canvas, cam);

    // 8. Draw Warm Golden Sunlight Atmosphere Overlay
    _drawSunlightAtmosphere(canvas, size);

    // 9. Draw Floating Score & Combo Notifications
    _drawFloatingNotices3D(canvas, cam);
  }

  /// Draws the lush meadow, golden wheat fields on both sides, and continuous 3D perspective dirt road.
  void _drawTerrainAndWheatFields(
    Canvas canvas,
    Size size,
    Camera3DProjector cam,
  ) {
    const double zFar = 28.0;
    const double zNear = -12.0;

    // Base lush farm meadow gradient (richer emerald in distance, warm sunlit green in foreground)
    final Rect fullRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final Paint meadowPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF529416),
          Color(0xFF74B31B),
          Color(0xFF8AC926),
        ],
        stops: [0.0, 0.45, 1.0],
      ).createShader(fullRect);
    canvas.drawRect(fullRect, meadowPaint);

    // Golden Wheat Fields on Left and Right (continuous from zFar to zNear)
    _drawWheatFieldSide(canvas, cam, isLeft: true);
    _drawWheatFieldSide(canvas, cam, isLeft: false);

    // Soft grassy road shoulder border (continuous from zFar = 22.0 to zNear = -9.0)
    final pShoulderFarL = cam.project(Vector3(-2.18, 0.0, zFar)).screenOffset;
    final pShoulderFarR = cam.project(Vector3(2.18, 0.0, zFar)).screenOffset;
    final pShoulderNearR = cam.project(Vector3(2.18, 0.0, zNear)).screenOffset;
    final pShoulderNearL = cam.project(Vector3(-2.18, 0.0, zNear)).screenOffset;

    final Path shoulderPath = Path()
      ..moveTo(pShoulderFarL.dx, pShoulderFarL.dy)
      ..lineTo(pShoulderFarR.dx, pShoulderFarR.dy)
      ..lineTo(pShoulderNearR.dx, pShoulderNearR.dy)
      ..lineTo(pShoulderNearL.dx, pShoulderNearL.dy)
      ..close();
    canvas.drawPath(
      shoulderPath,
      Paint()..color = const Color(0xFF99B83C),
    );

    // 3D Perspective Dirt Road from zFar = 22.0 to zNear = -9.0
    final pFarLeft = cam.project(Vector3(-1.95, 0.0, zFar)).screenOffset;
    final pFarRight = cam.project(Vector3(1.95, 0.0, zFar)).screenOffset;
    final pNearRight = cam.project(Vector3(1.95, 0.0, zNear)).screenOffset;
    final pNearLeft = cam.project(Vector3(-1.95, 0.0, zNear)).screenOffset;

    final Path roadPath = Path()
      ..moveTo(pFarLeft.dx, pFarLeft.dy)
      ..lineTo(pFarRight.dx, pFarRight.dy)
      ..lineTo(pNearRight.dx, pNearRight.dy)
      ..lineTo(pNearLeft.dx, pNearLeft.dy)
      ..close();

    final Paint roadPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFB58B52),
          FarmTheme.dirtPath,
          const Color(0xFFCCA46B),
        ],
      ).createShader(fullRect);
    canvas.drawPath(roadPath, roadPaint);

    // Continuous 3D wheel ruts along the road
    final Paint rutPaint = Paint()
      ..color = FarmTheme.dirtPathDark.withValues(alpha: 0.36)
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke;

    for (final double tireTrackX in [-1.12, 1.12]) {
      final trackFar = cam.project(Vector3(tireTrackX, 0.0, zFar)).screenOffset;
      final trackNear = cam.project(Vector3(tireTrackX, 0.0, zNear)).screenOffset;
      canvas.drawLine(trackFar, trackNear, rutPaint);
    }

    // Regular, seamless scrolling road texture strips & pebbles (period = 1.4 world units)
    const double roadStep = 1.4;
    final double roadOffset = worldScrollZ % roadStep;
    final int baseRoadIndex = (worldScrollZ / roadStep).floor();

    final Paint treadPaint = Paint()
      ..color = FarmTheme.dirtPathDark.withValues(alpha: 0.25)
      ..strokeWidth = 2.2;
    final Paint pebblePaint = Paint()
      ..color = FarmTheme.dirtPathDark.withValues(alpha: 0.44);

    for (int slot = 0; slot < 26; slot++) {
      final double z = 25.2 - (slot * roadStep + roadOffset);
      final int worldIdx = (baseRoadIndex - slot).abs();

      // Subtle tire-tread cross marks along both wheel tracks
      for (final double trackX in [-1.12, 1.12]) {
        final pL = cam.project(Vector3(trackX - 0.22, 0.01, z)).screenOffset;
        final pR = cam.project(Vector3(trackX + 0.22, 0.01, z)).screenOffset;
        canvas.drawLine(pL, pR, treadPaint);
      }

      // Deterministic road pebbles on left and right edges (never pop or switch sides)
      final double pebbleLeftX = -1.52 + (worldIdx % 3) * 0.08;
      final double pebbleRightX = 1.52 - ((worldIdx + 1) % 3) * 0.08;
      for (final double px in [pebbleLeftX, pebbleRightX]) {
        final proj = cam.project(Vector3(px, 0.01, z));
        canvas.drawOval(
          Rect.fromCenter(
            center: proj.screenOffset,
            width: 14.0 * proj.scale,
            height: 5.5 * proj.scale,
          ),
          pebblePaint,
        );
      }
    }
  }

  /// Draws continuous, regular 3D terraced golden wheat fields on Left and Right.
  void _drawWheatFieldSide(
    Canvas canvas,
    Camera3DProjector cam, {
    required bool isLeft,
  }) {
    const double zFar = 28.0;
    const double zNear = -12.0;
    final double innerX = isLeft ? -2.55 : 2.55;
    final double outerX = isLeft ? -10.5 : 10.5;

    final p1 = cam.project(Vector3(innerX, 0.0, zFar)).screenOffset;
    final p2 = cam.project(Vector3(outerX, 0.0, zFar)).screenOffset;
    final p3 = cam.project(Vector3(outerX, 0.0, zNear)).screenOffset;
    final p4 = cam.project(Vector3(innerX, 0.0, zNear)).screenOffset;

    // Golden soil bed under wheat
    final Path fieldBase = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..lineTo(p4.dx, p4.dy)
      ..close();

    canvas.drawPath(
      fieldBase,
      Paint()..color = const Color(0xFFD4A338).withValues(alpha: 0.85),
    );

    // Continuous, regular 3D golden wheat rows from z = 25.6 down to z = -11.2 (step = 1.6)
    const double wheatStep = 1.6;
    final double wheatOffset = worldScrollZ % wheatStep;
    final int baseWheatIdx = (worldScrollZ / wheatStep).floor();

    final double xStart = isLeft ? -2.75 : 2.75;
    final double xEnd = isLeft ? -7.2 : 7.2;
    final double minX = math.min(xStart, xEnd);
    final double maxX = math.max(xStart, xEnd);

    for (int slot = 0; slot < 23; slot++) {
      final double z = 25.6 - (slot * wheatStep + wheatOffset);
      final int worldRowIdx = baseWheatIdx - slot;
      final double sway = math.sin(animTime * 2.2 + worldRowIdx * 0.7) * 0.05;

      _drawExtruded3DBox(
        canvas,
        cam,
        minCorner: Vector3(minX, 0.0, z - 0.30),
        maxCorner: Vector3(maxX + sway, 0.34, z + 0.30),
        baseColor: const Color(0xFFF4B942),
        topHighlightColor: const Color(0xFFFFE082),
      );
    }
  }

  /// Draws continuous, regular 3D wooden fences and low-poly roadside trees
  /// on both Left and Right sides from far horizon (+Z) to near foreground (-Z).
  void _drawEnvironmentProps3D(Canvas canvas, Camera3DProjector cam) {
    // 1. Continuous 3D Wooden Fence Rails & Posts on Left (-2.22) and Right (+2.22)
    const double fenceStep = 2.0;
    final double fenceOffset = worldScrollZ % fenceStep;

    for (final double fenceX in [-2.22, 2.22]) {
      // Slots 0..18 go strictly from far Z (26.0) to near Z (-10.0) -> Painter's order!
      for (int slot = 0; slot < 19; slot++) {
        final double zPost = 26.0 - (slot * fenceStep + fenceOffset);
        final double zNext = zPost + fenceStep;

        // Soft shadow of rails on ground
        final s1 = cam.projectShadow(Vector3(fenceX, 0.55, zPost)).screenOffset;
        final s2 = cam.projectShadow(Vector3(fenceX, 0.55, zNext)).screenOffset;
        canvas.drawLine(
          s1,
          s2,
          Paint()
            ..color = Colors.black.withValues(alpha: 0.18)
            ..strokeWidth = 5.0
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0),
        );

        // Lower 3D wooden rail (Y: 0.24..0.34)
        _drawExtruded3DBox(
          canvas,
          cam,
          minCorner: Vector3(fenceX - 0.04, 0.24, zPost),
          maxCorner: Vector3(fenceX + 0.04, 0.34, zNext),
          baseColor: FarmTheme.wagonWoodLight,
        );

        // Upper 3D wooden rail (Y: 0.52..0.62)
        _drawExtruded3DBox(
          canvas,
          cam,
          minCorner: Vector3(fenceX - 0.04, 0.52, zPost),
          maxCorner: Vector3(fenceX + 0.04, 0.62, zNext),
          baseColor: FarmTheme.wagonWoodLight,
        );

        // 3D Vertical Fence Post at zPost (Y: 0.0..0.78)
        _drawSoftGroundShadow(
          canvas,
          cam,
          worldCenter: Vector3(fenceX, 0.4, zPost),
          radiusX: 0.18,
          radiusZ: 0.18,
          receiverY: 0.0,
        );
        _drawExtruded3DBox(
          canvas,
          cam,
          minCorner: Vector3(fenceX - 0.08, 0.0, zPost - 0.08),
          maxCorner: Vector3(fenceX + 0.08, 0.78, zPost + 0.08),
          baseColor: FarmTheme.wagonWoodDark,
          topHighlightColor: const Color(0xFFD4A373),
        );
      }
    }

    // 2. Continuous, Regular Low-Poly 3D Trees on BOTH Left (-3.12) and Right (+3.12)
    // Slots 0..14 go strictly from far Z (26.0) down to near Z (-10.4) with fixed step = 2.6.
    // Each tree's identity (`worldTreeIdx`) moves with the tree so it NEVER pops or switches sides!
    const double treeStep = 2.6;
    final double treeOffset = worldScrollZ % treeStep;
    final int baseTreeIdx = (worldScrollZ / treeStep).floor();

    for (int slot = 0; slot < 15; slot++) {
      final double z = 26.0 - (slot * treeStep + treeOffset);
      final int worldTreeIdx = (baseTreeIdx - slot).abs();

      // Left Roadside Tree
      _drawLowPolyTree3D(
        canvas,
        cam,
        basePos: Vector3(-3.12, 0.0, z),
        heightScale: 1.0 + (worldTreeIdx % 2) * 0.08,
        isWarmAutumnTint: worldTreeIdx % 4 == 0,
      );

      // Right Roadside Tree (regularly paired on the right side)
      _drawLowPolyTree3D(
        canvas,
        cam,
        basePos: Vector3(3.12, 0.0, z),
        heightScale: 1.0 + ((worldTreeIdx + 1) % 2) * 0.08,
        isWarmAutumnTint: (worldTreeIdx + 2) % 4 == 0,
      );
    }
  }

  /// Renders a multi-tiered 3D Low-Poly Tree with faceted directional lighting and ground shadow.
  void _drawLowPolyTree3D(
    Canvas canvas,
    Camera3DProjector cam, {
    required Vector3 basePos,
    double heightScale = 1.0,
    bool isWarmAutumnTint = false,
  }) {
    // 1. Soft directional ground shadow
    _drawSoftGroundShadow(
      canvas,
      cam,
      worldCenter: Vector3(basePos.x, 0.9 * heightScale, basePos.z),
      radiusX: 0.65 * heightScale,
      radiusZ: 0.55 * heightScale,
      receiverY: 0.0,
    );

    // 2. 3D Wooden Tree Trunk
    _drawExtruded3DBox(
      canvas,
      cam,
      minCorner: Vector3(basePos.x - 0.14, 0.0, basePos.z - 0.14),
      maxCorner: Vector3(basePos.x + 0.14, 0.65 * heightScale, basePos.z + 0.14),
      baseColor: const Color(0xFF7F4F24),
    );

    // 3. Three stacked 3D Low-Poly Pyramid/Cone Foliage Tiers
    final Color baseLeaf = isWarmAutumnTint
        ? const Color(0xFFE09F3E)
        : const Color(0xFF4F9D22);
    final Color sunlitLeaf = cam.shadeColor(baseLeaf, _normalLeft);
    final Color midLeaf = cam.shadeColor(baseLeaf, _normalFront);
    final Color shadedLeaf = cam.shadeColor(baseLeaf, _normalRight);

    for (int tier = 0; tier < 3; tier++) {
      final double yBottom = (0.50 + tier * 0.52) * heightScale;
      final double yTop = yBottom + (0.78 - tier * 0.10) * heightScale;
      final double radius = (0.62 - tier * 0.13) * heightScale;

      final pApex = cam.project(Vector3(basePos.x, yTop, basePos.z)).screenOffset;
      final pLeft = cam
          .project(Vector3(basePos.x - radius, yBottom, basePos.z - radius * 0.3))
          .screenOffset;
      final pFront = cam
          .project(Vector3(basePos.x, yBottom, basePos.z - radius))
          .screenOffset;
      final pRight = cam
          .project(Vector3(basePos.x + radius, yBottom, basePos.z - radius * 0.3))
          .screenOffset;

      // Left sunlit facet
      final Path leftFacet = Path()
        ..moveTo(pApex.dx, pApex.dy)
        ..lineTo(pLeft.dx, pLeft.dy)
        ..lineTo(pFront.dx, pFront.dy)
        ..close();
      canvas.drawPath(leftFacet, Paint()..color = sunlitLeaf);

      // Right shaded facet
      final Path rightFacet = Path()
        ..moveTo(pApex.dx, pApex.dy)
        ..lineTo(pFront.dx, pFront.dy)
        ..lineTo(pRight.dx, pRight.dy)
        ..close();
      canvas.drawPath(rightFacet, Paint()..color = shadedLeaf);

      // Subtle facet highlight ridge
      canvas.drawLine(
        pApex,
        pFront,
        Paint()
          ..color = midLeaf.withValues(alpha: 0.7)
          ..strokeWidth = 1.2,
      );
    }
  }

  /// Draws the 3D tow bars connecting Tractor -> Baler -> Wooden Wagon.
  void _drawTowConnections(Canvas canvas, Camera3DProjector cam) {
    // Hitch from Tractor (Z=5.5) to Baler (Z=4.5)
    _drawExtruded3DBox(
      canvas,
      cam,
      minCorner: Vector3(-0.08, 0.45, 4.4),
      maxCorner: Vector3(0.08, 0.56, 5.6),
      baseColor: const Color(0xFF3A3D45),
    );

    // Hitch from Baler (Z=3.0) to Wagon Front Wall (Z=-0.8)
    _drawExtruded3DBox(
      canvas,
      cam,
      minCorner: Vector3(-0.08, 0.48, -0.85),
      maxCorner: Vector3(0.08, 0.58, 3.1),
      baseColor: const Color(0xFF3A3D45),
    );
  }

  /// Draws the 3D Red Farm Tractor at Z = 6.2 with 3D wheels, engine hood, cabin, and exhaust.
  void _drawTractor3D(Canvas canvas, Camera3DProjector cam) {
    const double tz = 6.2;
    final double engineBob = math.sin(animTime * 14.0) * 0.03;

    // 1. Soft directional shadow under tractor
    _drawSoftGroundShadow(
      canvas,
      cam,
      worldCenter: Vector3(0.0, 0.7, tz),
      radiusX: 1.25,
      radiusZ: 1.35,
      receiverY: 0.0,
    );

    // 2. Front & Rear Left Wheels (X < 0)
    _drawWheel3D(
      canvas,
      cam,
      center: Vector3(-0.88, 0.38, tz + 0.75),
      radius: 0.38,
      width: 0.24,
    );
    _drawWheel3D(
      canvas,
      cam,
      center: Vector3(-0.95, 0.62, tz - 0.35),
      radius: 0.62,
      width: 0.34,
    );

    // 3. Front & Rear Right Wheels (X > 0)
    _drawWheel3D(
      canvas,
      cam,
      center: Vector3(0.88, 0.38, tz + 0.75),
      radius: 0.38,
      width: 0.24,
    );
    _drawWheel3D(
      canvas,
      cam,
      center: Vector3(0.95, 0.62, tz - 0.35),
      radius: 0.62,
      width: 0.34,
    );

    // 4. 3D Red Engine Hood & Chassis (Z: tz to tz + 1.15)
    _drawExtruded3DBox(
      canvas,
      cam,
      minCorner: Vector3(-0.62, 0.42 + engineBob, tz - 0.1),
      maxCorner: Vector3(0.62, 1.28 + engineBob, tz + 1.15),
      baseColor: FarmTheme.tractorRed,
      topHighlightColor: const Color(0xFFFF5C67),
    );

    // 5. Rear Fenders over big tires
    _drawExtruded3DBox(
      canvas,
      cam,
      minCorner: Vector3(-1.05, 0.95 + engineBob, tz - 0.78),
      maxCorner: Vector3(-0.65, 1.18 + engineBob, tz + 0.05),
      baseColor: FarmTheme.tractorRedDark,
    );
    _drawExtruded3DBox(
      canvas,
      cam,
      minCorner: Vector3(0.65, 0.95 + engineBob, tz - 0.78),
      maxCorner: Vector3(1.05, 1.18 + engineBob, tz + 0.05),
      baseColor: FarmTheme.tractorRedDark,
    );

    // 6. 3D Tractor Cabin Lower Body & Glass Enclosure
    _drawExtruded3DBox(
      canvas,
      cam,
      minCorner: Vector3(-0.68, 0.50 + engineBob, tz - 0.78),
      maxCorner: Vector3(0.68, 1.35 + engineBob, tz - 0.02),
      baseColor: FarmTheme.tractorRedDark,
    );

    // Tinted 3D Cabin Glass Block
    _drawExtruded3DBox(
      canvas,
      cam,
      minCorner: Vector3(-0.60, 1.35 + engineBob, tz - 0.72),
      maxCorner: Vector3(0.60, 1.98 + engineBob, tz - 0.06),
      baseColor: const Color(0xFF90E0EF).withValues(alpha: 0.78),
      topHighlightColor: const Color(0xFFCAF0F8),
    );

    // 7. 3D Tractor Cabin Roof Slab (Y: 1.98..2.14)
    _drawExtruded3DBox(
      canvas,
      cam,
      minCorner: Vector3(-0.72, 1.98 + engineBob, tz - 0.80),
      maxCorner: Vector3(0.72, 2.14 + engineBob, tz + 0.02),
      baseColor: FarmTheme.tractorRed,
      topHighlightColor: const Color(0xFFFF6B6B),
    );

    // 8. 3D Exhaust Stack & Rising Cozy Smoke Puffs
    _drawExtruded3DBox(
      canvas,
      cam,
      minCorner: Vector3(0.42, 1.28 + engineBob, tz + 0.55),
      maxCorner: Vector3(0.54, 2.05 + engineBob, tz + 0.67),
      baseColor: const Color(0xFF2B2D42),
    );

    for (int p = 0; p < 3; p++) {
      final double puffPhase = ((animTime * 1.4 + p * 0.33) % 1.0);
      final Vector3 puffPos = Vector3(
        0.48 + math.sin(puffPhase * 6.0) * 0.12,
        2.15 + puffPhase * 1.1,
        tz + 0.60 - puffPhase * 0.4,
      );
      final projPuff = cam.project(puffPos);
      final double radius = (6.0 + puffPhase * 10.0) * projPuff.scale;
      canvas.drawCircle(
        projPuff.screenOffset,
        radius,
        Paint()..color = Colors.white.withValues(alpha: (1.0 - puffPhase) * 0.55),
      );
    }
  }

  /// Draws the 3D Baling Machine at Z = 3.8 with angled 3D Ejection Chute.
  void _drawBaler3D(Canvas canvas, Camera3DProjector cam) {
    const double bz = 3.85;
    final double vib = math.cos(animTime * 16.0) * 0.02;

    // 1. Soft directional ground shadow
    _drawSoftGroundShadow(
      canvas,
      cam,
      worldCenter: Vector3(0.0, 0.6, bz),
      radiusX: 1.15,
      radiusZ: 1.05,
      receiverY: 0.0,
    );

    // 2. Baler Left & Right Wheels
    _drawWheel3D(
      canvas,
      cam,
      center: Vector3(-0.86, 0.36, bz),
      radius: 0.36,
      width: 0.22,
    );
    _drawWheel3D(
      canvas,
      cam,
      center: Vector3(0.86, 0.36, bz),
      radius: 0.36,
      width: 0.22,
    );

    // 3. Main 3D Baler Compression Chamber (Green & Golden Trim)
    _drawExtruded3DBox(
      canvas,
      cam,
      minCorner: Vector3(-0.74, 0.35 + vib, bz - 0.65),
      maxCorner: Vector3(0.74, 1.32 + vib, bz + 0.65),
      baseColor: const Color(0xFF2D6A4F),
      topHighlightColor: const Color(0xFF52B788),
    );

    // Golden Accent Band on Top of Baler
    _drawExtruded3DBox(
      canvas,
      cam,
      minCorner: Vector3(-0.62, 1.32 + vib, bz - 0.45),
      maxCorner: Vector3(0.62, 1.42 + vib, bz + 0.45),
      baseColor: FarmTheme.goldenStraw,
      topHighlightColor: FarmTheme.sunWarmYellow,
    );

    // 4. 3D Elevated Ejection Chute Hood (angled upward/backward toward the wagon)
    _drawExtruded3DBox(
      canvas,
      cam,
      minCorner: Vector3(-0.36, 1.15 + vib, bz - 1.05),
      maxCorner: Vector3(0.36, 2.25 + vib, bz - 0.35),
      baseColor: const Color(0xFF40916C),
      topHighlightColor: const Color(0xFF74C69D),
    );

    // Chute mouth dark interior opening facing the wagon (-Z)
    final pMouthTL = cam.project(Vector3(-0.28, 2.18 + vib, bz - 1.06)).screenOffset;
    final pMouthTR = cam.project(Vector3(0.28, 2.18 + vib, bz - 1.06)).screenOffset;
    final pMouthBR = cam.project(Vector3(0.28, 1.55 + vib, bz - 1.06)).screenOffset;
    final pMouthBL = cam.project(Vector3(-0.28, 1.55 + vib, bz - 1.06)).screenOffset;

    final Path mouthPath = Path()
      ..moveTo(pMouthTL.dx, pMouthTL.dy)
      ..lineTo(pMouthTR.dx, pMouthTR.dy)
      ..lineTo(pMouthBR.dx, pMouthBR.dy)
      ..lineTo(pMouthBL.dx, pMouthBL.dy)
      ..close();
    canvas.drawPath(mouthPath, Paint()..color = const Color(0xFF1B262C));
  }

  /// Draws the 3D Wooden Wagon with visible 3D side walls, interior planks,
  /// 3D stacked straw bales, and the 3D farmer character.
  void _drawWagonAndContents3D(Canvas canvas, Camera3DProjector cam) {
    final double tilt = game.wagonTilt;
    const double zFront = -0.85;
    const double zBack = -3.35;
    const double xHalf = 1.52;
    const double floorY = BaleSpawner.wagonFloorY; // 0.60
    const double wallTopY = floorY + BaleSpawner.wagonWallHeight; // 1.32

    // Helper to apply wagon roll tilt around wagon center (0, floorY, -2.1)
    Vector3 tiltPoint(double x, double y, double z) {
      final double dy = y - floorY;
      final double rx = x * math.cos(tilt) - dy * math.sin(tilt);
      final double ry = floorY + x * math.sin(tilt) + dy * math.cos(tilt);
      return Vector3(rx, ry, z);
    }

    // 1. Soft Directional Ground Shadow under the entire Wagon
    _drawSoftGroundShadow(
      canvas,
      cam,
      worldCenter: Vector3(0.0, floorY, -2.1),
      radiusX: 1.85,
      radiusZ: 1.55,
      receiverY: 0.0,
    );

    // 2. Wagon 3D Wheels (Front & Rear Axles)
    for (final double wheelZ in [-1.35, -2.85]) {
      _drawWheel3D(
        canvas,
        cam,
        center: Vector3(-xHalf - 0.08, 0.38, wheelZ),
        radius: 0.38,
        width: 0.22,
      );
      _drawWheel3D(
        canvas,
        cam,
        center: Vector3(xHalf + 0.08, 0.38, wheelZ),
        radius: 0.38,
        width: 0.22,
      );
    }

    // 3. Wagon 3D Wooden Floor Bed Slab (Y: 0.42 to 0.60)
    _drawExtruded3DBox(
      canvas,
      cam,
      minCorner: tiltPoint(-xHalf, 0.42, zBack),
      maxCorner: tiltPoint(xHalf, floorY, zFront),
      baseColor: FarmTheme.wagonWoodLight,
      topHighlightColor: const Color(0xFFD4A373),
    );

    // Draw perspective wooden floor plank lines on the wagon bed (Y = floorY)
    final Paint plankLinePaint = Paint()
      ..color = FarmTheme.wagonWoodDark.withValues(alpha: 0.45)
      ..strokeWidth = 1.6;
    for (int p = -4; p <= 4; p++) {
      final double px = p * 0.34;
      final pStart = cam.project(tiltPoint(px, floorY + 0.01, zFront)).screenOffset;
      final pEnd = cam.project(tiltPoint(px, floorY + 0.01, zBack)).screenOffset;
      canvas.drawLine(pStart, pEnd, plankLinePaint);
    }

    // Soft interior wall shadow cast by the Left Wall & Front Wall onto the wagon floor
    final sWallFL = cam.project(tiltPoint(-xHalf + 0.12, floorY + 0.01, zFront - 0.1)).screenOffset;
    final sWallFR = cam.project(tiltPoint(-xHalf + 0.52, floorY + 0.01, zFront - 0.1)).screenOffset;
    final sWallBR = cam.project(tiltPoint(-xHalf + 0.52, floorY + 0.01, zBack + 0.1)).screenOffset;
    final sWallBL = cam.project(tiltPoint(-xHalf + 0.12, floorY + 0.01, zBack + 0.1)).screenOffset;
    final Path wallShadowPath = Path()
      ..moveTo(sWallFL.dx, sWallFL.dy)
      ..lineTo(sWallFR.dx, sWallFR.dy)
      ..lineTo(sWallBR.dx, sWallBR.dy)
      ..lineTo(sWallBL.dx, sWallBL.dy)
      ..close();
    canvas.drawPath(
      wallShadowPath,
      Paint()..color = Colors.black.withValues(alpha: 0.16),
    );

    // 4. Front 3D Wooden Bulkhead Wall (at zFront = -0.85, Y: 0.60 to 1.38)
    _drawExtruded3DBox(
      canvas,
      cam,
      minCorner: tiltPoint(-xHalf, floorY, zFront - 0.12),
      maxCorner: tiltPoint(xHalf, wallTopY + 0.06, zFront),
      baseColor: FarmTheme.wagonWoodDark,
      topHighlightColor: FarmTheme.wagonWoodLight,
    );

    final bool isIsoRotated = cam.config.yawDegrees < -8.0;
    final double rightWallTopY =
        wallTopY - (game.cameraIsoCurved * 0.38); // Cutaway near wall in isometric view

    // 5. Left 3D Wooden Sideboard Wall (X: -1.52 to -1.38, Y: 0.60 to 1.32)
    // In -38° diagonal isometric view, the Left Wall is the far background wall!
    _drawWagonSideWall3D(
      canvas,
      cam,
      minCorner: tiltPoint(-xHalf, floorY, zBack),
      maxCorner: tiltPoint(-xHalf + 0.14, wallTopY, zFront),
      isLeftWall: true,
    );

    // 6. Right 3D Wooden Sideboard Wall (drawn before contents only in normal 0° view)
    if (!isIsoRotated) {
      _drawWagonSideWall3D(
        canvas,
        cam,
        minCorner: tiltPoint(xHalf - 0.14, floorY, zBack),
        maxCorner: tiltPoint(xHalf, rightWallTopY, zFront),
        isLeftWall: false,
      );
    }

    // 6b. Draw 3 Row Color Zones on Wagon Floor (alpha = 0.30) + 3x3 Grid Guides
    const List<(double, double)> rowZBands = [
      (-0.88, -1.68), // Row 0 (Front - Cyan)
      (-1.68, -2.48), // Row 1 (Middle - Gold)
      (-2.48, -3.32), // Row 2 (Back - Violet)
    ];
    for (int r = 0; r < 3; r++) {
      final (double zTop, double zBot) = rowZBands[r];
      final pFL = cam.project(tiltPoint(-xHalf + 0.14, floorY + 0.012, zTop)).screenOffset;
      final pFR = cam.project(tiltPoint(xHalf - 0.14, floorY + 0.012, zTop)).screenOffset;
      final pBR = cam.project(tiltPoint(xHalf - 0.14, floorY + 0.012, zBot)).screenOffset;
      final pBL = cam.project(tiltPoint(-xHalf + 0.14, floorY + 0.012, zBot)).screenOffset;
      final Path rowBandPath = Path()
        ..moveTo(pFL.dx, pFL.dy)
        ..lineTo(pFR.dx, pFR.dy)
        ..lineTo(pBR.dx, pBR.dy)
        ..lineTo(pBL.dx, pBL.dy)
        ..close();
      canvas.drawPath(
        rowBandPath,
        Paint()..color = FarmTheme.rowColor(r).withValues(alpha: 0.30),
      );
    }

    final Paint gridGuidePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.26)
      ..strokeWidth = 1.3;
    for (final double zDiv in [-1.68, -2.48]) {
      final pL = cam.project(tiltPoint(-xHalf + 0.16, floorY + 0.016, zDiv)).screenOffset;
      final pR = cam.project(tiltPoint(xHalf - 0.16, floorY + 0.016, zDiv)).screenOffset;
      canvas.drawLine(pL, pR, gridGuidePaint);
    }
    for (final double xDiv in [-0.45, 0.45]) {
      final pF = cam.project(tiltPoint(xDiv, floorY + 0.016, -0.88)).screenOffset;
      final pB = cam.project(tiltPoint(xDiv, floorY + 0.016, -3.32)).screenOffset;
      canvas.drawLine(pF, pB, gridGuidePaint);
    }

    // Highlight player's current cell (or selected organize cell during cutscene) on the wagon floor
    final int highlightCol =
        (game.isCutsceneActive && game.selectedOrganizeColumn != null)
            ? game.selectedOrganizeColumn!
            : game.currentPlayerColumn;
    final int activeRow =
        (game.isCutsceneActive && game.selectedOrganizeDepthRow != null)
            ? game.selectedOrganizeDepthRow!
            : game.currentPlayerDepthRow;
    final Color activeRowColor = FarmTheme.rowColor(activeRow);
    final double activeCellX = StackedBale.worldXForColumn(highlightCol);
    final double activeCellZ = StackedBale.worldZForRow(activeRow);
    final pCellTL = cam.project(tiltPoint(activeCellX - 0.40, floorY + 0.022, activeCellZ + 0.36)).screenOffset;
    final pCellTR = cam.project(tiltPoint(activeCellX + 0.40, floorY + 0.022, activeCellZ + 0.36)).screenOffset;
    final pCellBR = cam.project(tiltPoint(activeCellX + 0.40, floorY + 0.022, activeCellZ - 0.36)).screenOffset;
    final pCellBL = cam.project(tiltPoint(activeCellX - 0.40, floorY + 0.022, activeCellZ - 0.36)).screenOffset;
    final Path activeCellPath = Path()
      ..moveTo(pCellTL.dx, pCellTL.dy)
      ..lineTo(pCellTR.dx, pCellTR.dy)
      ..lineTo(pCellBR.dx, pCellBR.dy)
      ..lineTo(pCellBL.dx, pCellBL.dy)
      ..close();
    canvas.drawPath(
      activeCellPath,
      Paint()..color = activeRowColor.withValues(alpha: 0.35),
    );
    canvas.drawPath(
      activeCellPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // 7 & 8. Draw 3x3x5 Stacked Bales and 3D Farmer in Camera-Rotated Painter's Depth Order
    final sortedStack = List<StackedBale>.from(game.stackedBales)
      ..sort((a, b) {
        final double depthA =
            cam.project(tiltPoint(a.xOffset, floorY, a.zOffset)).depth;
        final double depthB =
            cam.project(tiltPoint(b.xOffset, floorY, b.zOffset)).depth;
        final int dCmp = depthB.compareTo(depthA); // Farthest (+depth) to Nearest (-depth)
        if (dCmp != 0) return dCmp;
        return a.tier.compareTo(b.tier); // Bottom tier to Top tier
      });

    final double farmerDepth = cam
        .project(tiltPoint(game.playerX, game.playerY, game.playerZ))
        .depth;

    bool farmerDrawn = false;
    for (final stacked in sortedStack) {
      final double baleDepth = cam
          .project(tiltPoint(stacked.xOffset, floorY, stacked.zOffset))
          .depth;

      // Draw farmer before bales that are closer to the camera than the farmer
      if (!farmerDrawn && baleDepth < farmerDepth - 0.12) {
        _drawFarmer3D(
          canvas,
          cam,
          basePos: tiltPoint(game.playerX, game.playerY, game.playerZ),
          isStunned: game.isStunned,
          stunTimer: game.stunTimer,
        );
        farmerDrawn = true;
      }

      final bool isSelectedTopBale = game.isCutsceneActive &&
          game.selectedOrganizeColumn == stacked.column &&
          game.selectedOrganizeDepthRow == stacked.depthRow &&
          stacked.tier ==
              game.getCellCount(stacked.column, stacked.depthRow) - 1;

      final double liftY = isSelectedTopBale ? 0.16 : 0.0;
      final double bx = stacked.xOffset;
      final double by = floorY + (stacked.tier * 0.34) + liftY;
      final double bz = stacked.zOffset;

      _drawSoftGroundShadow(
        canvas,
        cam,
        worldCenter: tiltPoint(bx, by + 0.15, bz),
        radiusX: 0.38,
        radiusZ: 0.26,
        receiverY: by - liftY,
      );

      _drawStrawBale3D(
        canvas,
        cam,
        center: tiltPoint(bx, by + 0.17, bz),
        size: Vector3(0.66, 0.33, 0.44),
        hueVariation: isSelectedTopBale ? 0.12 : stacked.colorHueVariation,
      );
    }

    if (!farmerDrawn) {
      _drawFarmer3D(
        canvas,
        cam,
        basePos: tiltPoint(game.playerX, game.playerY, game.playerZ),
        isStunned: game.isStunned,
        stunTimer: game.stunTimer,
      );
    }

    // In diagonal isometric view, draw the near Right Cutaway Wall after the stacked bales
    if (isIsoRotated) {
      _drawWagonSideWall3D(
        canvas,
        cam,
        minCorner: tiltPoint(xHalf - 0.14, floorY, zBack),
        maxCorner: tiltPoint(xHalf, rightWallTopY, zFront),
        isLeftWall: false,
      );
    }

    // 9. Upward-Rising 3D Target Cylinder Animation for Incoming Bales
    for (final bale in game.activeBales) {
      if (bale.state != BaleState.inFlight) continue;
      _drawLandingTargetCylinder3D(
        canvas,
        cam,
        bale: bale,
        floorY: floorY,
        tiltPoint: tiltPoint,
      );
    }

    // 10. Low Rear Tailgate Lip (at zBack = -3.35, Y: 0.60 to 0.86)
    _drawExtruded3DBox(
      canvas,
      cam,
      minCorner: tiltPoint(-xHalf, floorY, zBack - 0.10),
      maxCorner: tiltPoint(xHalf, floorY + 0.26, zBack),
      baseColor: FarmTheme.wagonWoodDark,
      topHighlightColor: FarmTheme.wagonWoodLight,
    );
  }

  /// Draws 3D Hitched Full Wagons trailing behind the active wagon in the tractor train convoy.
  void _drawHitchedWagons3D(Canvas canvas, Camera3DProjector cam) {
    final double tilt = game.wagonTilt * 0.75;
    const double xHalf = 1.48;
    const double floorY = BaleSpawner.wagonFloorY;

    Vector3 tiltPoint(double x, double y, double z) {
      final double dy = y - floorY;
      final double rx = x * math.cos(tilt) - dy * math.sin(tilt);
      final double ry = floorY + x * math.sin(tilt) + dy * math.cos(tilt);
      return Vector3(rx, ry, z);
    }

    final int wagonCount = math.min(game.wagonsCompleted, 2);
    for (int i = 0; i < wagonCount; i++) {
      // Offset along Z behind active wagon (-3.35)
      final double zHitchFront = -3.35 - (i * 2.60);
      final double zFront = -3.85 - (i * 2.60);
      final double zBack = -5.95 - (i * 2.60);
      final double midZ = (zFront + zBack) * 0.5;

      // 1. Soft ground shadow under hitched wagon
      _drawSoftGroundShadow(
        canvas,
        cam,
        worldCenter: Vector3(0.0, floorY, midZ),
        radiusX: 1.75,
        radiusZ: 1.25,
        receiverY: 0.0,
      );

      // 2. Heavy-duty 3D Iron Tow Hitch & Coupler from preceding wagon
      _drawExtruded3DBox(
        canvas,
        cam,
        minCorner: tiltPoint(-0.14, floorY - 0.10, zFront),
        maxCorner: tiltPoint(0.14, floorY + 0.04, zHitchFront),
        baseColor: const Color(0xFF2B2D42),
        topHighlightColor: const Color(0xFF4A4E69),
      );

      // Hitch locking pin cylinder
      final pPin = cam.project(tiltPoint(0.0, floorY + 0.08, zHitchFront + 0.12));
      canvas.drawCircle(
        pPin.screenOffset,
        5.0 * pPin.scale,
        Paint()..color = FarmTheme.sunWarmYellow,
      );

      // 3. Wagon 3D Wheels (Front & Rear Axles)
      for (final double wz in [zFront - 0.42, zBack + 0.42]) {
        _drawWheel3D(
          canvas,
          cam,
          center: tiltPoint(-xHalf - 0.06, 0.36, wz),
          radius: 0.36,
          width: 0.20,
        );
        _drawWheel3D(
          canvas,
          cam,
          center: tiltPoint(xHalf + 0.06, 0.36, wz),
          radius: 0.36,
          width: 0.20,
        );
      }

      // 4. Wooden Floor Bed Slab
      _drawExtruded3DBox(
        canvas,
        cam,
        minCorner: tiltPoint(-xHalf, 0.42, zBack),
        maxCorner: tiltPoint(xHalf, floorY, zFront),
        baseColor: FarmTheme.wagonWoodDark,
        topHighlightColor: FarmTheme.wagonWoodLight,
      );

      // 5. Wooden Sideboards (Left and Right)
      _drawExtruded3DBox(
        canvas,
        cam,
        minCorner: tiltPoint(-xHalf, floorY, zBack),
        maxCorner: tiltPoint(-xHalf + 0.12, floorY + 0.45, zFront),
        baseColor: const Color(0xFF5C3D1E),
        topHighlightColor: const Color(0xFF8B5E34),
      );
      _drawExtruded3DBox(
        canvas,
        cam,
        minCorner: tiltPoint(xHalf - 0.12, floorY, zBack),
        maxCorner: tiltPoint(xHalf, floorY + 0.45, zFront),
        baseColor: const Color(0xFF5C3D1E),
        topHighlightColor: const Color(0xFF8B5E34),
      );

      // 6. Front Bulkhead & Rear Tailgate
      _drawExtruded3DBox(
        canvas,
        cam,
        minCorner: tiltPoint(-xHalf, floorY, zFront - 0.10),
        maxCorner: tiltPoint(xHalf, floorY + 0.48, zFront),
        baseColor: const Color(0xFF4A3018),
      );
      _drawExtruded3DBox(
        canvas,
        cam,
        minCorner: tiltPoint(-xHalf, floorY, zBack - 0.10),
        maxCorner: tiltPoint(xHalf, floorY + 0.48, zBack),
        baseColor: const Color(0xFF4A3018),
      );

      // 7. Full Stacks of Harvested Golden Straw Bales inside the Hitched Trailer!
      for (int c = 0; c < 3; c++) {
        final double bx = StackedBale.worldXForColumn(c) * 0.95;
        for (int r = 0; r < 3; r++) {
          final double bz = zFront - 0.38 - (r * 0.65);
          for (int tier = 0; tier < 4; tier++) {
            final double by = floorY + (tier * 0.32);
            _drawStrawBale3D(
              canvas,
              cam,
              center: tiltPoint(bx, by + 0.16, bz),
              size: Vector3(0.62, 0.30, 0.42),
              hueVariation: (c * 0.05) - (r * 0.04),
            );
          }
        }
      }

      // 8. Crossed Heavy-Duty Cargo Straps securing the harvest
      final Paint strapPaint = Paint()
        ..color = const Color(0xFF1D3557).withValues(alpha: 0.85)
        ..strokeWidth = 2.4;
      for (final double bz in [zFront - 0.50, zFront - 1.20, zFront - 1.80]) {
        final pL = cam.project(tiltPoint(-xHalf, floorY + 1.28, bz)).screenOffset;
        final pR = cam.project(tiltPoint(xHalf, floorY + 1.28, bz)).screenOffset;
        canvas.drawLine(pL, pR, strapPaint);
      }

      // 9. Harvest Banner Badge on Tailgate: "WAGON #X"
      final pBadgeCenter = cam.project(tiltPoint(0.0, floorY + 0.28, zBack - 0.12));
      final int wagonNumber = i + 1;
      final String badgeText = '🚛 WAGON #$wagonNumber (FULL)';
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: badgeText,
          style: TextStyle(
            color: Colors.white,
            fontSize: 9.0 * pBadgeCenter.scale,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final Rect badgeRect = Rect.fromCenter(
        center: pBadgeCenter.screenOffset,
        width: tp.width + 12.0 * pBadgeCenter.scale,
        height: tp.height + 4.0 * pBadgeCenter.scale,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(badgeRect, const Radius.circular(5)),
        Paint()..color = const Color(0xFF2B2D42).withValues(alpha: 0.90),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(badgeRect, const Radius.circular(5)),
        Paint()
          ..color = FarmTheme.sunWarmYellow
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
      tp.paint(
        canvas,
        pBadgeCenter.screenOffset - Offset(tp.width * 0.5, tp.height * 0.5),
      );
    }
  }

  /// Draws an upward-rising 3D Cylinder beam & animated bottom-to-top rings
  /// at the incoming bale's landing spot inside the wagon.
  void _drawLandingTargetCylinder3D(
    Canvas canvas,
    Camera3DProjector cam, {
    required StrawBale bale,
    required double floorY,
    required Vector3 Function(double x, double y, double z) tiltPoint,
  }) {
    final double tx = bale.targetPos.x;
    final double tz = bale.targetPos.z;

    // Determine target cell (col, depthRow) so cylinder starts atop any stacked bales in that cell
    final int targetCol = tx < -0.45 ? 0 : (tx > 0.45 ? 2 : 1);
    final int targetRow = tz > -1.68 ? 0 : (tz < -2.48 ? 2 : 1);
    final int tiersInCell = game.getCellCount(targetCol, targetRow);

    final double baseY = floorY + 0.02 + (tiersInCell * 0.34);
    const double cylinderHeight = 1.65;
    final double topY = baseY + cylinderHeight;

    final projBase = cam.project(tiltPoint(tx, baseY, tz));
    final projTop = cam.project(tiltPoint(tx, topY, tz));

    final bool inCatchWindow = bale.isInCatchWindow;
    final Color rowThemeColor = FarmTheme.rowColor(targetRow);
    final Color primaryColor = inCatchWindow
        ? Color.lerp(rowThemeColor, Colors.white, 0.25)!
        : rowThemeColor;
    final Color glowAccent = rowThemeColor;

    final double baseRx = 27.0 * projBase.scale;
    final double baseRy = 14.5 * projBase.scale;
    final double topRx = 25.0 * projTop.scale;
    final double topRy = 13.5 * projTop.scale;

    final Offset cBase = projBase.screenOffset;
    final Offset cTop = projTop.screenOffset;

    // 1. Translucent 3D Vertical Cylinder Body (fading from bottom to top)
    final Rect cylinderBounds = Rect.fromLTRB(
      math.min(cBase.dx - baseRx, cTop.dx - topRx),
      cTop.dy - topRy,
      math.max(cBase.dx + baseRx, cTop.dx + topRx),
      cBase.dy + baseRy,
    );

    final Path cylinderBodyPath = Path()
      ..moveTo(cBase.dx - baseRx, cBase.dy)
      ..lineTo(cTop.dx - topRx, cTop.dy)
      ..arcToPoint(
        Offset(cTop.dx + topRx, cTop.dy),
        radius: Radius.elliptical(topRx, topRy),
        clockwise: true,
      )
      ..lineTo(cBase.dx + baseRx, cBase.dy)
      ..arcToPoint(
        Offset(cBase.dx - baseRx, cBase.dy),
        radius: Radius.elliptical(baseRx, baseRy),
        clockwise: true,
      )
      ..close();

    final double bodyAlpha = inCatchWindow ? 0.38 : 0.24;
    final Paint cylinderFillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          primaryColor.withValues(alpha: bodyAlpha),
          glowAccent.withValues(alpha: bodyAlpha * 0.55),
          primaryColor.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(cylinderBounds);

    canvas.drawPath(cylinderBodyPath, cylinderFillPaint);

    // 2. Vertical Cylinder Left & Right Edge Light Rays (fading bottom to top)
    final Paint edgeRayPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          primaryColor.withValues(alpha: inCatchWindow ? 0.85 : 0.55),
          primaryColor.withValues(alpha: 0.0),
        ],
      ).createShader(cylinderBounds)
      ..strokeWidth = inCatchWindow ? 2.4 : 1.6;

    canvas.drawLine(
      Offset(cBase.dx - baseRx, cBase.dy),
      Offset(cTop.dx - topRx, cTop.dy),
      edgeRayPaint,
    );
    canvas.drawLine(
      Offset(cBase.dx + baseRx, cBase.dy),
      Offset(cTop.dx + topRx, cTop.dy),
      edgeRayPaint,
    );

    // 3. Solid Glowing Base Ring on the Wagon Floor / Stack Top
    canvas.drawOval(
      Rect.fromCenter(
        center: cBase,
        width: baseRx * 2.0,
        height: baseRy * 2.0,
      ),
      Paint()
        ..color = primaryColor.withValues(alpha: inCatchWindow ? 0.95 : 0.70)
        ..style = PaintingStyle.stroke
        ..strokeWidth = inCatchWindow ? 3.2 : 2.2,
    );

    // 4. Three Upward-Rising Animated 3D Rings (Bottom -> Top Continuous Flow)
    const int ringCount = 3;
    for (int r = 0; r < ringCount; r++) {
      // Phase 0.0 (at bottom baseY) -> 1.0 (at topY)
      final double phase = ((animTime * 1.85) + (r / ringCount)) % 1.0;
      final double ringWorldY = baseY + phase * cylinderHeight;
      final projRing = cam.project(tiltPoint(tx, ringWorldY, tz));

      // Smooth fade-in at bottom and fade-out near top of cylinder
      final double ringAlpha =
          (math.sin(phase * math.pi) * (1.0 - phase * 0.35)).clamp(0.0, 1.0);
      final double rx = (27.0 - phase * 2.0) * projRing.scale;
      final double ry = (14.5 - phase * 1.0) * projRing.scale;

      canvas.drawOval(
        Rect.fromCenter(
          center: projRing.screenOffset,
          width: rx * 2.0,
          height: ry * 2.0,
        ),
        Paint()
          ..color = primaryColor.withValues(
            alpha: ringAlpha * (inCatchWindow ? 0.92 : 0.68),
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = (2.6 - phase * 1.1).clamp(1.2, 2.8),
      );
    }
  }

  /// Draws a 3D Wooden Wagon Sideboard Wall with visible interior & exterior plank faces.
  void _drawWagonSideWall3D(
    Canvas canvas,
    Camera3DProjector cam, {
    required Vector3 minCorner,
    required Vector3 maxCorner,
    required bool isLeftWall,
  }) {
    _drawExtruded3DBox(
      canvas,
      cam,
      minCorner: minCorner,
      maxCorner: maxCorner,
      baseColor: FarmTheme.wagonWoodDark,
      topHighlightColor: const Color(0xFFD4A373),
      drawInteriorSide: true,
      isLeftWall: isLeftWall,
    );

    // Vertical wooden side stakes along the wall
    for (final double stakeZ in [-1.0, -2.1, -3.2]) {
      _drawExtruded3DBox(
        canvas,
        cam,
        minCorner: Vector3(minCorner.x - 0.02, minCorner.y, stakeZ - 0.06),
        maxCorner: Vector3(maxCorner.x + 0.02, maxCorner.y + 0.08, stakeZ + 0.06),
        baseColor: FarmTheme.wagonIron,
      );
    }
  }

  /// Draws a 3D Straw Bale with 6-face directional shading and 3D twine bands.
  void _drawStrawBale3D(
    Canvas canvas,
    Camera3DProjector cam, {
    required Vector3 center,
    required Vector3 size,
    double hueVariation = 0.0,
    double rotationZ = 0.0,
  }) {
    final double hx = size.x * 0.5;
    final double hy = size.y * 0.5;
    final double hz = size.z * 0.5;

    final hsl = HSLColor.fromColor(FarmTheme.goldenStraw);
    final Color variedStraw = hsl
        .withHue((hsl.hue + hueVariation * 35.0) % 360.0)
        .toColor();

    _drawExtruded3DBox(
      canvas,
      cam,
      minCorner: Vector3(center.x - hx, center.y - hy, center.z - hz),
      maxCorner: Vector3(center.x + hx, center.y + hy, center.z + hz),
      baseColor: variedStraw,
      topHighlightColor: FarmTheme.sunWarmYellow,
    );

    // Draw 3D Twine Ties wrapping the top and front faces of the bale
    final Paint twinePaint = Paint()
      ..color = const Color(0xFF6B4226)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (final double xOff in [-hx * 0.48, hx * 0.48]) {
      final pTopBack = cam.project(Vector3(center.x + xOff, center.y + hy, center.z + hz)).screenOffset;
      final pTopFront = cam.project(Vector3(center.x + xOff, center.y + hy, center.z - hz)).screenOffset;
      final pBotFront = cam.project(Vector3(center.x + xOff, center.y - hy, center.z - hz)).screenOffset;

      final Path twinePath = Path()
        ..moveTo(pTopBack.dx, pTopBack.dy)
        ..lineTo(pTopFront.dx, pTopFront.dy)
        ..lineTo(pBotFront.dx, pBotFront.dy);
      canvas.drawPath(twinePath, twinePaint);
    }
  }

  /// Draws the 3D Farmer Character standing inside the wagon with boots, overalls,
  /// flannel shirt, raised catching hands, head, and 3D straw hat.
  void _drawFarmer3D(
    Canvas canvas,
    Camera3DProjector cam, {
    required Vector3 basePos,
    required bool isStunned,
    required double stunTimer,
  }) {
    // 1. Soft directional shadow on the wooden wagon floor
    _drawSoftGroundShadow(
      canvas,
      cam,
      worldCenter: Vector3(basePos.x, basePos.y + 0.6, basePos.z),
      radiusX: 0.42,
      radiusZ: 0.34,
      receiverY: basePos.y,
    );

    final double stunLeanX = isStunned ? -0.25 : 0.0;
    final double stunDropY = isStunned ? -0.22 : 0.0;

    // 2. 3D Boots & Legs (Y: 0.0 to 0.42 above wagon floor)
    _drawExtruded3DBox(
      canvas,
      cam,
      minCorner: Vector3(basePos.x - 0.20, basePos.y, basePos.z - 0.10),
      maxCorner: Vector3(basePos.x - 0.04, basePos.y + 0.42 + stunDropY * 0.3, basePos.z + 0.10),
      baseColor: const Color(0xFF1D3557),
    );
    _drawExtruded3DBox(
      canvas,
      cam,
      minCorner: Vector3(basePos.x + 0.04, basePos.y, basePos.z - 0.10),
      maxCorner: Vector3(basePos.x + 0.20, basePos.y + 0.42 + stunDropY * 0.3, basePos.z + 0.10),
      baseColor: const Color(0xFF1D3557),
    );

    // 3. 3D Torso: Blue Denim Overalls & Red Shirt (Y: 0.42 to 1.02)
    final double torsoMinY = basePos.y + 0.40 + stunDropY * 0.5;
    final double torsoMaxY = basePos.y + 1.02 + stunDropY;
    _drawExtruded3DBox(
      canvas,
      cam,
      minCorner: Vector3(basePos.x - 0.25 + stunLeanX, torsoMinY, basePos.z - 0.14),
      maxCorner: Vector3(basePos.x + 0.25 + stunLeanX, torsoMaxY, basePos.z + 0.14),
      baseColor: FarmTheme.tractorRed,
      topHighlightColor: const Color(0xFFFF6B6B),
    );

    // Blue Overalls Bib on Torso
    _drawExtruded3DBox(
      canvas,
      cam,
      minCorner: Vector3(basePos.x - 0.21 + stunLeanX, torsoMinY, basePos.z - 0.16),
      maxCorner: Vector3(basePos.x + 0.21 + stunLeanX, torsoMaxY - 0.14, basePos.z + 0.16),
      baseColor: const Color(0xFF264653),
    );

    // 4. 3D Arms Raised to Catch Incoming Bales
    final double armTopY = isStunned ? torsoMaxY - 0.10 : torsoMaxY + 0.22;
    _drawExtruded3DBox(
      canvas,
      cam,
      minCorner: Vector3(basePos.x - 0.38 + stunLeanX, torsoMaxY - 0.25, basePos.z - 0.08),
      maxCorner: Vector3(basePos.x - 0.25 + stunLeanX, armTopY, basePos.z + 0.24),
      baseColor: FarmTheme.tractorRed,
    );
    _drawExtruded3DBox(
      canvas,
      cam,
      minCorner: Vector3(basePos.x + 0.25 + stunLeanX, torsoMaxY - 0.25, basePos.z - 0.08),
      maxCorner: Vector3(basePos.x + 0.38 + stunLeanX, armTopY, basePos.z + 0.24),
      baseColor: FarmTheme.tractorRed,
    );

    // 5. 3D Head (Y: 1.02 to 1.36)
    final double headMinY = torsoMaxY + 0.02;
    final double headMaxY = headMinY + 0.34;
    _drawExtruded3DBox(
      canvas,
      cam,
      minCorner: Vector3(basePos.x - 0.18 + stunLeanX, headMinY, basePos.z - 0.16),
      maxCorner: Vector3(basePos.x + 0.18 + stunLeanX, headMaxY, basePos.z + 0.16),
      baseColor: const Color(0xFFFFCBA4),
      topHighlightColor: const Color(0xFFFFE5D0),
    );

    // 6. 3D Wide-Brimmed Straw Hat (Brim + Red Band + Crown)
    final double hatTilt = isStunned ? -0.15 : 0.0;
    // Hat Brim
    _drawExtruded3DBox(
      canvas,
      cam,
      minCorner: Vector3(basePos.x - 0.36 + stunLeanX + hatTilt, headMaxY - 0.04, basePos.z - 0.32),
      maxCorner: Vector3(basePos.x + 0.36 + stunLeanX + hatTilt, headMaxY + 0.04, basePos.z + 0.32),
      baseColor: FarmTheme.goldenStraw,
      topHighlightColor: FarmTheme.sunWarmYellow,
    );
    // Hat Red Ribbon
    _drawExtruded3DBox(
      canvas,
      cam,
      minCorner: Vector3(basePos.x - 0.20 + stunLeanX + hatTilt, headMaxY + 0.04, basePos.z - 0.18),
      maxCorner: Vector3(basePos.x + 0.20 + stunLeanX + hatTilt, headMaxY + 0.10, basePos.z + 0.18),
      baseColor: FarmTheme.tractorRed,
    );
    // Hat Crown
    _drawExtruded3DBox(
      canvas,
      cam,
      minCorner: Vector3(basePos.x - 0.19 + stunLeanX + hatTilt, headMaxY + 0.10, basePos.z - 0.17),
      maxCorner: Vector3(basePos.x + 0.19 + stunLeanX + hatTilt, headMaxY + 0.24, basePos.z + 0.17),
      baseColor: FarmTheme.goldenStraw,
      topHighlightColor: FarmTheme.sunWarmYellow,
    );

    // 7. Stunned Orbiting 3D Stars & Recovery Progress Bar
    if (isStunned) {
      final Paint starPaint = Paint()..color = FarmTheme.sunWarmYellow;
      for (int i = 0; i < 3; i++) {
        final double angle = (animTime * 7.5) + (i * 2.094);
        final Vector3 starPos = Vector3(
          basePos.x + stunLeanX + math.cos(angle) * 0.42,
          headMaxY + 0.38,
          basePos.z + math.sin(angle) * 0.32,
        );
        final projStar = cam.project(starPos);
        canvas.drawCircle(projStar.screenOffset, 4.5 * projStar.scale, starPaint);
      }

      // 3D Projected Stun Recovery Bar above head
      final projBar = cam.project(Vector3(basePos.x, headMaxY + 0.65, basePos.z));
      final double stunRatio = (stunTimer / 3.0).clamp(0.0, 1.0);
      final Offset bc = projBar.screenOffset;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: bc, width: 54, height: 7),
          const Radius.circular(4),
        ),
        Paint()..color = Colors.black87,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(bc.dx - 26, bc.dy - 2.5, 52 * (1.0 - stunRatio), 5),
          const Radius.circular(3),
        ),
        Paint()..color = FarmTheme.stunBlue,
      );
    }
  }

  /// Draws all airborne parabolic straw bales as well as missed/overflow bales
  /// in 3D perspective with soft directional ground shadows and "MISSED" labels.
  void _drawFlyingBales3D(Canvas canvas, Camera3DProjector cam) {
    // Highlight selected column in 3D wagon during 7-second Cutscene Mode
    if (game.isCutsceneActive && game.selectedOrganizeColumn != null) {
      final double selX = (game.selectedOrganizeColumn! - 1) * 0.8 * 1.05;
      final projCol = cam.project(
        Vector3(selX, BaleSpawner.wagonFloorY + 0.05, -1.42),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: projCol.screenOffset,
          width: 72.0 * projCol.scale,
          height: 36.0 * projCol.scale,
        ),
        Paint()
          ..color = FarmTheme.sunWarmYellow.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5,
      );
    }

    // Sort active bales/animals (inFlight + escaping + missed/overflow) from far (+Z) to near (-Z)
    final bales = game.activeBales
        .where((b) =>
            b.state == BaleState.inFlight ||
            b.state == BaleState.escaping ||
            b.state == BaleState.missed ||
            b.state == BaleState.overflowInside ||
            b.state == BaleState.overflowOutside)
        .toList()
      ..sort((a, b) => b.currentPos.z.compareTo(a.currentPos.z));

    for (final bale in bales) {
      final bool isOverWagon = bale.state != BaleState.overflowOutside &&
          bale.currentPos.z <= -0.80 &&
          bale.currentPos.z >= -3.40 &&
          bale.currentPos.x.abs() <= 1.55;
      final double receiverY = isOverWagon ? BaleSpawner.wagonFloorY : 0.0;

      // 1. Draw Soft Directional Shadow on road or wagon floor
      _drawSoftGroundShadow(
        canvas,
        cam,
        worldCenter: bale.currentPos,
        radiusX: 0.40 * bale.fadeOpacity,
        radiusZ: 0.28 * bale.fadeOpacity,
        receiverY: receiverY,
      );

      // 2. Draw either 3D Low-Poly Farm Animal or 3D Straw Bale
      final double scaleFade = 0.65 + 0.35 * bale.fadeOpacity;
      if (bale.objectType.isAnimal) {
        _drawLowPolyAnimal3D(
          canvas,
          cam,
          bale: bale,
          scale: scaleFade,
        );
      } else {
        _drawStrawBale3D(
          canvas,
          cam,
          center: bale.currentPos,
          size: Vector3(0.70 * scaleFade, 0.38 * scaleFade, 0.46 * scaleFade),
          hueVariation: bale.colorHueVariation,
          rotationZ: bale.currentRotation.z,
        );
      }

      // 3. Draw Catch Timing Halo when bale/animal is within the 3D catch window
      if (bale.isInCatchWindow) {
        final projBale = cam.project(bale.currentPos);
        final Color ringColor = bale.objectType.isAnimal
            ? FarmTheme.comboOrange
            : FarmTheme.sunWarmYellow;
        canvas.drawCircle(
          projBale.screenOffset,
          28.0 * projBale.scale,
          Paint()
            ..color = ringColor.withValues(alpha: 0.88)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.8,
        );
      }

      // 4. If bale landed inside wagon uncaught (missed) or overflowed, draw red shockwave + "💔 MISSED -15 HP" badge!
      if (bale.state == BaleState.missed ||
          bale.state == BaleState.overflowInside ||
          bale.state == BaleState.overflowOutside) {
        final double fade = bale.fadeOpacity.clamp(0.0, 1.0);
        final double expandProgress = (1.0 - fade).clamp(0.0, 1.0);

        // Red impact ring on the floor under the missed bale
        final projImpact = cam.project(
          Vector3(bale.currentPos.x, receiverY + 0.03, bale.currentPos.z),
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: projImpact.screenOffset,
            width: (50.0 + expandProgress * 44.0) * projImpact.scale,
            height: (28.0 + expandProgress * 24.0) * projImpact.scale,
          ),
          Paint()
            ..color = FarmTheme.heartRed.withValues(alpha: fade * 0.85)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.2,
        );

        final projLabel = cam.project(
          Vector3(
            bale.currentPos.x,
            bale.currentPos.y + 0.52 + expandProgress * 0.35,
            bale.currentPos.z,
          ),
        );
        final String labelText =
            bale.state == BaleState.overflowOutside ? 'OUT -15' : 'MISSED -15';
        final textSpan = TextSpan(
          text: labelText,
          style: TextStyle(
            color: Colors.white.withValues(alpha: fade),
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.6,
          ),
        );
        final tp = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        )..layout();

        final Rect badgeRect = Rect.fromCenter(
          center: projLabel.screenOffset,
          width: tp.width + 16,
          height: tp.height + 8,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(badgeRect, const Radius.circular(12)),
          Paint()..color = FarmTheme.heartRed.withValues(alpha: 0.92 * fade),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(badgeRect, const Radius.circular(12)),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.9 * fade)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );

        tp.paint(
          canvas,
          Offset(
            projLabel.screenOffset.dx - tp.width * 0.5,
            projLabel.screenOffset.dy - tp.height * 0.5,
          ),
        );
      }
    }
  }

  /// Renders a distinct 3D Low-Poly Farm Animal (chicken, rooster, duck, sheep,
  /// cow, cat, dog, bird) with animated legs/wings, dust puffs while escaping,
  /// and a crisp overhead identification badge.
  void _drawLowPolyAnimal3D(
    Canvas canvas,
    Camera3DProjector cam, {
    required StrawBale bale,
    required double scale,
  }) {
    final Vector3 pos = bale.currentPos;
    final double s = scale;
    final double anim = bale.wobbleOffset;
    final double legSwing = math.sin(anim * 2.2) * 0.08 * s;
    final double wingFlap = math.sin(anim * 2.8) * 0.12 * s;
    final ThrownObjectType type = bale.objectType;

    // 1. If escaping on the wagon floor, draw scurrying dust puffs behind feet
    if (bale.state == BaleState.escaping) {
      for (int i = 0; i < 3; i++) {
        final double trailT = (i + 1) * 0.14;
        final Vector3 dustPos = Vector3(
          pos.x - bale.tumbleVelocity.x * trailT * 0.35,
          pos.y - 0.04 + (i * 0.05),
          pos.z - bale.tumbleVelocity.z * trailT * 0.35,
        );
        final projDust = cam.project(dustPos);
        canvas.drawCircle(
          projDust.screenOffset,
          (6.5 - i * 1.6) * projDust.scale * bale.fadeOpacity,
          Paint()
            ..color = const Color(0xFFF3E5AB)
                .withValues(alpha: 0.55 * bale.fadeOpacity),
        );
      }
    }

    // 2. Choose animal-specific 3D low-poly geometry & color palette
    switch (type) {
      case ThrownObjectType.chicken:
      case ThrownObjectType.rooster:
        final bool isRooster = type == ThrownObjectType.rooster;
        final Color bodyColor = isRooster
            ? const Color(0xFFD96B27)
            : const Color(0xFFFFFDF5);
        final Color wingColor = isRooster
            ? const Color(0xFF9E3B18)
            : const Color(0xFFF2E8CF);

        // Two orange legs
        for (final double lx in [-0.09 * s, 0.09 * s]) {
          _drawExtruded3DBox(
            canvas,
            cam,
            minCorner: Vector3(pos.x + lx - 0.025 * s, pos.y - 0.18 * s, pos.z - 0.03 * s + (lx > 0 ? legSwing : -legSwing)),
            maxCorner: Vector3(pos.x + lx + 0.025 * s, pos.y, pos.z + 0.03 * s + (lx > 0 ? legSwing : -legSwing)),
            baseColor: const Color(0xFFFB8500),
          );
        }
        // Plump 3D body
        _drawExtruded3DBox(
          canvas,
          cam,
          minCorner: Vector3(pos.x - 0.22 * s, pos.y - 0.02 * s, pos.z - 0.24 * s),
          maxCorner: Vector3(pos.x + 0.22 * s, pos.y + 0.28 * s, pos.z + 0.22 * s),
          baseColor: bodyColor,
        );
        // Rooster dark emerald tail plume at back
        if (isRooster) {
          _drawExtruded3DBox(
            canvas,
            cam,
            minCorner: Vector3(pos.x - 0.10 * s, pos.y + 0.16 * s, pos.z + 0.16 * s),
            maxCorner: Vector3(pos.x + 0.10 * s, pos.y + 0.48 * s, pos.z + 0.36 * s),
            baseColor: const Color(0xFF1B4332),
            topHighlightColor: const Color(0xFF2D6A4F),
          );
        }
        // Flapping side wings
        _drawExtruded3DBox(
          canvas,
          cam,
          minCorner: Vector3(pos.x - 0.31 * s, pos.y + (0.06 + wingFlap) * s, pos.z - 0.14 * s),
          maxCorner: Vector3(pos.x + 0.31 * s, pos.y + (0.22 + wingFlap) * s, pos.z + 0.12 * s),
          baseColor: wingColor,
        );
        // Head + Red Comb + Orange Beak
        _drawExtruded3DBox(
          canvas,
          cam,
          minCorner: Vector3(pos.x - 0.14 * s, pos.y + 0.22 * s, pos.z - 0.28 * s),
          maxCorner: Vector3(pos.x + 0.14 * s, pos.y + 0.44 * s, pos.z - 0.04 * s),
          baseColor: bodyColor,
        );
        _drawExtruded3DBox(
          canvas,
          cam,
          minCorner: Vector3(pos.x - 0.04 * s, pos.y + 0.42 * s, pos.z - 0.25 * s),
          maxCorner: Vector3(pos.x + 0.04 * s, pos.y + (isRooster ? 0.58 : 0.52) * s, pos.z - 0.08 * s),
          baseColor: const Color(0xFFE63946),
        );
        _drawExtruded3DBox(
          canvas,
          cam,
          minCorner: Vector3(pos.x - 0.06 * s, pos.y + 0.28 * s, pos.z - 0.38 * s),
          maxCorner: Vector3(pos.x + 0.06 * s, pos.y + 0.36 * s, pos.z - 0.26 * s),
          baseColor: const Color(0xFFFFB703),
        );
        break;

      case ThrownObjectType.duck:
        // Webbed orange feet
        for (final double lx in [-0.10 * s, 0.10 * s]) {
          _drawExtruded3DBox(
            canvas,
            cam,
            minCorner: Vector3(pos.x + lx - 0.05 * s, pos.y - 0.15 * s, pos.z - 0.06 * s),
            maxCorner: Vector3(pos.x + lx + 0.05 * s, pos.y, pos.z + 0.06 * s),
            baseColor: const Color(0xFFFB8500),
          );
        }
        // Duck body
        _drawExtruded3DBox(
          canvas,
          cam,
          minCorner: Vector3(pos.x - 0.24 * s, pos.y, pos.z - 0.26 * s),
          maxCorner: Vector3(pos.x + 0.24 * s, pos.y + 0.26 * s, pos.z + 0.26 * s),
          baseColor: const Color(0xFFF4F1DE),
        );
        // Mallard emerald-green head
        _drawExtruded3DBox(
          canvas,
          cam,
          minCorner: Vector3(pos.x - 0.14 * s, pos.y + 0.22 * s, pos.z - 0.30 * s),
          maxCorner: Vector3(pos.x + 0.14 * s, pos.y + 0.44 * s, pos.z - 0.08 * s),
          baseColor: const Color(0xFF2A9D8F),
          topHighlightColor: const Color(0xFF48CAE4),
        );
        // Flat yellow-orange bill
        _drawExtruded3DBox(
          canvas,
          cam,
          minCorner: Vector3(pos.x - 0.10 * s, pos.y + 0.26 * s, pos.z - 0.44 * s),
          maxCorner: Vector3(pos.x + 0.10 * s, pos.y + 0.33 * s, pos.z - 0.28 * s),
          baseColor: const Color(0xFFFFB703),
        );
        break;

      case ThrownObjectType.sheep:
        // 4 dark charcoal legs
        for (final double lx in [-0.16 * s, 0.16 * s]) {
          for (final double lz in [-0.16 * s, 0.16 * s]) {
            _drawExtruded3DBox(
              canvas,
              cam,
              minCorner: Vector3(pos.x + lx - 0.04 * s, pos.y - 0.18 * s, pos.z + lz - 0.04 * s),
              maxCorner: Vector3(pos.x + lx + 0.04 * s, pos.y + 0.02 * s, pos.z + lz + 0.04 * s),
              baseColor: const Color(0xFF2B2D42),
            );
          }
        }
        // Fluffy white wool 3D cube body
        _drawExtruded3DBox(
          canvas,
          cam,
          minCorner: Vector3(pos.x - 0.30 * s, pos.y, pos.z - 0.28 * s),
          maxCorner: Vector3(pos.x + 0.30 * s, pos.y + 0.36 * s, pos.z + 0.28 * s),
          baseColor: const Color(0xFFF8F9FA),
          topHighlightColor: Colors.white,
        );
        // Dark sheep face + wool cap
        _drawExtruded3DBox(
          canvas,
          cam,
          minCorner: Vector3(pos.x - 0.16 * s, pos.y + 0.14 * s, pos.z - 0.42 * s),
          maxCorner: Vector3(pos.x + 0.16 * s, pos.y + 0.36 * s, pos.z - 0.22 * s),
          baseColor: const Color(0xFF2B2D42),
        );
        _drawExtruded3DBox(
          canvas,
          cam,
          minCorner: Vector3(pos.x - 0.18 * s, pos.y + 0.32 * s, pos.z - 0.40 * s),
          maxCorner: Vector3(pos.x + 0.18 * s, pos.y + 0.42 * s, pos.z - 0.20 * s),
          baseColor: Colors.white,
        );
        break;

      case ThrownObjectType.cow:
        // 4 legs
        for (final double lx in [-0.18 * s, 0.18 * s]) {
          for (final double lz in [-0.18 * s, 0.18 * s]) {
            _drawExtruded3DBox(
              canvas,
              cam,
              minCorner: Vector3(pos.x + lx - 0.045 * s, pos.y - 0.20 * s, pos.z + lz - 0.045 * s),
              maxCorner: Vector3(pos.x + lx + 0.045 * s, pos.y + 0.02 * s, pos.z + lz + 0.045 * s),
              baseColor: const Color(0xFF212529),
            );
          }
        }
        // White cow body + dark spot patch on back
        _drawExtruded3DBox(
          canvas,
          cam,
          minCorner: Vector3(pos.x - 0.32 * s, pos.y, pos.z - 0.30 * s),
          maxCorner: Vector3(pos.x + 0.32 * s, pos.y + 0.38 * s, pos.z + 0.30 * s),
          baseColor: const Color(0xFFF8F9FA),
          topHighlightColor: Colors.white,
        );
        _drawExtruded3DBox(
          canvas,
          cam,
          minCorner: Vector3(pos.x - 0.20 * s, pos.y + 0.24 * s, pos.z - 0.12 * s),
          maxCorner: Vector3(pos.x + 0.22 * s, pos.y + 0.40 * s, pos.z + 0.20 * s),
          baseColor: const Color(0xFF212529),
        );
        // Cow head + pink snout + horns
        _drawExtruded3DBox(
          canvas,
          cam,
          minCorner: Vector3(pos.x - 0.18 * s, pos.y + 0.16 * s, pos.z - 0.44 * s),
          maxCorner: Vector3(pos.x + 0.18 * s, pos.y + 0.42 * s, pos.z - 0.22 * s),
          baseColor: const Color(0xFFF8F9FA),
        );
        _drawExtruded3DBox(
          canvas,
          cam,
          minCorner: Vector3(pos.x - 0.15 * s, pos.y + 0.15 * s, pos.z - 0.50 * s),
          maxCorner: Vector3(pos.x + 0.15 * s, pos.y + 0.28 * s, pos.z - 0.40 * s),
          baseColor: const Color(0xFFFFADC6),
        );
        for (final double hx in [-0.16 * s, 0.16 * s]) {
          _drawExtruded3DBox(
            canvas,
            cam,
            minCorner: Vector3(pos.x + hx - 0.03 * s, pos.y + 0.40 * s, pos.z - 0.36 * s),
            maxCorner: Vector3(pos.x + hx + 0.03 * s, pos.y + 0.50 * s, pos.z - 0.30 * s),
            baseColor: const Color(0xFFE9D8A6),
          );
        }
        break;

      case ThrownObjectType.cat:
        // Ginger cat body + upright tail + pointed ears
        _drawExtruded3DBox(
          canvas,
          cam,
          minCorner: Vector3(pos.x - 0.20 * s, pos.y - 0.04 * s, pos.z - 0.24 * s),
          maxCorner: Vector3(pos.x + 0.20 * s, pos.y + 0.24 * s, pos.z + 0.24 * s),
          baseColor: const Color(0xFFF77F00),
          topHighlightColor: const Color(0xFFFCBF49),
        );
        // Upright cat tail
        _drawExtruded3DBox(
          canvas,
          cam,
          minCorner: Vector3(pos.x - 0.04 * s, pos.y + 0.16 * s, pos.z + 0.18 * s),
          maxCorner: Vector3(pos.x + 0.04 * s, pos.y + 0.46 * s, pos.z + 0.26 * s),
          baseColor: const Color(0xFFD62828),
        );
        // Cat head + two pointed ears
        _drawExtruded3DBox(
          canvas,
          cam,
          minCorner: Vector3(pos.x - 0.16 * s, pos.y + 0.16 * s, pos.z - 0.36 * s),
          maxCorner: Vector3(pos.x + 0.16 * s, pos.y + 0.38 * s, pos.z - 0.14 * s),
          baseColor: const Color(0xFFF77F00),
        );
        for (final double ex in [-0.11 * s, 0.11 * s]) {
          _drawExtruded3DBox(
            canvas,
            cam,
            minCorner: Vector3(pos.x + ex - 0.04 * s, pos.y + 0.36 * s, pos.z - 0.30 * s),
            maxCorner: Vector3(pos.x + ex + 0.04 * s, pos.y + 0.47 * s, pos.z - 0.22 * s),
            baseColor: const Color(0xFFD62828),
          );
        }
        break;

      case ThrownObjectType.dog:
        // Golden-brown dog body + wagging tail + floppy brown ears
        _drawExtruded3DBox(
          canvas,
          cam,
          minCorner: Vector3(pos.x - 0.23 * s, pos.y - 0.04 * s, pos.z - 0.26 * s),
          maxCorner: Vector3(pos.x + 0.23 * s, pos.y + 0.28 * s, pos.z + 0.26 * s),
          baseColor: const Color(0xFFC68B59),
          topHighlightColor: const Color(0xFFD4A373),
        );
        // Wagging tail
        _drawExtruded3DBox(
          canvas,
          cam,
          minCorner: Vector3(pos.x - 0.04 * s + legSwing, pos.y + 0.18 * s, pos.z + 0.20 * s),
          maxCorner: Vector3(pos.x + 0.04 * s + legSwing, pos.y + 0.42 * s, pos.z + 0.32 * s),
          baseColor: const Color(0xFF6F4E37),
        );
        // Dog head + snout + floppy ears
        _drawExtruded3DBox(
          canvas,
          cam,
          minCorner: Vector3(pos.x - 0.17 * s, pos.y + 0.18 * s, pos.z - 0.38 * s),
          maxCorner: Vector3(pos.x + 0.17 * s, pos.y + 0.42 * s, pos.z - 0.14 * s),
          baseColor: const Color(0xFFC68B59),
        );
        _drawExtruded3DBox(
          canvas,
          cam,
          minCorner: Vector3(pos.x - 0.10 * s, pos.y + 0.18 * s, pos.z - 0.47 * s),
          maxCorner: Vector3(pos.x + 0.10 * s, pos.y + 0.29 * s, pos.z - 0.36 * s),
          baseColor: const Color(0xFF6F4E37),
        );
        for (final double ex in [-0.19 * s, 0.19 * s]) {
          _drawExtruded3DBox(
            canvas,
            cam,
            minCorner: Vector3(pos.x + ex - 0.04 * s, pos.y + 0.22 * s, pos.z - 0.30 * s),
            maxCorner: Vector3(pos.x + ex + 0.04 * s, pos.y + 0.38 * s, pos.z - 0.20 * s),
            baseColor: const Color(0xFF6F4E37),
          );
        }
        break;

      case ThrownObjectType.bird:
      case ThrownObjectType.bale:
        // Sky-blue bird with wide flapping wings
        _drawExtruded3DBox(
          canvas,
          cam,
          minCorner: Vector3(pos.x - 0.18 * s, pos.y + 0.04 * s, pos.z - 0.22 * s),
          maxCorner: Vector3(pos.x + 0.18 * s, pos.y + 0.28 * s, pos.z + 0.22 * s),
          baseColor: const Color(0xFF38BDF8),
          topHighlightColor: const Color(0xFF7DD3FC),
        );
        // Wide flapping wings
        _drawExtruded3DBox(
          canvas,
          cam,
          minCorner: Vector3(pos.x - 0.42 * s, pos.y + (0.14 + wingFlap) * s, pos.z - 0.12 * s),
          maxCorner: Vector3(pos.x + 0.42 * s, pos.y + (0.22 + wingFlap) * s, pos.z + 0.12 * s),
          baseColor: const Color(0xFF0284C7),
        );
        // Yellow beak
        _drawExtruded3DBox(
          canvas,
          cam,
          minCorner: Vector3(pos.x - 0.06 * s, pos.y + 0.12 * s, pos.z - 0.32 * s),
          maxCorner: Vector3(pos.x + 0.06 * s, pos.y + 0.20 * s, pos.z - 0.20 * s),
          baseColor: const Color(0xFFFFB703),
        );
        break;
    }

    // 3. Draw Compact Emoji Badge above the animal (no verbose text clutter)
    final double fade = bale.fadeOpacity.clamp(0.0, 1.0);
    final projBadge = cam.project(
      Vector3(pos.x, pos.y + 0.58 * s, pos.z),
    );
    final String badgeText = bale.state == BaleState.escaping && bale.wasCaughtBeforeEscape
        ? '${type.emoji} ⚡'
        : type.emoji;

    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: badgeText,
        style: TextStyle(
          color: Colors.white.withValues(alpha: fade),
          fontSize: 13.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final Rect pillRect = Rect.fromCenter(
      center: projBadge.screenOffset,
      width: tp.width + 10,
      height: tp.height + 4,
    );
    final Color pillBg = bale.state == BaleState.escaping
        ? (bale.wasCaughtBeforeEscape
            ? FarmTheme.heartRed.withValues(alpha: 0.90 * fade)
            : FarmTheme.comboOrange.withValues(alpha: 0.90 * fade))
        : FarmTheme.uiPillBg.withValues(alpha: 0.88 * fade);

    canvas.drawRRect(
      RRect.fromRectAndRadius(pillRect, const Radius.circular(10)),
      Paint()..color = pillBg,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(pillRect, const Radius.circular(10)),
      Paint()
        ..color = FarmTheme.sunWarmYellow.withValues(alpha: 0.85 * fade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );
    tp.paint(
      canvas,
      Offset(
        projBadge.screenOffset.dx - tp.width * 0.5,
        projBadge.screenOffset.dy - tp.height * 0.5,
      ),
    );
  }

  /// Draws a soft, directional ground shadow projected from the warm sun key light.
  void _drawSoftGroundShadow(
    Canvas canvas,
    Camera3DProjector cam, {
    required Vector3 worldCenter,
    required double radiusX,
    required double radiusZ,
    required double receiverY,
  }) {
    final projShadow = cam.projectShadow(
      worldCenter,
      receiverPlaneY: receiverY,
    );
    final double heightDiff = math.max(0.0, worldCenter.y - receiverY);
    final double heightAttenuation = (1.0 - (heightDiff / 7.5)).clamp(0.28, 1.0);
    final double alpha =
        cam.config.shadowDarkness * heightAttenuation;

    final double w = radiusX * 88.0 * projShadow.scale * heightAttenuation;
    final double h = radiusZ * 52.0 * projShadow.scale * heightAttenuation;

    canvas.drawOval(
      Rect.fromCenter(
        center: projShadow.screenOffset,
        width: w,
        height: h,
      ),
      Paint()
        ..color = const Color(0xFF1A2418).withValues(alpha: alpha)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          cam.config.shadowSoftness * (0.7 + (1.0 - heightAttenuation) * 0.8),
        ),
    );
  }

  /// Renders a 3D Cylindrical Wheel with dark rubber tire and silver hubcap.
  void _drawWheel3D(
    Canvas canvas,
    Camera3DProjector cam, {
    required Vector3 center,
    required double radius,
    required double width,
  }) {
    final double hw = width * 0.5;
    _drawExtruded3DBox(
      canvas,
      cam,
      minCorner: Vector3(center.x - hw, center.y - radius, center.z - radius),
      maxCorner: Vector3(center.x + hw, center.y + radius, center.z + radius),
      baseColor: const Color(0xFF252830),
      topHighlightColor: const Color(0xFF3E424E),
    );

    // Wheel rim highlight on outer side
    final double rimX = center.x < 0 ? center.x - hw - 0.01 : center.x + hw + 0.01;
    final projRim = cam.project(Vector3(rimX, center.y, center.z));
    canvas.drawOval(
      Rect.fromCenter(
        center: projRim.screenOffset,
        width: radius * 16.0 * projRim.scale,
        height: radius * 28.0 * projRim.scale,
      ),
      Paint()..color = const Color(0xFFADB5BD),
    );
  }

  /// Renders a true 3D axis-aligned box in perspective with directional Key Light shading
  /// on its Top, Front (-Z), Left (-X), and Right (+X) faces.
  void _drawExtruded3DBox(
    Canvas canvas,
    Camera3DProjector cam, {
    required Vector3 minCorner,
    required Vector3 maxCorner,
    required Color baseColor,
    Color? topHighlightColor,
    bool drawInteriorSide = false,
    bool isLeftWall = false,
  }) {
    // 8 vertices of the 3D box
    final p000 = cam.project(Vector3(minCorner.x, minCorner.y, minCorner.z)).screenOffset;
    final p100 = cam.project(Vector3(maxCorner.x, minCorner.y, minCorner.z)).screenOffset;
    final p010 = cam.project(Vector3(minCorner.x, maxCorner.y, minCorner.z)).screenOffset;
    final p110 = cam.project(Vector3(maxCorner.x, maxCorner.y, minCorner.z)).screenOffset;

    final p001 = cam.project(Vector3(minCorner.x, minCorner.y, maxCorner.z)).screenOffset;
    final p101 = cam.project(Vector3(maxCorner.x, minCorner.y, maxCorner.z)).screenOffset;
    final p011 = cam.project(Vector3(minCorner.x, maxCorner.y, maxCorner.z)).screenOffset;
    final p111 = cam.project(Vector3(maxCorner.x, maxCorner.y, maxCorner.z)).screenOffset;

    final Color topColor = topHighlightColor ?? cam.shadeColor(baseColor, _normalTop);
    final Color frontColor = cam.shadeColor(baseColor, _normalFront);
    final Color leftColor = cam.shadeColor(baseColor, _normalLeft);
    final Color rightColor = cam.shadeColor(baseColor, _normalRight);

    // 1. Draw Interior Side Wall if requested (for open wooden wagon walls)
    if (drawInteriorSide) {
      if (isLeftWall) {
        // Inner right-facing surface of the left wall
        final Path innerRight = Path()
          ..moveTo(p100.dx, p100.dy)
          ..lineTo(p101.dx, p101.dy)
          ..lineTo(p111.dx, p111.dy)
          ..lineTo(p110.dx, p110.dy)
          ..close();
        canvas.drawPath(
          innerRight,
          Paint()..color = cam.shadeColor(FarmTheme.wagonWoodLight, _normalInteriorLeft),
        );
      } else {
        // Inner left-facing surface of the right wall
        final Path innerLeft = Path()
          ..moveTo(p000.dx, p000.dy)
          ..lineTo(p001.dx, p001.dy)
          ..lineTo(p011.dx, p011.dy)
          ..lineTo(p010.dx, p010.dy)
          ..close();
        canvas.drawPath(
          innerLeft,
          Paint()..color = cam.shadeColor(FarmTheme.wagonWoodLight, _normalInteriorRight),
        );
      }
    }

    // 2. Draw Outer Left or Right Face depending on X position and diagonal isometric yaw
    final double centerX = (minCorner.x + maxCorner.x) * 0.5;
    final bool isIsoYaw = cam.config.yawDegrees < -3.0;
    if (centerX >= -0.05 && !isIsoYaw) {
      final Path leftFace = Path()
        ..moveTo(p000.dx, p000.dy)
        ..lineTo(p001.dx, p001.dy)
        ..lineTo(p011.dx, p011.dy)
        ..lineTo(p010.dx, p010.dy)
        ..close();
      canvas.drawPath(leftFace, Paint()..color = leftColor);
    }
    if (centerX <= 0.05 || isIsoYaw) {
      final Path rightFace = Path()
        ..moveTo(p100.dx, p100.dy)
        ..lineTo(p101.dx, p101.dy)
        ..lineTo(p111.dx, p111.dy)
        ..lineTo(p110.dx, p110.dy)
        ..close();
      canvas.drawPath(rightFace, Paint()..color = rightColor);
    }

    // 3. Front Face (facing camera at -Z: p000, p100, p110, p010)
    final Path frontFace = Path()
      ..moveTo(p000.dx, p000.dy)
      ..lineTo(p100.dx, p100.dy)
      ..lineTo(p110.dx, p110.dy)
      ..lineTo(p010.dx, p010.dy)
      ..close();
    canvas.drawPath(frontFace, Paint()..color = frontColor);

    // 4. Top Face (facing up at +Y: p010, p110, p111, p011)
    final Path topFace = Path()
      ..moveTo(p010.dx, p010.dy)
      ..lineTo(p110.dx, p110.dy)
      ..lineTo(p111.dx, p111.dy)
      ..lineTo(p011.dx, p011.dy)
      ..close();
    canvas.drawPath(topFace, Paint()..color = topColor);
  }

  /// Adds a warm, cozy golden-hour directional sunlight glow from top-left.
  void _drawSunlightAtmosphere(Canvas canvas, Size size) {
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final Paint sunGlowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.85, -0.90),
        radius: 1.35,
        colors: [
          const Color(0xFFFFE082).withValues(alpha: 0.22),
          const Color(0xFFFFD166).withValues(alpha: 0.06),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, sunGlowPaint);
  }

  /// Draws floating score, combo, and damage notifications projected in 3D space.
  void _drawFloatingNotices3D(Canvas canvas, Camera3DProjector cam) {
    for (final notice in game.notices) {
      final double alpha = notice.lifeTime.clamp(0.0, 1.0);
      final double worldY = 2.05 + (1.0 - alpha) * 1.45;
      final proj = cam.project(
        Vector3(notice.x, worldY, BaleSpawner.playerCatchZ),
      );

      final textSpan = TextSpan(
        text: notice.isDamage ? '💔 ${notice.text}' : notice.text,
        style: TextStyle(
          color: (notice.isDamage
                  ? Colors.white
                  : (notice.isSpecial ? FarmTheme.sunWarmYellow : Colors.white))
              .withValues(alpha: alpha),
          fontSize: notice.isDamage ? 15 : (notice.isSpecial ? 16 : 14),
          fontWeight: FontWeight.w900,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.8 * alpha),
              offset: const Offset(1.5, 1.5),
              blurRadius: 4,
            ),
          ],
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      if (notice.isDamage) {
        final Rect pillRect = Rect.fromCenter(
          center: proj.screenOffset,
          width: textPainter.width + 18,
          height: textPainter.height + 8,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(pillRect, const Radius.circular(14)),
          Paint()..color = FarmTheme.heartRed.withValues(alpha: 0.90 * alpha),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(pillRect, const Radius.circular(14)),
          Paint()
            ..color = FarmTheme.sunWarmYellow.withValues(alpha: 0.85 * alpha)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }

      textPainter.paint(
        canvas,
        Offset(
          proj.screenOffset.dx - (textPainter.width * 0.5),
          proj.screenOffset.dy - (textPainter.height * 0.5),
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant FarmScene3DPainter oldDelegate) => true;
}
