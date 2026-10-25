import 'package:flutter/material.dart';
import '../../controllers/game_controller.dart';
import '../../models/game_mode.dart';
import '../../utils/audio_haptics.dart';
import '../../utils/farm_theme.dart';
import '../main_menu_screen.dart';

/// Cozy settings & pause modal dialog.
class SettingsDialog extends StatefulWidget {
  final GameController game;

  const SettingsDialog({super.key, required this.game});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late bool _sound;
  late bool _haptics;
  late GameModeType _selectedMode;

  @override
  void initState() {
    super.initState();
    _sound = AudioHapticsService.soundEnabled;
    _haptics = AudioHapticsService.hapticsEnabled;
    _selectedMode = widget.game.gameMode;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: FarmTheme.uiPillBg,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: FarmTheme.uiPillBorder, width: 2.0),
          boxShadow: FarmTheme.cozyShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.settings_rounded,
                      color: FarmTheme.sunWarmYellow,
                      size: 26,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'SETTINGS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 24),

            // Game Mode Switcher
            Row(
              children: [
                Expanded(
                  child: _buildModeOption(
                    title: 'ARCADE',
                    mode: GameModeType.arcade,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildModeOption(
                    title: 'JENGA',
                    mode: GameModeType.puzzle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Audio & Haptics Toggles
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Sound', style: TextStyle(color: Colors.white)),
              value: _sound,
              activeThumbImage: null,
              activeTrackColor: FarmTheme.goldenStraw,
              onChanged: (val) {
                setState(() => _sound = val);
                AudioHapticsService.soundEnabled = val;
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Haptics', style: TextStyle(color: Colors.white)),
              value: _haptics,
              activeTrackColor: FarmTheme.goldenStraw,
              onChanged: (val) {
                setState(() => _haptics = val);
                AudioHapticsService.hapticsEnabled = val;
                if (val) AudioHapticsService.triggerSpecialHaptic();
              },
            ),
            const SizedBox(height: 12),

            // Action Buttons: Main Menu, Restart & Resume
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white30),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      widget.game.resetGame();
                      Navigator.of(context).pop();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const MainMenuScreen(),
                        ),
                      );
                    },
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('MENU'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: FarmTheme.heartRed,
                      side: const BorderSide(color: FarmTheme.heartRed),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      widget.game.resetGame();
                      Navigator.of(context).pop();
                    },
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('RESTART'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FarmTheme.goldenStraw,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'RESUME',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeOption({
    required String title,
    required GameModeType mode,
  }) {
    final bool isSelected = _selectedMode == mode;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedMode = mode);
        widget.game.switchMode(mode);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? FarmTheme.goldenStraw.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? FarmTheme.goldenStraw : Colors.white24,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? FarmTheme.sunWarmYellow : Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
