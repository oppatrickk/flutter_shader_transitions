import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'shader_registry.dart';
import 'transition_config.dart';

/// Applies a [ShaderTransition] as an alpha mask to [child] using
/// [BlendMode.dstIn].
///
/// This is the core rendering primitive for all shader transitions.
///
/// ## How it works (no cover)
///
/// The shader outputs RGBA where only the **alpha** matters. [ShaderMask]
/// with [BlendMode.dstIn] multiplies the child's alpha by the shader's alpha
/// — the child is transparent where `shader.alpha == 0` and opaque where it
/// is `1`. Combined with `opaque: false` on the enclosing route, the
/// outgoing page shows through the transparent region.
///
/// ## How it works (with [TransitionCover])
///
/// When `transition.cover != null` the transition is a three-phase sequence
/// backed by **two** shader instances:
///
/// 1. **Wipe in** — the cover color sweeps over the outgoing page.
/// 2. **Hold** — for `cover.hold` the screen stays fully covered.
/// 3. **Wipe out** — the incoming page sweeps over the cover.
///
/// With `cover.hold == Duration.zero` phases 1 and 3 abut: a continuous
/// cross-fade through the color.
///
/// ## Uniform layout v3
///
/// Every `.frag` shares this layout, set unconditionally (unused slots are
/// harmless):
/// ```
/// 0    uProgress   : float  per-phase progress 0→1
/// 1-2  uResolution : vec2   bounds size px
/// 3-4  uOrigin     : vec2   normalized [0,1] focal point
/// 5-6  uDirection  : vec2   normalized sweep vector
/// 7    uFeather    : float  edge softness px
/// 8    uCellSize   : float  diamond grid px
/// 9    uRotation   : float  radians
/// 10   uInvert     : float  0/1 reverse flag
/// 11   uSectors    : float  clock sector count
/// 12   uSides      : float  polygon side count
/// ```
class ShaderMaskTransition extends StatefulWidget {
  const ShaderMaskTransition({
    super.key,
    required this.animation,
    required this.transition,
    required this.child,
    this.onStart,
    this.onComplete,
    this.onProgress,
  });

  /// The route animation (0.0 → 1.0 on push, 1.0 → 0.0 on pop).
  final Animation<double> animation;

  /// The transition to render (sealed: diamond / circle / wipe).
  final ShaderTransition transition;

  /// The incoming page widget.
  final Widget child;

  /// Called when the forward animation starts. Use it to trigger sound — the
  /// app plays its own audio; this package bundles none.
  final VoidCallback? onStart;

  /// Called when the forward animation completes (reaches 1.0).
  final VoidCallback? onComplete;

  /// Called every animation tick with the raw `animation.value`.
  final ValueChanged<double>? onProgress;

  @override
  State<ShaderMaskTransition> createState() => _ShaderMaskTransitionState();
}

class _ShaderMaskTransitionState extends State<ShaderMaskTransition> {
  ui.FragmentShader? _pageShader;
  // Created only when transition.cover != null — the cover wipe-in needs
  // uniform state independent of the page wipe-out.
  ui.FragmentShader? _coverShader;

  @override
  void initState() {
    super.initState();
    _pageShader =
        ShaderRegistry.instance.createShader(widget.transition.shaderKey);
    if (widget.transition.cover != null) {
      _coverShader =
          ShaderRegistry.instance.createShader(widget.transition.shaderKey);
    }
    widget.animation.addStatusListener(_onStatus);
    if (widget.onProgress != null) {
      widget.animation.addListener(_onTick);
    }
  }

  void _onStatus(AnimationStatus status) {
    switch (status) {
      case AnimationStatus.forward:
        widget.onStart?.call();
      case AnimationStatus.completed:
        widget.onComplete?.call();
      case AnimationStatus.dismissed:
      case AnimationStatus.reverse:
        break;
    }
  }

  void _onTick() => widget.onProgress?.call(widget.animation.value);

  @override
  void dispose() {
    widget.animation.removeStatusListener(_onStatus);
    if (widget.onProgress != null) {
      widget.animation.removeListener(_onTick);
    }
    _pageShader?.dispose();
    _coverShader?.dispose();
    super.dispose();
  }

  // Cover hold can never exceed this fraction of the timeline — each wipe is
  // guaranteed ≥ (1 - this) / 2, even if the caller passes an over-long hold.
  static const double _maxCoverFraction = 0.75;

