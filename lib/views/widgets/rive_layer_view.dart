import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive/rive.dart';
import '../../controllers/game_controller.dart';

/// Rive Animation View Layer that loads the `.riv` asset and attaches to the
/// RiveGameController bridge. If the `.riv` asset isn't present in the assets
/// folder yet, it cleanly notifies and acts as a placeholder without crashing.
class RiveLayerView extends StatefulWidget {
  final GameController game;

  const RiveLayerView({
    super.key,
    required this.game,
  });

  @override
  State<RiveLayerView> createState() => _RiveLayerViewState();
}

class _RiveLayerViewState extends State<RiveLayerView> {
  bool _hasAsset = false;
  bool _checkedAsset = false;

  @override
  void initState() {
    super.initState();
    _checkRiveAsset();
  }

  Future<void> _checkRiveAsset() async {
    try {
      await rootBundle.load('assets/rive/hay_bale_game.riv');
      if (mounted) {
        setState(() {
          _hasAsset = true;
          _checkedAsset = true;
        });
      }
    } catch (_) {
      // Asset not found yet in assets bundle; fallback cleanly
      if (mounted) {
        setState(() {
          _hasAsset = false;
          _checkedAsset = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_checkedAsset) {
      return const SizedBox.shrink();
    }

    if (_hasAsset) {
      return RiveAnimation.asset(
        'assets/rive/hay_bale_game.riv',
        fit: BoxFit.cover,
        alignment: Alignment.center,
        onInit: (artboard) {
          widget.game.riveBridge.onRiveInit(artboard);
        },
      );
    }

    // When no .riv file is placed yet, return an empty container
    // (the FarmCanvasView provides complete custom 3D isometric rendering).
    return const SizedBox.shrink();
  }
}
