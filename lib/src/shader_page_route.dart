import 'package:flutter/material.dart';

import 'shader_transition_builders.dart';
import 'transition_config.dart';

/// A [PageRouteBuilder] that applies a [ShaderTransition] between the
/// outgoing and incoming routes.
///
/// ## Usage
/// ```dart
/// Navigator.of(context).push(
///   ShaderPageRoute(
///     page: const NextPage(),
///     transition: const DiamondTransition(
///       direction: SweepDirection.leftToRight,
///     ),
///   ),
/// );
/// ```
///
/// ## Why `opaque: false`
///
/// This route sets `opaque: false` so Flutter keeps rendering the outgoing
/// route underneath. Without it the outgoing page disappears immediately
/// (black flash) because Flutter skips routes below an opaque top route.
/// Wherever the shader outputs `alpha == 0`, the incoming page is
/// transparent and the outgoing page (or [TransitionCover] color) shows.
class ShaderPageRoute<T> extends PageRouteBuilder<T> {
  ShaderPageRoute({
    required Widget page,
    this.transition = const DiamondTransition(),
    super.settings,
  }) : super(
          // CRITICAL: keep the outgoing route rendered underneath.
          opaque: false,
          barrierColor: null,
          pageBuilder: (_, __, ___) => page,
          // One duration for both directions; any cover hold lives inside
          // this window (clamped by ShaderMaskTransition).
          transitionDuration: transition.duration,
          reverseTransitionDuration: transition.duration,
          transitionsBuilder: ShaderTransitionBuilders.create(transition),
        );

  /// The shader transition rendered between routes.
  final ShaderTransition transition;
}