  /// Maps `animation.value ∈ [0,1]` to per-phase progresses for the cover
  /// and page shaders.
  ({double cover, double page}) _phaseProgresses(double t) {
    final totalMs = widget.transition.duration.inMilliseconds.toDouble();
    if (totalMs <= 0) return (cover: 1.0, page: 1.0);
    final maxHoldMs = totalMs * _maxCoverFraction;
    final requestedHoldMs =
        (widget.transition.cover?.hold.inMilliseconds ?? 0).toDouble();
    final holdMs = requestedHoldMs.clamp(0.0, maxHoldMs);
    final wipeMs = (totalMs - holdMs) / 2.0;
    final phase1End = wipeMs / totalMs;
    final phase2End = (wipeMs + holdMs) / totalMs;

    if (t < phase1End) return (cover: t / phase1End, page: 0.0);
    if (t < phase2End) return (cover: 1.0, page: 0.0);
    return (cover: 1.0, page: (t - phase2End) / (1.0 - phase2End));
  }

  /// Per-type geometry for the unified uniform block (layout v3).
  ({
    double dx,
    double dy,
    double ox,
    double oy,
    double feather,
    double cellSize,
    double rotation,
    double sectors,
    double sides,
  }) _geometry() {
    final tr = widget.transition;
    switch (tr) {
      case DiamondTransition():
        final (dx, dy) = tr.direction.vector;
        return (
          dx: dx,
          dy: dy,
          ox: 0.5,
          oy: 0.5,
          feather: tr.feather,
          cellSize: tr.cellSize,
          rotation: 0.0,
          sectors: 1.0,
          sides: 4.0,
        );
      case WipeTransition():
        final (dx, dy) = tr.direction.vector;
        return (
          dx: dx,
          dy: dy,
          ox: 0.5,
          oy: 0.5,
          feather: tr.softness,
          cellSize: 0.0,
          rotation: tr.rotation,
          sectors: 1.0,
          sides: 4.0,
        );
      case CircleTransition():
        return (
          dx: 1.0,
          dy: 0.0,
          // Alignment (-1..1) → normalized (0..1).
          ox: (tr.origin.x + 1.0) / 2.0,
          oy: (tr.origin.y + 1.0) / 2.0,
          feather: tr.feather,
          cellSize: 0.0,
          rotation: 0.0,
          sectors: 1.0,
          sides: 64.0,
        );
      case ClockTransition():
        return (
          dx: 1.0,
          dy: 0.0,
          ox: (tr.origin.x + 1.0) / 2.0,
          oy: (tr.origin.y + 1.0) / 2.0,
          feather: tr.feather,
          cellSize: 0.0,
          rotation: tr.rotation,
          sectors: tr.sectors.toDouble(),
          sides: 4.0,
        );
      case PolygonTransition():
        return (
          dx: 1.0,
          dy: 0.0,
          ox: (tr.origin.x + 1.0) / 2.0,
          oy: (tr.origin.y + 1.0) / 2.0,
          feather: tr.feather,
          cellSize: 0.0,
          rotation: tr.rotation,
          sectors: 1.0,
          sides: tr.sides.toDouble(),
        );
    }
  }

  void _setUniforms(ui.FragmentShader shader, double progress, Rect bounds) {
    final g = _geometry();
    final len = math.sqrt(g.dx * g.dx + g.dy * g.dy);
    final ndx = len > 0 ? g.dx / len : 0.0;
    final ndy = len > 0 ? g.dy / len : 0.0;

    shader.setFloat(0, progress); // uProgress
    shader.setFloat(1, bounds.width); // uResolution.x
    shader.setFloat(2, bounds.height); // uResolution.y
    shader.setFloat(3, g.ox); // uOrigin.x
    shader.setFloat(4, g.oy); // uOrigin.y
    shader.setFloat(5, ndx); // uDirection.x
    shader.setFloat(6, ndy); // uDirection.y
    shader.setFloat(7, g.feather); // uFeather
    shader.setFloat(8, g.cellSize); // uCellSize
    shader.setFloat(9, g.rotation); // uRotation
    shader.setFloat(10, widget.transition.invert ? 1.0 : 0.0); // uInvert
    shader.setFloat(11, g.sectors); // uSectors
    shader.setFloat(12, g.sides); // uSides
  }

  Widget _maskedLayer({
    required ui.FragmentShader shader,
    required double progress,
    required Widget child,
  }) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (Rect bounds) {
        _setUniforms(shader, progress, bounds);
        return shader;
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_pageShader == null) {
      return FadeTransition(opacity: widget.animation, child: widget.child);
    }
    final TransitionCover? cover = widget.transition.cover;

    return AnimatedBuilder(
      animation: widget.animation,
      builder: (context, child) {
        if (cover == null || _coverShader == null) {
          return _maskedLayer(
            shader: _pageShader!,
            progress: widget.animation.value,
            child: child!,
          );
        }

        final phases = _phaseProgresses(widget.animation.value);
        return Stack(
          fit: StackFit.expand,
          children: [
            _maskedLayer(
              shader: _coverShader!,
              progress: phases.cover,
              child: ColoredBox(color: cover.color),
            ),
            _maskedLayer(
              shader: _pageShader!,
              progress: phases.page,
              child: child!,
            ),
          ],
        );
      },
      child: widget.child,
    );
  }
}
