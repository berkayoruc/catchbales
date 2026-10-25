import 'package:flutter/services.dart';

/// Audio and Haptic feedback controller for the Farm Game.
class AudioHapticsService {
  static bool soundEnabled = true;
  static bool hapticsEnabled = true;

  static void playCatchSound() {
    if (!soundEnabled) return;
    SystemSound.play(SystemSoundType.click);
  }

  static void playStunSound() {
    if (!soundEnabled) return;
    SystemSound.play(SystemSoundType.alert);
  }

  static void triggerCatchHaptic() {
    if (!hapticsEnabled) return;
    HapticFeedback.lightImpact();
  }

  static void triggerStunHaptic() {
    if (!hapticsEnabled) return;
    HapticFeedback.heavyImpact();
    // Subsequent rumble for stun impact
    Future.delayed(const Duration(milliseconds: 120), () {
      if (hapticsEnabled) {
        HapticFeedback.mediumImpact();
      }
    });
  }

  static void triggerSpecialHaptic() {
    if (!hapticsEnabled) return;
    HapticFeedback.mediumImpact();
  }
}
