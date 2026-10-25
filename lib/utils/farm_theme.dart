import 'package:flutter/material.dart';

/// Low-Poly Cozy Farm aesthetic theme:
/// Warm yellows, golden straw, soft emerald greens, rustic woods, and pastel accents.
class FarmTheme {
  FarmTheme._();

  // Typography
  static const String fontFamily = 'Fredoka';
  static const String displayFontFamily = 'LilitaOne';

  // Primary Palette
  static const Color sunWarmYellow = Color(0xFFFFD166);
  static const Color goldenStraw = Color(0xFFF4B942);
  static const Color deepStraw = Color(0xFFDDA128);
  static const Color tractorRed = Color(0xFFE63946);
  static const Color tractorRedDark = Color(0xFFC12735);
  static const Color grassSoftGreen = Color(0xFF7CB518);
  static const Color fieldLushGreen = Color(0xFF5C9E14);
  static const Color dirtPath = Color(0xFFC29B62);
  static const Color dirtPathDark = Color(0xFFA67C47);
  static const Color wagonWoodLight = Color(0xFFBA8C63);
  static const Color wagonWoodDark = Color(0xFF8B5E3C);
  static const Color wagonIron = Color(0xFF4A4E69);

  // UI & Overlay Colors
  static const Color uiPillBg = Color(0xDD22223B);
  static const Color uiPillBorder = Color(0x66F4B942);
  static const Color uiTextLight = Color(0xFFF8F9FA);
  static const Color uiTextGold = Color(0xFFFFE6A7);
  static const Color heartRed = Color(0xFFFF4D6D);
  static const Color comboOrange = Color(0xFFFF8500);
  static const Color stunBlue = Color(0xFF4EA8DE);
  static const Color skySoftBlue = Color(0xFFA2D2FF);

  // 3x3 Wagon Row Colors (Row 0: Front, Row 1: Middle, Row 2: Back)
  static const Color rowFrontCyan = Color(0xFF00E5FF);
  static const Color rowMiddleGold = Color(0xFFFFD166);
  static const Color rowBackViolet = Color(0xFFE066FF);

  static Color rowColor(int depthRow) {
    return switch (depthRow) {
      0 => rowFrontCyan,
      1 => rowMiddleGold,
      _ => rowBackViolet,
    };
  }

  // Box Shadows
  static List<BoxShadow> get cozyShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.18),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> buttonGlow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.4),
          blurRadius: 12,
          spreadRadius: 2,
          offset: const Offset(0, 3),
        ),
      ];
}
