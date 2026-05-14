import 'dart:ui' show Color;

/// The type of shader-based transition to apply.
enum TransitionType {
  /// A grid of diamond shapes that reveal the incoming page in a sweeping wave.
  diamond,

  /// A circular iris wipe that expands from the center of the screen.
  circle,

  /// A linear wipe that sweeps across the screen in the specified direction.
  wipe,
}

/// The direction in which the transition sweeps across the screen.
///
/// For [TransitionType.diamond] and [TransitionType.wipe], this controls which
/// corner or edge of the screen the sweep originates from. For
/// [TransitionType.circle], this parameter is ignored.
enum SweepDirection {
  topLeftToBottomRight,
  bottomRightToTopLeft,
  leftToRight,
  rightToLeft,
  topToBottom,
  bottomToTop,
  topRightToBottomLeft,
  bottomLeftToTopRight,
}

/// Extension providing the normalized 2D direction vector for each [SweepDirection].
///
/// The vector components may not be unit-length (e.g. diagonal is (1,1)).
/// [ShaderMaskTransition] normalizes them before passing to the GLSL shader.
extension SweepDirectionVector on SweepDirection {
  (double, double) get vector => switch (this) {
        SweepDirection.topLeftToBottomRight => (1.0, 1.0),
        SweepDirection.bottomRightToTopLeft => (-1.0, -1.0),
        SweepDirection.leftToRight => (1.0, 0.0),
        SweepDirection.rightToLeft => (-1.0, 0.0),
        SweepDirection.topToBottom => (0.0, 1.0),
        SweepDirection.bottomToTop => (0.0, -1.0),
        SweepDirection.topRightToBottomLeft => (-1.0, 1.0),
        SweepDirection.bottomLeftToTopRight => (1.0, -1.0),
      };
}

/// Configuration for a shader-based screen transition.
///
/// Use the named constructors for a convenient per-type API:
/// ```dart
/// ShaderTransitionConfig.diamond()
/// ShaderTransitionConfig.circle()
/// ShaderTransitionConfig.wipe(direction: SweepDirection.leftToRight)
/// ```
///
/// Pass [color] to fill the un-revealed area with a flat color (e.g. black)
/// instead of letting the outgoing page show through.
class ShaderTransitionConfig {
  /// The type of shader transition to use.
  final TransitionType type;

  /// The direction of the transition sweep.
  ///
  /// Ignored for [TransitionType.circle].
  final SweepDirection direction;

  /// Duration of the forward (push) transition.
  final Duration duration;

  /// Duration of the reverse (pop) transition.
  final Duration reverseDuration;

  /// Type-specific size parameter:
  /// - [TransitionType.diamond]: cell size in pixels (default 40.0)
  /// - [TransitionType.wipe]: feather/softness width in pixels (default 4.0)
  /// - [TransitionType.circle]: unused
  final double size;

  /// Optional fill color for the un-revealed region of the transition.
  ///
  /// When `null` (default), the un-revealed area is transparent and the
  /// outgoing page shows through underneath — a classic mask reveal.
  ///
  /// When non-null, a flat color is rendered beneath the masked incoming
  /// page, so the wipe peels the color away to expose the new page. Useful
  /// for cinematic "fade-to-black" style transitions or brand-colored wipes.
  /// Semi-transparent colors are allowed and will partially blend with the
  /// outgoing page.
  final Color? color;

  const ShaderTransitionConfig({
    this.type = TransitionType.diamond,
    this.direction = SweepDirection.topLeftToBottomRight,
    this.duration = const Duration(milliseconds: 800),
    this.reverseDuration = const Duration(milliseconds: 800),
    this.size = 40.0,
    this.color,
  });

  /// Diamond grid wipe sweeping across the screen.
  const ShaderTransitionConfig.diamond({
    SweepDirection direction = SweepDirection.topLeftToBottomRight,
    Duration duration = const Duration(milliseconds: 800),
    Duration reverseDuration = const Duration(milliseconds: 800),
    double size = 40.0,
    Color? color,
  }) : this(
          type: TransitionType.diamond,
          direction: direction,
          duration: duration,
          reverseDuration: reverseDuration,
          size: size,
          color: color,
        );

  /// Circular iris wipe expanding from the center.
  const ShaderTransitionConfig.circle({
    Duration duration = const Duration(milliseconds: 700),
    Duration reverseDuration = const Duration(milliseconds: 700),
    Color? color,
  }) : this(
          type: TransitionType.circle,
          duration: duration,
          reverseDuration: reverseDuration,
          color: color,
        );

  /// Linear directional wipe with optional feathered edge.
  ///
  /// [size] controls the softness of the wipe edge in pixels.
  /// Set to 0.0 for a hard edge.
  const ShaderTransitionConfig.wipe({
    SweepDirection direction = SweepDirection.leftToRight,
    Duration duration = const Duration(milliseconds: 600),
    Duration reverseDuration = const Duration(milliseconds: 600),
    double size = 4.0,
    Color? color,
  }) : this(
          type: TransitionType.wipe,
          direction: direction,
          duration: duration,
          reverseDuration: reverseDuration,
          size: size,
          color: color,
        );
}
