# Rive Asset Integration Guide

Place your exported Rive animation file at:
```
assets/rive/hay_bale_game.riv
```

### State Machine Configuration
The game controller (`RiveGameController` in `lib/controllers/rive_game_controller.dart`) connects to a State Machine named:
* **`FarmGameStateMachine`** (or the default state machine in your `.riv` file)

### Exposed State Machine Inputs
The controller automatically binds to the following inputs:

| Input Name | Type | Value Range | Description |
|---|---|---|---|
| `MoveX` | Number (`SMIInput<double>`) | `-1.0` to `1.0` | Farmer character horizontal position inside the wagon |
| `StunTrigger` | Trigger (`SMITrigger`) | Trigger | Fired when bale hits character to activate ragdoll/stun animation |
| `CatchSuccess` / `CatchTrigger` | Trigger (`SMITrigger`) | Trigger | Fired when a bale is successfully caught |
| `HealthValue` / `Health` | Number (`SMIInput<double>`) | `0.0` to `100.0` | Current player health value |
| `GameMode` | Number (`SMIInput<double>`) | `0.0` (Arcade) / `1.0` (Puzzle) | Active game mode |
| `TrailerWobble` / `WobbleIntensity` | Number (`SMIInput<double>`) | `0.0` to `1.0` | Amount of trailer tilt & shake from bumpy terrain |

### Built-in Fallback Rendering
If `hay_bale_game.riv` is not present, the game automatically uses the built-in 3D Low-Poly Isometric Farm Canvas (`FarmCanvasView`) which features complete tractor, baler, parabolic ballistic trajectory simulation, wagon wobble physics, character animations, and stacking grids.
