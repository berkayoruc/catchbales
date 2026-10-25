import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';

/// All object types that can be ejected from the baler toward the wagon.
enum ThrownObjectType {
  bale,
  chicken,
  rooster,
  duck,
  sheep,
  cow,
  cat,
  dog,
  bird;

  bool get isAnimal => this != ThrownObjectType.bale;

  String get displayNameEn => switch (this) {
        ThrownObjectType.bale => 'Straw Bale',
        ThrownObjectType.chicken => 'Chicken',
        ThrownObjectType.rooster => 'Rooster',
        ThrownObjectType.duck => 'Duck',
        ThrownObjectType.sheep => 'Sheep',
        ThrownObjectType.cow => 'Cow',
        ThrownObjectType.cat => 'Cat',
        ThrownObjectType.dog => 'Dog',
        ThrownObjectType.bird => 'Bird',
      };

  String get displayName => displayNameEn;

  String get displayNameTr => switch (this) {
        ThrownObjectType.bale => 'Saman Balyası',
        ThrownObjectType.chicken => 'Tavuk',
        ThrownObjectType.rooster => 'Horoz',
        ThrownObjectType.duck => 'Ördek',
        ThrownObjectType.sheep => 'Koyun',
        ThrownObjectType.cow => 'İnek',
        ThrownObjectType.cat => 'Kedi',
        ThrownObjectType.dog => 'Köpek',
        ThrownObjectType.bird => 'Kuş',
      };

  String get emoji => switch (this) {
        ThrownObjectType.bale => '🌾',
        ThrownObjectType.chicken => '🐔',
        ThrownObjectType.rooster => '🐓',
        ThrownObjectType.duck => '🦆',
        ThrownObjectType.sheep => '🐑',
        ThrownObjectType.cow => '🐄',
        ThrownObjectType.cat => '🐱',
        ThrownObjectType.dog => '🐶',
        ThrownObjectType.bird => '🐦',
      };
}

/// State of an individual thrown bale or farm animal in the game loop.
enum BaleState {
  inFlight,
  caught,
  missed,
  stunHit,
  stacked,
  overflowOutside,
  overflowInside,
  escaping,
}

/// Represents a single low-poly straw bale or farm animal with 3D trajectory and orientation.
class StrawBale {
  final String id;
  final ThrownObjectType objectType;
  final Vector3 startPos;
  final Vector3 targetPos;
  final double arcHeight;
  final double flightDuration; // In seconds
  final Vector3 angularVelocity; // Random torque in rad/s
  final double colorHueVariation;

  // Runtime dynamic state
  double progress = 0.0; // 0.0 -> 1.0
  Vector3 currentPos = Vector3.zero();
  Vector3 currentRotation = Vector3.zero();
  BaleState state = BaleState.inFlight;

  // Timer & velocity for missed-on-floor, >5 row overflow, or animal escape physics
  double missedDisplayTimer = 0.0;
  static const double maxMissedDisplayDuration = 0.90;
  static const double maxEscapeDuration = 1.40;
  Vector3 tumbleVelocity = Vector3.zero();
  bool wasCaughtBeforeEscape = false;

  // Placement grid coordinates when stacked in wagon
  int? gridCol;
  int? gridRow;
  double wobbleOffset = 0.0;

  StrawBale({
    required this.id,
    this.objectType = ThrownObjectType.bale,
    required this.startPos,
    required this.targetPos,
    required this.arcHeight,
    required this.flightDuration,
    required this.angularVelocity,
    this.colorHueVariation = 0.0,
  }) {
    currentPos.setFrom(startPos);
  }

