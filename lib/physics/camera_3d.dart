import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

/// Projected 2D screen point with perspective depth scale and camera-space Z.
class ProjectedPoint {
  final Offset screenOffset;
  final double scale;
  final double depth;

  const ProjectedPoint({
    required this.screenOffset,
    required this.scale,
    required this.depth,
  });
}

/// Configuration for the Rive 3D Camera & Cozy Directional Lighting.
/// Matches the Rive Camera Script & Lighting Script parameters.
class Rive3DSceneConfig {
  /// Camera pitch in degrees (-50° to -60°, default -55° for 3rd-person isometric depth).
  final double pitchDegrees;

  /// Camera yaw in degrees (default 0° aligned with dirt path).
  final double yawDegrees;

  /// Camera Field of View in degrees (default 45°).
  final double fovDegrees;

  /// Camera position in 3D world space.
  final Vector3 cameraPosition;

  /// Normalized direction vector from the sun (Key Light) toward the scene.
  final Vector3 keyLightDirection;

  /// Warm sun key light color.
  final Color keyLightColor;

  /// Key light intensity (0.0 to 2.0).
  final double keyLightIntensity;

  /// Ambient fill light color.
  final Color ambientLightColor;

  /// Shadow darkness opacity (0.0 to 1.0).
  final double shadowDarkness;

  /// Shadow blur radius for soft cozy shadows.
  final double shadowSoftness;

  /// Camera zoom multiplier (1.0 in normal driving, ~1.45 in isometric wagon focus).
  final double zoomScale;

  /// Vertical screen Y anchor ratio for the wagon center (0.63 normal, 0.40 in cutscene).
  final double wagonCenterYRatio;

  const Rive3DSceneConfig({
    this.pitchDegrees = -55.0,
    this.yawDegrees = 0.0,
    this.fovDegrees = 45.0,
    required this.cameraPosition,
    required this.keyLightDirection,
    this.keyLightColor = const Color(0xFFFFE082),
    this.keyLightIntensity = 1.25,
    this.ambientLightColor = const Color(0xFFD8F3DC),
    this.shadowDarkness = 0.34,
    this.shadowSoftness = 6.0,
    this.zoomScale = 1.0,
    this.wagonCenterYRatio = 0.63,
  });

  factory Rive3DSceneConfig.cozyFarmDefault() {
    return Rive3DSceneConfig(
      pitchDegrees: -55.0,
      yawDegrees: 0.0,
      fovDegrees: 45.0,
      cameraPosition: Vector3(0.0, 9.2, -9.0),
      keyLightDirection: Vector3(0.42, -0.82, 0.38).normalized(),
      zoomScale: 1.0,
      wagonCenterYRatio: 0.63,
    );
  }

  /// Diagonal Isometric Wagon-Focus Camera Configuration for 7s Stack Organization:
  /// Rotates yaw to -38°, tilts pitch to -48°, zooms in (1.46x) and centers the wagon on screen.
  factory Rive3DSceneConfig.wagonIsometricFocus() {
    return Rive3DSceneConfig(
      pitchDegrees: -48.0,
      yawDegrees: -38.0,
      fovDegrees: 35.0,
      cameraPosition: Vector3(3.4, 7.6, -6.8),
      keyLightDirection: Vector3(0.42, -0.82, 0.38).normalized(),
      zoomScale: 1.46,
      wagonCenterYRatio: 0.41,
    );
  }

  /// Smoothly interpolates between two 3D camera configurations (0.0 -> 1.0).
  static Rive3DSceneConfig lerp(
    Rive3DSceneConfig a,
    Rive3DSceneConfig b,
    double t,
  ) {
    final double clamped = t.clamp(0.0, 1.0);
    return Rive3DSceneConfig(
      pitchDegrees: a.pitchDegrees + (b.pitchDegrees - a.pitchDegrees) * clamped,
      yawDegrees: a.yawDegrees + (b.yawDegrees - a.yawDegrees) * clamped,
      fovDegrees: a.fovDegrees + (b.fovDegrees - a.fovDegrees) * clamped,
      cameraPosition: Vector3(
        a.cameraPosition.x + (b.cameraPosition.x - a.cameraPosition.x) * clamped,
        a.cameraPosition.y + (b.cameraPosition.y - a.cameraPosition.y) * clamped,
        a.cameraPosition.z + (b.cameraPosition.z - a.cameraPosition.z) * clamped,
      ),
      keyLightDirection: a.keyLightDirection,
      keyLightColor: a.keyLightColor,
      keyLightIntensity:
          a.keyLightIntensity + (b.keyLightIntensity - a.keyLightIntensity) * clamped,
      ambientLightColor: a.ambientLightColor,
      shadowDarkness:
          a.shadowDarkness + (b.shadowDarkness - a.shadowDarkness) * clamped,
      shadowSoftness:
          a.shadowSoftness + (b.shadowSoftness - a.shadowSoftness) * clamped,
      zoomScale: a.zoomScale + (b.zoomScale - a.zoomScale) * clamped,
      wagonCenterYRatio:
          a.wagonCenterYRatio + (b.wagonCenterYRatio - a.wagonCenterYRatio) * clamped,
    );
  }
}

/// True 3D Camera Projector (-55° Pitch, 45° FOV) that transforms 3D World Space
/// coordinates (Vector3) into 2D Screen Viewport coordinates and computes
/// directional soft shadow projections.
class Camera3DProjector {
  final Rive3DSceneConfig config;
  final Size viewportSize;

