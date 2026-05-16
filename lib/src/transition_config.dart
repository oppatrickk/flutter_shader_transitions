import 'dart:ui' show Color;

import 'package:flutter/painting.dart' show Alignment;

/// The direction in which a directional transition sweeps across the screen.
///
/// Applies to [DiamondTransition] and [WipeTransition]. Ignored by
/// [CircleTransition], which is radial and uses [CircleTransition.origin]
/// instead.
enum SweepDirection {
  /// Diagonal sweep starting at the top-left corner, ending bottom-right.
  topLeftToBottomRight,

  /// Diagonal sweep starting at the bottom-right corner, ending top-left.
  bottomRightToTopLeft,

  /// Horizontal sweep from the left edge to the right edge.
  leftToRight,

  /// Horizontal sweep from the right edge to the left edge.
  rightToLeft,

  /// Vertical sweep from the top edge to the bottom edge.
  topToBottom,

  /// Vertical sweep from the bottom edge to the top edge.
  bottomToTop,

  /// Diagonal sweep starting at the top-right corner, ending bottom-left.
  topRightToBottomLeft,

  /// Diagonal sweep starting at the bottom-left corner, ending top-right.
  bottomLeftToTopRight,
}

/// Provides the (non-normalized) 2D direction vector for each
/// [SweepDirection].
///
/// Vector components are `-1`, `0`, or `1`; diagonals are `(±1, ±1)` and so
/// are not unit-length. [ShaderMaskTransition] normalizes them before passing
/// `uDirection` to the GLSL shader. `+y` points down (Flutter screen space).
extension SweepDirectionVector on SweepDirection {
  /// The raw `(dx, dy)` vector for this direction. See the extension docs for
  /// the coordinate convention and normalization note.
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

/// Groups the cover color and its hold duration for a "fade-through-color"
/// transition.
///
/// When a [ShaderTransition] is given a [ShaderTransition.cover], the
/// transition becomes a three-phase sequence: the [color] wipes in over the
/// outgoing page, holds at full cover for [hold], then the incoming page
/// wipes in over the color. With `hold == Duration.zero` it's a continuous
/// cross-fade through the color (no hold frame).
///
/// [hold] sits **inside** [ShaderTransition.duration] and is internally
/// clamped to at most 75% of it, so each wipe always keeps a visible share
/// of the timeline regardless of what you pass.
///
/// ```dart
/// WipeTransition(
///   cover: TransitionCover(
///     color: Colors.black,
///     hold: Duration(milliseconds: 600),
///   ),
/// )
/// ```
class TransitionCover {
  /// The flat fill color shown beneath the masked incoming page. Semi-
  /// transparent colors partially blend with the outgoing page.
  final Color color;

  /// How long the screen stays fully covered, between the cover wipe-in and
  /// the page wipe-out. Clamped to ≤ 75% of [ShaderTransition.duration].
  final Duration hold;

  /// Creates a cover with the given [color] and optional [hold] (default
  /// [Duration.zero] — a continuous cross-fade with no hold frame).
  const TransitionCover({
    required this.color,
    this.hold = Duration.zero,
  });
}

/// A shader-backed screen transition.
///
/// This is a sealed hierarchy — instantiate one of the concrete subtypes:
///
/// - [DiamondTransition] — a sweeping grid of diamond cells.
/// - [CircleTransition] — a circular iris reveal from [CircleTransition.origin].
/// - [WipeTransition] — a straight feathered edge in a [SweepDirection].
///
/// Every transition shares [duration], an optional [cover], and an [invert]
/// flag. Pass one to [ShaderPageRoute], [ShaderTransitions] factories, or
/// [ShaderTransitionBuilders.create].
sealed class ShaderTransition {
  /// Total animation time, used unchanged for both push and pop.
  ///
  /// When [cover] is set, this window is split internally into
  /// `cover wipe-in → hold → page wipe-out`.
  final Duration duration;

  /// Optional flat-color cover for a cinematic fade-through transition.
  /// `null` (default) lets the outgoing page show through — a classic
  /// mask reveal.
  final TransitionCover? cover;

  /// Reverses the reveal direction of the effect. For [CircleTransition]
  /// this turns the expanding iris into a contracting one; for directional
  /// transitions it flips which side reveals first.
  final bool invert;

  const ShaderTransition({
    required this.duration,
    this.cover,
    this.invert = false,
  });

  /// The [ShaderRegistry] key (and `.frag` basename) backing this transition.
  String get shaderKey;
}

/// A grid of diamond cells that reveal the incoming page in a sweeping band.
///
/// Within the moving band each cell fills from its center outward, so the
/// edge reads as a shimmer of growing diamonds rather than a hard line.
///
/// ```dart
/// const DiamondTransition(
///   direction: SweepDirection.leftToRight,
///   cellSize: 36,
/// )
/// ```
final class DiamondTransition extends ShaderTransition {
  /// Diamond grid cell size in logical pixels. Clamped at the shader to
  /// never go below 1 px.
  final double cellSize;

  /// Edge softness of the sweeping band, in logical pixels. `0` is allowed.
  final double feather;

  /// Which corner/edge the sweep originates from.
  final SweepDirection direction;

  /// Creates a diamond-grid transition.
  const DiamondTransition({
    this.cellSize = 40.0,
    this.feather = 0.0,
    this.direction = SweepDirection.topLeftToBottomRight,
    super.duration = const Duration(milliseconds: 800),
    super.cover,
    super.invert,
  });

  @override
  String get shaderKey => 'diamond';
}

/// A circular iris reveal that grows (or, with [invert], shrinks) from
/// [origin].
///
/// ```dart
/// const CircleTransition(origin: Alignment.bottomRight)
/// // contracting iris:
/// const CircleTransition(invert: true)
/// ```
final class CircleTransition extends ShaderTransition {
  /// The point the iris emanates from. `Alignment.center` (default) is the
  /// screen center; `Alignment.topLeft` the top-left corner, etc.
  final Alignment origin;

  /// Edge softness of the iris ring, in logical pixels.
  final double feather;

  /// Creates a circular iris transition.
  const CircleTransition({
    this.origin = Alignment.center,
    this.feather = 2.0,
    super.duration = const Duration(milliseconds: 700),
    super.cover,
    super.invert,
  });

  @override
  String get shaderKey => 'circle';
}

/// A straight feathered edge that travels across the screen in a
/// [SweepDirection], optionally [rotation]-rotated.
///
/// ```dart
/// const WipeTransition(
///   direction: SweepDirection.rightToLeft,
///   softness: 6,
/// )
/// ```
final class WipeTransition extends ShaderTransition {
  /// Feather width of the wipe edge in logical pixels. `0` gives a hard edge.
  final double softness;

  /// Which edge/corner the wipe travels from.
  final SweepDirection direction;

  /// Rotates the wipe edge around screen center, in radians. `0` (default)
  /// keeps the edge perpendicular to [direction].
  final double rotation;

  /// Creates a linear wipe transition.
  const WipeTransition({
    this.softness = 4.0,
    this.direction = SweepDirection.leftToRight,
    this.rotation = 0.0,
    super.duration = const Duration(milliseconds: 600),
    super.cover,
    super.invert,
  });

  @override
  String get shaderKey => 'wipe';
}
