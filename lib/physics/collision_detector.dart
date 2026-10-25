import 'dart:math' as math;
import '../models/bale.dart';
import 'bale_spawner.dart';

enum CollisionOutcomeType {
  none,
  caught,
  stunned,
  missedFloor,
}

class CollisionResult {
  final CollisionOutcomeType outcome;
  final StrawBale bale;
  final double scoreEarned;
  final bool isPerfectCatch;

  CollisionResult({
    required this.outcome,
    required this.bale,
    this.scoreEarned = 0,
    this.isPerfectCatch = false,
  });
}

/// Evaluates 3D interception and impact physics between incoming bales and the player
/// across the 3x3x5 wagon grid (X: Left-Right, Z: Front-Back, Y: Stack Height).
class CollisionDetector {
  // Catch interception tolerance in 3D wagon units
  static const double catchRadius = 0.72;
  static const double directHitRadius = 0.48;

  // Camera pitch foreshortening factor: cos(55°) ≈ 0.5736
  static final double _cameraPitchCos = math.cos(55.0 * math.pi / 180.0);

  /// Computes the 3D camera-synchronized horizontal & depth distance between
  /// the farmer (at [playerX], [playerZ]) and an incoming bale.
  double computePerspectiveDistance(
    StrawBale bale,
    double playerX, [
    double playerZ = BaleSpawner.playerCatchZ,
  ]) {
    final double effectiveBaleX =
        bale.currentPos.x * 0.35 + bale.targetPos.x * 0.65;
    final double dx = (playerX - effectiveBaleX).abs();

    final double dz =
        (playerZ - bale.targetPos.z).abs() * _cameraPitchCos * 0.65;

    return math.sqrt(dx * dx + dz * dz);
  }

  /// Evaluates an active action catch attempt (when player presses the Hand / Catch button).
  /// Returns the best intercepted bale if any is in the 3D camera catch window.
  CollisionResult? evaluateManualCatch({
    required List<StrawBale> activeBales,
    required double playerX,
    double playerZ = BaleSpawner.playerCatchZ,
    required bool isStunned,
  }) {
    if (isStunned) return null;

    StrawBale? bestTarget;
    double minDistance = double.infinity;

    for (final bale in activeBales) {
      if (bale.state != BaleState.inFlight) continue;

      if (bale.progress >= 0.60 && bale.progress <= 1.0) {
        final double directDx = (playerX - bale.currentPos.x).abs();
        final double directDz = (playerZ - bale.targetPos.z).abs() * 0.55;
        final double directDist = math.sqrt(directDx * directDx + directDz * directDz);
        final double perspDist =
            computePerspectiveDistance(bale, playerX, playerZ);
        final double dist = math.min(directDist, perspDist);

        if (dist <= catchRadius && dist < minDistance) {
          minDistance = dist;
          bestTarget = bale;
        }
      }
    }

    if (bestTarget != null) {
      final isPerfect = minDistance < (catchRadius * 0.45);
      final points = isPerfect ? 150.0 : 100.0;
      return CollisionResult(
        outcome: CollisionOutcomeType.caught,
        bale: bestTarget,
        scoreEarned: points,
        isPerfectCatch: isPerfect,
      );
    }

    return null;
  }

  /// Evaluates passive landing collisions as bales reach the wagon floor plane (progress >= 0.95).
  /// If player is standing directly under an uncaught bale, player gets hit and stunned!
  List<CollisionResult> evaluateLandingCollisions({
    required List<StrawBale> activeBales,
    required double playerX,
    double playerZ = BaleSpawner.playerCatchZ,
    required bool isStunned,
  }) {
    final List<CollisionResult> results = [];

    for (final bale in activeBales) {
      if (bale.state != BaleState.inFlight) continue;

      if (bale.progress >= 0.95) {
        final double dx = (playerX - bale.targetPos.x).abs();
        final double dz = (playerZ - bale.targetPos.z).abs() * 0.65;
        final double distToPlayer = math.sqrt(dx * dx + dz * dz);

        if (distToPlayer <= directHitRadius) {
          // Bale impacts the farmer! Ragdoll / Stun triggered!
          results.add(CollisionResult(
            outcome: CollisionOutcomeType.stunned,
            bale: bale,
          ));
        } else {
          // Bale landed on the wagon floor uncaught
          results.add(CollisionResult(
            outcome: CollisionOutcomeType.missedFloor,
            bale: bale,
          ));
        }
      }
    }

    return results;
  }
}