  /// Updates bale/animal position and rotation along its 3D parabolic trajectory,
  /// or updates its post-landing missed/overflow/escaping physics state.
  void update(double dt) {
    if (state == BaleState.inFlight) {
      progress += dt / flightDuration;
      if (progress > 1.0) {
        progress = 1.0;
      }

      // Parabolic interpolation:
      // Linear interpolation between start and target in X and Z
      final double px = startPos.x + (targetPos.x - startPos.x) * progress;
      final double pz = startPos.z + (targetPos.z - startPos.z) * progress;

      // Parabolic arc in Y (vertical height): 4 * h * t * (1 - t)
      final double linearY = startPos.y + (targetPos.y - startPos.y) * progress;
      final double arcY = 4.0 * arcHeight * progress * (1.0 - progress);
      final double py = linearY + arcY;

      currentPos.setValues(px, py, pz);

      // Update 3D rotational tumble (animals wiggle gently instead of full upside-down tumble)
      if (objectType.isAnimal) {
        wobbleOffset += dt * 10.0;
        currentRotation.x = math.sin(wobbleOffset * 1.4) * 0.18;
        currentRotation.y += angularVelocity.y * dt * 0.35;
        currentRotation.z = math.cos(wobbleOffset * 1.8) * 0.22;
      } else {
        currentRotation.x += angularVelocity.x * dt;
        currentRotation.y += angularVelocity.y * dt;
        currentRotation.z += angularVelocity.z * dt;
      }
    } else if (state == BaleState.escaping) {
      // Animal scurrying / hopping away across the wagon floor and jumping off!
      missedDisplayTimer -= dt;
      wobbleOffset += dt * 16.0;

      currentPos.x += tumbleVelocity.x * dt;
      currentPos.z += tumbleVelocity.z * dt;

      final bool insideWagonBounds =
          currentPos.x.abs() <= 1.38 && currentPos.z >= -3.25;
      if (insideWagonBounds) {
        // Energetic hopping bounce on the wooden wagon floor
        final double hop = math.sin(wobbleOffset * 1.35).abs() * 0.26;
        currentPos.y = 0.64 + hop;
      } else {
        // Leaping over the wagon side wall / tailgate down toward the meadow
        tumbleVelocity.y -= 9.2 * dt;
        currentPos.y = math.max(0.05, currentPos.y + tumbleVelocity.y * dt);
      }
    } else if (state == BaleState.missed ||
        state == BaleState.overflowOutside ||
        state == BaleState.overflowInside) {
      // Advance physics tumble & countdown timer before disappearing
      missedDisplayTimer -= dt;

      if (tumbleVelocity.length2 > 0.001) {
        currentPos.x += tumbleVelocity.x * dt;
        currentPos.y += tumbleVelocity.y * dt;
        currentPos.z += tumbleVelocity.z * dt;
        // Gravity pull on tumbling overflow bale
        tumbleVelocity.y -= 9.8 * dt;

        // Ground / floor bounce clamp
        final double minY = state == BaleState.overflowOutside ? 0.18 : 0.75;
        if (currentPos.y < minY) {
          currentPos.y = minY;
          tumbleVelocity.y = -tumbleVelocity.y * 0.35;
          tumbleVelocity.x *= 0.7;
          tumbleVelocity.z *= 0.7;
        }
      }

      currentRotation.z += angularVelocity.z * dt * 0.6;
    }
  }

  /// Opacity (0.0 to 1.0) for missed/overflow/escaping objects fading out at the end.
  double get fadeOpacity {
    if (state == BaleState.escaping) {
      return (missedDisplayTimer / 0.35).clamp(0.0, 1.0);
    }
    if (state == BaleState.missed ||
        state == BaleState.overflowOutside ||
        state == BaleState.overflowInside) {
      return (missedDisplayTimer / maxMissedDisplayDuration).clamp(0.0, 1.0);
    }
    return 1.0;
  }

  /// True if the bale is within the catch timing window (e.g. 70% to 100% of flight).
  bool get isInCatchWindow =>
      progress >= 0.70 && progress <= 1.0 && state == BaleState.inFlight;

  /// Clones with new state or properties
  StrawBale copyWithState(BaleState newState) {
    final copy = StrawBale(
      id: id,
      objectType: objectType,
      startPos: startPos,
      targetPos: targetPos,
      arcHeight: arcHeight,
      flightDuration: flightDuration,
      angularVelocity: angularVelocity,
      colorHueVariation: colorHueVariation,
    );
    copy.progress = progress;
    copy.currentPos.setFrom(currentPos);
    copy.currentRotation.setFrom(currentRotation);
    copy.state = newState;
    copy.missedDisplayTimer = missedDisplayTimer;
    copy.tumbleVelocity.setFrom(tumbleVelocity);
    copy.wasCaughtBeforeEscape = wasCaughtBeforeEscape;
    copy.gridCol = gridCol;
    copy.gridRow = gridRow;
    copy.wobbleOffset = wobbleOffset;
    return copy;
  }
}