  late final double _pitchRad;
  late final double _cosPitch;
  late final double _sinPitch;
  late final double _yawRad;
  late final double _cosYaw;
  late final double _sinYaw;
  late final double _focalLength;

  // Wagon center pivot in world space so camera orbits directly around the wagon
  static const double _pivotZ = -2.08;

  Camera3DProjector({
    required this.config,
    required this.viewportSize,
  }) {
    _pitchRad = config.pitchDegrees.abs() * (math.pi / 180.0);
    _cosPitch = math.cos(_pitchRad);
    _sinPitch = math.sin(_pitchRad);

    _yawRad = config.yawDegrees * (math.pi / 180.0);
    _cosYaw = math.cos(_yawRad);
    _sinYaw = math.sin(_yawRad);

    final double fovRad = config.fovDegrees * (math.pi / 180.0);
    _focalLength = (viewportSize.width * 0.5) / math.tan(fovRad * 0.5);
  }

  /// Projects a 3D world point (X: right, Y: up, Z: forward along road)
  /// into 2D screen coordinates with perspective foreshortening and 3D Yaw/Pitch orbit.
  ProjectedPoint project(Vector3 worldPos) {
    // 1. Orbit around the wagon center pivot (0.0, 0.0, _pivotZ) by yawDegrees
    final double dx = worldPos.x;
    final double dz = worldPos.z - _pivotZ;

    final double rotX = dx * _cosYaw - dz * _sinYaw;
    final double rotZ = _pivotZ + (dx * _sinYaw + dz * _cosYaw);

    // 2. Translate relative to camera anchor
    final double ry = worldPos.y - config.cameraPosition.y;
    final double rz = rotZ - config.cameraPosition.z;

    // 3. Rotate around X axis by pitch angle
    final double camZ = ry * _sinPitch + rz * _cosPitch;

    final double safeDepth = math.max(2.5, camZ);
    final double perspectiveScale = _focalLength / (safeDepth * 4.2);

    final double centerX = viewportSize.width * 0.5;

    final double depthFactor = 1.0 / (1.0 + (rotZ + 1.5) * 0.065);
    final double effectiveScale =
        depthFactor.clamp(0.45, 1.45) * config.zoomScale;

    final double referenceWidth =
        math.min(viewportSize.width, viewportSize.height * (9.0 / 16.0));
    final double unitPixels = referenceWidth * 0.22;
    final double screenX = centerX + (rotX * unitPixels * effectiveScale);

    final double zScreenOffset =
        (rotZ + 1.5) * unitPixels * _cosPitch * 0.92 * effectiveScale;
    final double yScreenOffset =
        worldPos.y * unitPixels * _sinPitch * 0.95 * effectiveScale;

    final double baseWagonScreenY =
        viewportSize.height * config.wagonCenterYRatio;
    final double screenY = baseWagonScreenY - zScreenOffset - yScreenOffset;

    return ProjectedPoint(
      screenOffset: Offset(screenX, screenY),
      scale: effectiveScale * (perspectiveScale > 0 ? 1.0 : 1.0),
      depth: rotZ,
    );
  }

  /// Projects a 3D point onto a horizontal shadow receiver plane (e.g. ground Y=0 or wagon floor Y=0.65)
  /// along the directional Key Light vector.
  ProjectedPoint projectShadow(Vector3 worldPos, {double receiverPlaneY = 0.0}) {
    final double heightAbovePlane = math.max(0.0, worldPos.y - receiverPlaneY);
    final Vector3 lightDir = config.keyLightDirection;

    // Ray-plane intersection along keyLightDirection where lightDir.y < 0
    final double t = lightDir.y.abs() > 0.01 ? (heightAbovePlane / lightDir.y.abs()) : 0.0;
    final Vector3 shadowWorldPos = Vector3(
      worldPos.x + lightDir.x * t * 0.55,
      receiverPlaneY,
      worldPos.z - lightDir.z * t * 0.45,
    );

    return project(shadowWorldPos);
  }

  /// Computes directional diffuse lighting brightness (0.35 to 1.25) for a 3D surface normal.
  double computeFaceLighting(Vector3 surfaceNormal) {
    final Vector3 n = surfaceNormal.normalized();
    // Vector pointing toward the light source
    final Vector3 toLight = -config.keyLightDirection;
    final double ndotl = math.max(0.0, n.dot(toLight));
    // Ambient (0.48) + Directional Key Light (0.72 * ndotl)
    return (0.48 + 0.72 * ndotl * config.keyLightIntensity).clamp(0.35, 1.30);
  }

  /// Shades a base color using a 3D surface normal and warm sunlight tint.
  Color shadeColor(Color baseColor, Vector3 surfaceNormal) {
    final double intensity = computeFaceLighting(surfaceNormal);
    final hsl = HSLColor.fromColor(baseColor);
    final double newLightness = (hsl.lightness * intensity).clamp(0.08, 0.94);
    // Shift slightly warmer when sunlit, slightly cooler when in shadow
    final double hueShift = intensity > 1.0 ? -2.0 : 4.0;
    return hsl
        .withHue((hsl.hue + hueShift) % 360.0)
        .withLightness(newLightness)
        .toColor();
  }
}
