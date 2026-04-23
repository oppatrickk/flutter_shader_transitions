import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'transition_config.dart';

/// Applies a shader as an alpha mask to [child] using [BlendMode.dstIn].
///
/// This is the core rendering primitive for all shader transitions.
///
/// ## How it works
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
/// ## Uniform layout
///
/// All shaders share the same 6-uniform layout, set unconditionally:
/// ```
/// index 0 — uProgress    : float  (animation.value, 0.0→1.0)
/// index 1 — uResolution.x: float  (bounds.width)
/// index 2 — uResolution.y: float  (bounds.height)
/// index 3 — uSize        : float  (diamond cell px / wipe feather px)
/// index 4 — uDirection.x : float  (normalized sweep direction x)
/// index 5 — uDirection.y : float  (normalized sweep direction y)
/// ```
class ShaderMaskTransition extends StatelessWidget {
  const ShaderMaskTransition({
    super.key,
    required this.shader,
    required this.animation,
    required this.config,
    required this.child,
  });

  /// The [ui.FragmentShader] instance to use. Must have been created from a
  /// preloaded [ui.FragmentProgram] and must NOT be shared between routes.
  final ui.FragmentShader shader;

  /// The route animation (0.0 → 1.0 on push, 1.0 → 0.0 on pop).
  final Animation<double> animation;

  /// Configuration providing direction, size, and type metadata.
  final ShaderTransitionConfig config;

  /// The incoming page widget.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      // Pass child through so Flutter does not rebuild it on every frame.
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (Rect bounds) {
            final (dx, dy) = config.direction.vector;
            final len = math.sqrt(dx * dx + dy * dy);
            final ndx = len > 0 ? dx / len : 0.0;
            final ndy = len > 0 ? dy / len : 0.0;

            shader.setFloat(0, animation.value); // uProgress
            shader.setFloat(1, bounds.width); // uResolution.x
            shader.setFloat(2, bounds.height); // uResolution.y
            shader.setFloat(3, config.size); // uSize
            shader.setFloat(4, ndx); // uDirection.x
            shader.setFloat(5, ndy); // uDirection.y

            return shader;
          },
          child: child,
        );
      },
      child: child,
    );
  }
}
