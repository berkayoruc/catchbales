import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../controllers/game_controller.dart';
import '../../utils/farm_theme.dart';

/// ShowcaseView-style interactive spotlight onboarding overlay:
/// Measures the exact RenderBox coordinates of each target widget via [GlobalKey]
/// to cut out a pixel-accurate transparent spotlight window and position a compact
/// floating tooltip card with a directional pointer arrow.
class HowToPlayOverlay extends StatefulWidget {
  final GameController game;
  final GlobalKey? bottomPadKey;
  final GlobalKey? organizeButtonKey;
  final GlobalKey? healthBarKey;
  final GlobalKey? ancestorStackKey;

  const HowToPlayOverlay({
    super.key,
    required this.game,
    this.bottomPadKey,
    this.organizeButtonKey,
    this.healthBarKey,
    this.ancestorStackKey,
  });

  @override
  State<HowToPlayOverlay> createState() => _HowToPlayOverlayState();
}

class _HowToPlayOverlayState extends State<HowToPlayOverlay> {
  final GlobalKey _overlayRootKey = GlobalKey();
  Rect? _measuredRect;
  int? _measuredStep;

  static const List<_ShowcaseStep> _steps = [
    _ShowcaseStep(
      stepBadge: 'ADIM 1 / 3',
      title: '3x3 RÖMORK HAREKETİ',
      subtitle: 'Kaydır veya dokun • Otomatik yakalar',
      icon: Icons.grid_view_rounded,
      accentColor: FarmTheme.sunWarmYellow,
      target: _SpotlightTarget.bottomPad,
    ),
    _ShowcaseStep(
      stepBadge: 'ADIM 2 / 3',
      title: 'RÖMORK & DÜZENLEME',
      subtitle: '45 balya doldur • Dokunup dengele',
      icon: Icons.view_in_ar_rounded,
      accentColor: FarmTheme.comboOrange,
      target: _SpotlightTarget.organizeButton,
    ),
    _ShowcaseStep(
      stepBadge: 'ADIM 3 / 3',
      title: 'CAN & HAYVANLAR',
      subtitle: 'Balyayı kaçırma • Hayvan tutarsan kısa stun',
      icon: Icons.favorite_rounded,
      accentColor: FarmTheme.heartRed,
      target: _SpotlightTarget.healthBar,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _schedulePostFrameMeasure();
  }

  @override
  void didUpdateWidget(covariant HowToPlayOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _schedulePostFrameMeasure();
  }

  void _schedulePostFrameMeasure() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final int currentIndex =
          widget.game.tutorialStep.clamp(0, _steps.length - 1);
      final Rect? fresh = _tryMeasureTargetRect(_steps[currentIndex].target);
      if (fresh != null &&
          (_measuredStep != currentIndex ||
              _measuredRect == null ||
              (_measuredRect!.topLeft - fresh.topLeft).distance > 0.5 ||
              (_measuredRect!.bottomRight - fresh.bottomRight).distance > 0.5)) {
        setState(() {
          _measuredStep = currentIndex;
          _measuredRect = fresh;
        });
      }
    });
  }

  GlobalKey? _keyForTarget(_SpotlightTarget target) {
    return switch (target) {
      _SpotlightTarget.bottomPad => widget.bottomPadKey,
      _SpotlightTarget.organizeButton => widget.organizeButtonKey,
      _SpotlightTarget.healthBar => widget.healthBarKey,
    };
  }

  Rect? _tryMeasureTargetRect(_SpotlightTarget target) {
    final GlobalKey? targetKey = _keyForTarget(target);
    if (targetKey == null) return null;

    final BuildContext? targetCtx = targetKey.currentContext;
    if (targetCtx == null) return null;

    final RenderObject? targetObj = targetCtx.findRenderObject();
    if (targetObj is! RenderBox || !targetObj.hasSize) return null;

    final RenderObject? ancestorObj =
        (_overlayRootKey.currentContext ?? widget.ancestorStackKey?.currentContext)
            ?.findRenderObject();
    if (ancestorObj is! RenderBox || !ancestorObj.hasSize) return null;

    final Offset topLeft =
        targetObj.localToGlobal(Offset.zero, ancestor: ancestorObj);
    final Size targetSize = targetObj.size;
    if (targetSize.width <= 0 || targetSize.height <= 0) return null;

    return (topLeft & targetSize).inflate(5.0);
  }

  Rect _resolveSpotlightRect(
    BuildContext context,
    Size size,
    _SpotlightTarget target,
    int stepIndex,
  ) {
    // 1. Prefer live RenderBox measurement from GlobalKey
    final Rect? liveRect = _tryMeasureTargetRect(target) ??
        (_measuredStep == stepIndex ? _measuredRect : null);
    if (liveRect != null) {
      final double left = liveRect.left.clamp(4.0, size.width - 20.0);
      final double top = liveRect.top.clamp(4.0, size.height - 20.0);
      final double right = liveRect.right.clamp(left + 16.0, size.width - 4.0);
      final double bottom =
          liveRect.bottom.clamp(top + 16.0, size.height - 4.0);
      return Rect.fromLTRB(left, top, right, bottom);
    }

    // 2. Fallback with SafeArea insets if rendered without keys
    final EdgeInsets safePadding = MediaQuery.paddingOf(context);
    final double w = size.width;
    final double h = size.height;
    final bool isCompact = w < 340;
    final double padHeight = isCompact ? 80.0 : 88.0;
    final double padWidth = math.min(w * 0.62, 224.0).clamp(160.0, 230.0);
    final double bottomY = h - safePadding.bottom - 10.0;

    return switch (target) {
      _SpotlightTarget.bottomPad => Rect.fromCenter(
          center: Offset(w * 0.5, bottomY - padHeight * 0.5),
          width: padWidth,
          height: padHeight,
        ).inflate(4.0),
      _SpotlightTarget.organizeButton => Rect.fromLTWH(
          12,
          safePadding.top + 8,
          140,
          36,
        ),
      _SpotlightTarget.healthBar => Rect.fromCenter(
          center: Offset(w * 0.58, safePadding.top + 26.0),
          width: 96,
          height: 36,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final int currentIndex =
        widget.game.tutorialStep.clamp(0, _steps.length - 1);
    final _ShowcaseStep step = _steps[currentIndex];
    final bool isLastStep = currentIndex == _steps.length - 1;

    return LayoutBuilder(
      key: _overlayRootKey,
      builder: (context, constraints) {
        final Size screenSize = Size(
          constraints.maxWidth,
          constraints.maxHeight,
        );
        final Rect spotlightRect = _resolveSpotlightRect(
          context,
          screenSize,
          step.target,
          currentIndex,
        );
        final bool isBottomTarget = step.target == _SpotlightTarget.bottomPad;

        // Compute horizontal arrow alignment relative to the tooltip width (screenSize.width - 32)
        final double tooltipWidth =
            (screenSize.width - 32.0).clamp(100.0, double.infinity);
        final double relativeCenterX =
            (spotlightRect.center.dx - 16.0) / tooltipWidth;
        final double arrowAlignmentX =
            (relativeCenterX * 2.0 - 1.0).clamp(-0.86, 0.86);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            widget.game.nextTutorialStep();
            _schedulePostFrameMeasure();
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Dark Overlay with Transparent Spotlight Cutout + Glowing Ring
              CustomPaint(
                painter: _ShowcaseSpotlightPainter(
                  spotlightRect: spotlightRect,
                  borderRadius: 20.0,
                  accentColor: step.accentColor,
                ),
                size: Size.infinite,
              ),

              // 2. Compact Floating Showcase Tooltip Bubble positioned near Spotlight
              Positioned(
                left: 16,
                right: 16,
                top: isBottomTarget ? null : (spotlightRect.bottom + 12),
                bottom: isBottomTarget
                    ? (screenSize.height - spotlightRect.top + 12)
                    : null,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Upward Pointer Arrow (when spotlight is above tooltip)
                    if (!isBottomTarget)
                      Align(
                        alignment: Alignment(arrowAlignmentX, 0.0),
                        child: CustomPaint(
                          size: const Size(18, 9),
                          painter: _TooltipArrowPainter(
                            color: FarmTheme.uiPillBg,
                            borderColor: step.accentColor,
                            pointsUp: true,
                          ),
                        ),
                      ),

                    // Compact Tooltip Card
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: FarmTheme.uiPillBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: step.accentColor,
                          width: 2.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.55),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Top row: Step Badge + Dots + Skip
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                step.stepBadge,
                                style: TextStyle(
                                  color: step.accentColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(_steps.length, (i) {
                                  final bool active = i == currentIndex;
                                  return Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 2.5,
                                    ),
                                    width: active ? 14 : 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: active
                                          ? step.accentColor
                                          : Colors.white24,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  );
                                }),
                              ),
                              GestureDetector(
                                onTap: widget.game.completeTutorial,
                                child: const Text(
                                  'GEÇ ✕',
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Main Row: Icon + Short Title/Subtitle + Action Pill
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      step.accentColor.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  step.icon,
                                  color: step.accentColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        step.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      step.subtitle,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: isLastStep
                                      ? FarmTheme.grassSoftGreen
                                      : step.accentColor,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  isLastStep ? 'BAŞLA' : 'İLERİ',
                                  style: TextStyle(
                                    color: isLastStep
                                        ? Colors.white
                                        : Colors.black87,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Downward Pointer Arrow (when spotlight is below tooltip)
                    if (isBottomTarget)
                      Align(
                        alignment: Alignment(arrowAlignmentX, 0.0),
                        child: CustomPaint(
                          size: const Size(18, 9),
                          painter: _TooltipArrowPainter(
                            color: FarmTheme.uiPillBg,
                            borderColor: step.accentColor,
                            pointsUp: false,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

enum _SpotlightTarget {
  bottomPad,
  organizeButton,
  healthBar,
}

class _ShowcaseStep {
  final String stepBadge;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final _SpotlightTarget target;

  const _ShowcaseStep({
    required this.stepBadge,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.target,
  });
}

/// Paints a full-screen dim overlay with a transparent rounded-rectangle cutout
/// over [spotlightRect] and a glowing highlight border around the cutout.
class _ShowcaseSpotlightPainter extends CustomPainter {
  final Rect spotlightRect;
  final double borderRadius;
  final Color accentColor;

  _ShowcaseSpotlightPainter({
    required this.spotlightRect,
    required this.borderRadius,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Path fullScreen = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final RRect holeRRect = RRect.fromRectAndRadius(
      spotlightRect,
      Radius.circular(borderRadius),
    );
    final Path holePath = Path()..addRRect(holeRRect);

    final Path overlayPath = Path.combine(
      PathOperation.difference,
      fullScreen,
      holePath,
    );

    canvas.drawPath(
      overlayPath,
      Paint()..color = Colors.black.withValues(alpha: 0.72),
    );

    // Outer soft glow around spotlight cutout
    canvas.drawRRect(
      holeRRect.inflate(3.0),
      Paint()
        ..color = accentColor.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0),
    );

    // Crisp inner border around spotlight cutout
    canvas.drawRRect(
      holeRRect,
      Paint()
        ..color = accentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(covariant _ShowcaseSpotlightPainter oldDelegate) {
    return oldDelegate.spotlightRect != spotlightRect ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.accentColor != accentColor;
  }
}

class _TooltipArrowPainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  final bool pointsUp;

  _TooltipArrowPainter({
    required this.color,
    required this.borderColor,
    required this.pointsUp,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = Path();
    if (pointsUp) {
      path.moveTo(0, size.height);
      path.lineTo(size.width * 0.5, 0);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width * 0.5, size.height);
      path.lineTo(size.width, 0);
    }
    path.close();

    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
  }

  @override
  bool shouldRepaint(covariant _TooltipArrowPainter oldDelegate) => false;
}
