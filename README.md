# Hay Bale Stacking Game 🚜🌾
### Mobile Farming 3D Arcade Game in Flutter & Rive

A mobile farming 3D arcade game built with **Flutter**, **Dart**, the official **Rive Flutter SDK (`rive`)**, **Provider**, and **Vector Math**.

---

## 📱 Features & Architecture

### 1. Visual Style & 9:16 Mobile Viewport
- **Aesthetic:** Low-Poly Cozy Farm (warm yellows, soft greens, pastel tones, soft shadows).
- **Format:** Responsive 9:16 Vertical Portrait Mode designed for iOS & Android mobile screens.
- **Visual Scene:** A red tractor towing a baler machine along a scrolling dirt path. The baler throws straw bales backwards along 3D parabolic arcs into an open wooden trailer where the farmer character catches and stacks them.

### 2. HUD & Touch Controls Overlay
- **Top HUD Panel:**
  - Oval pill containers for `SCORE` (e.g. 1,250), `LIVES` (dynamic health bar / percentage), and `BALES CAUGHT` (or `QUOTA` in Puzzle mode).
  - Settings Gear icon button opening a full modal dialog (Mode switch, Sound, Haptics, Restart, Instructions).
  - Combo Multiplier indicator badge (`2x`, `3x`, `4x`).
- **Bottom Touch Controls Overlay:**
  - Left & Right arrow buttons (`<` and `>`) supporting continuous hold and tap movement inside wagon boundaries.
  - Action button (`CATCH` / Hand icon) for intercepting bales inside the timing hit window.
  - Special ability button (`SPECIAL` / `BREAK STUN`) with real-time circular cooldown indicator.

### 3. Rive 3D & State Machine Bridge (`rive_bridge.dart` / `RiveGameController`)
Dedicated controller linking Flutter physics and inputs to the `.riv` asset (`FarmGameStateMachine`):
- `MoveX` (`SMIInput<double>`): Farmer X position inside wagon (`-1.0` to `1.0`).
- `StunTrigger` (`SMITrigger`): Fired when a bale impacts the player, activating a 3-second ragdoll/stun animation.
- `CatchSuccess` (`SMITrigger`): Fired upon successful bale catch.
- `HealthValue` (`SMIInput<double>`): Player health (`0.0` to `100.0`).
- `GameMode` (`SMIInput<double>`): `0.0` for Arcade Mode, `1.0` for Puzzle/Jenga Mode.
- `TrailerWobble` (`SMIInput<double>`): Trailer vibration intensity driven by terrain bumps.

### 4. Game Modes & Physics Engine
1. **`BaleSpawner` (`vector_math.Vector3`):**
   - Calculates 3D parabolic trajectories from the baler pipe `(0.0, 3.2, 5.0)` to landing targets within the wagon bed.
   - Applies 3D rotational tumble (angular torque) and score-dependent launch frequency.
2. **`CollisionDetector`:**
   - Evaluates timing windows (`progress >= 0.70`) and spatial distance tolerance (`catchRadius`).
   - Successful catch -> Score points, combo increase, snap to wagon stack.
   - Direct impact without catch -> Stun state for 3 seconds, -25 HP damage, haptics & camera shake.
3. **`GameModeManager`:**
   - **Arcade Runner:** Infinite high-score runner with auto-grid alignment and ramping speed.
   - **Jenga Stacker:** Level quota where terrain bumps cause wagon wobble, challenging stack balance.

---

## 🛠️ Project Structure

```
lib/
├── controllers/
│   ├── game_controller.dart        # Central game loop, combo, stats, & controls
│   └── rive_game_controller.dart   # Rive State Machine Bridge (inputs & triggers)
├── models/
│   ├── bale.dart                   # Straw bale 3D position, trajectory, state
│   ├── game_mode.dart              # Arcade vs Puzzle/Jenga modes
│   └── stack_slot.dart             # Wagon bed stack grid & tilt representation
├── physics/
│   ├── bale_spawner.dart           # Vector3 parabolic trajectory calculations
│   ├── collision_detector.dart     # Catch windows & direct hit detection
│   └── trailer_physics.dart        # Suspension, bumpiness, & tilt wobble
├── utils/
│   ├── audio_haptics.dart          # Sound cues & haptic feedback
│   └── farm_theme.dart             # Low-poly cozy color palette & shadows
├── views/
│   ├── game_screen.dart            # 9:16 mobile container & game loop ticker
│   └── widgets/
│       ├── farm_canvas_view.dart   # Low-poly 3D isometric custom farm renderer
│       ├── floating_score_widget.dart
│       ├── game_over_dialog.dart   # High-score modal with stats breakdown
│       ├── rive_layer_view.dart    # Rive animation player with asset fallback
│       ├── settings_dialog.dart    # Audio, haptics, & mode selection
│       ├── top_hud_panel.dart      # Oval pills for score, lives, quota
│       └── touch_controls_overlay.dart # Left/Right, Catch, & Special buttons
└── main.dart                       # App initialization & portrait lock
```

---

## 🚀 Running the Game

```bash
cd farm_bale_game
flutter pub get
flutter run
```

To run the automated test suite:
```bash
flutter test
```
