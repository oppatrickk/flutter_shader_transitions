import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'shader_registry.dart';
import 'transition_config.dart';

/// Applies a shader as an alpha mask to [child] using [BlendMode.dstIn].
///
/// This is the core rendering primitive for all shader transitions.
///
/// ## How it works (no cover color)
///
/// The shader outputs an RGBA value where only the **alpha channel** matters.
/// [ShaderMask] with [BlendMode.dstIn] multiplies the child's alpha by the
/// shader's alpha — making the child transparent where `shader.alpha == 0`
/// and fully opaque where `shader.alpha == 1`.
///
/// Combined with `opaque: false` on the enclosing [PageRoute], this creates
/// a true two-layer transition:
/// - At `animation.value == 0.0`: child (incoming page) is fully transparent
///   → the outgoing page shows through from the Navigator's layer stack.
/// - At `animation.value == 1.0`: child (incoming page) is fully opaque
///   → transition is complete.
///
/// ## How it works (with cover color)
///
/// When `config.color` is non-null, the transition becomes a three-phase
/// sequence backed by **two** shader instances:
///
/// 1. **Wipe in** — the cover color sweeps over the outgoing page using a
///    masked [ColoredBox]. The incoming page is fully hidden.
/// 2. **Hold** — for `config.coverDuration` the screen is held at full
///    cover. No wipe motion happens.
/// 3. **Wipe out** — the incoming page sweeps over the cover.
///
/// When `config.coverDuration == Duration.zero`, phases 1 and 3 abut
/// directly: a continuous cross-fade through the color with no hold frame.
///
/// ## Uniform layout
///
/// All shaders share the same 6-uniform layout, set unconditionally:
/// ```
/// index 0 — uProgress    : float  (per-shader phase progress, 0.0→1.0)
/// index 1 — uResolution.x: float  (bounds.width)
/// index 2 — uResolution.y: float  (bounds.height)
/// index 3 — uSize        : float  (diamond cell px / wipe feather px)
/// index 4 — uDirection.x : float  (normalized sweep direction x)
/// index 5 — uDirection.y : float  (normalized sweep direction y)
/// ```
class ShaderMaskTransition extends StatefulWidget {
  const ShaderMaskTransition({
    super.key,
    required this.animation,
    required this.config,
    required this.child,
  });

  /// The route animation (0.0 → 1.0 on push, 1.0 → 0.0 on pop).
  final Animation<double> animation;

  /// Configuration providing direction, size, and type metadata.
  final ShaderTransitionConfig config;

  /// The incoming page widget.
  final Widget child;

  @override
  State<ShaderMaskTransition> createState() => _ShaderMaskTransitionState();
}

class _ShaderMaskTransitionState extends State<ShaderMaskTransition> {
  // Mask for the incoming page. Always created.
  ui.FragmentShader? _pageShader;
  // Mask for the cover ColoredBox. Created only when config.color != null —
  // the cover wipe-in needs its own uniform state independent of the page
  // wipe-out, so we keep a second FragmentShader instance.
  ui.FragmentShader? _coverShader;

  @override
  void initState() {
    super.initState();
    _pageShader = ShaderRegistry.instance.createShader(widget.config.type.name);
    if (widget.config.color != null) {
      _coverShader =
          ShaderRegistry.instance.createShader(widget.config.type.name);
    }
  }

  @override
  void dispose() {
    _pageShader?.dispose();
    _coverShader?.dispose();
    super.dispose();
  }

  // The cover hold can never exceed this fraction of the total transition
  // window — each wipe is guaranteed at least (1 - this) / 2 of the timeline.
  // 0.75 → wipes always get ≥ 12.5% each, even if the caller passes a
  // coverDuration longer than transitionDuration.
  static const double _maxCoverFraction = 0.75;

  /// Maps `animation.value ∈ [0, 1]` to per-phase progresses for the cover
  /// and page shaders. See class-level dartdoc for the three-phase model.
  ///
  /// The cover hold sits inside [ShaderTransitionConfig.transitionDuration]
  /// and is clamped to at most [_maxCoverFraction] of it, so the wipes
  /// always have a meaningful share regardless of what the caller passes.
  ({double cover, double page}) _phaseProgresses(double t) {
    final totalMs = widget.config.transitionDuration.inMilliseconds.toDouble();
    if (totalMs <= 0) {
      // Degenerate config — treat as fully revealed.
      return (cover: 1.0, page: 1.0);
    }
    final maxHoldMs = totalMs * _maxCoverFraction;
    final requestedHoldMs =
        widget.config.coverDuration.inMilliseconds.toDouble();
    final holdMs = requestedHoldMs.clamp(0.0, maxHoldMs);
    final wipeMs = (totalMs - holdMs) / 2.0;
    final phase1End = wipeMs / totalMs;
    final phase2End = (wipeMs + holdMs) / totalMs;

    if (t < phase1End) {
      return (cover: t / phase1End, page: 0.0);
    }
    if (t < phase2End) {
      return (cover: 1.0, page: 0.0);
    }
    return (cover: 1.0, page: (t - phase2End) / (1.0 - phase2End));
  }

  void _setUniforms(ui.FragmentShader shader, double progress, Rect bounds) {
    final (dx, dy) = widget.config.direction.vector;
    final len = math.sqrt(dx * dx + dy * dy);
    final ndx = len > 0 ? dx / len : 0.0;
    final ndy = len > 0 ? dy / len : 0.0;

    shader.setFloat(0, progress); // uProgress
    shader.setFloat(1, bounds.width); // uResolution.x
    shader.setFloat(2, bounds.height); // uResolution.y
    shader.setFloat(3, widget.config.size); // uSize
    shader.setFloat(4, ndx); // uDirection.x
    shader.setFloat(5, ndy); // uDirection.y
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
    final Color? color = widget.config.color;

    return AnimatedBuilder(
      animation: widget.animation,
      builder: (context, child) {
        if (color == null || _coverShader == null) {
          // Single-shader path: classic mask reveal, no cover.
          return _maskedLayer(
            shader: _pageShader!,
            progress: widget.animation.value,
            child: child!,
          );
        }

        // Phased flow: cover wipes in, holds, then page wipes in.
        final phases = _phaseProgresses(widget.animation.value);
        return Stack(
          fit: StackFit.expand,
          children: [
            _maskedLayer(
              shader: _coverShader!,
              progress: phases.cover,
              child: ColoredBox(color: color),
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
