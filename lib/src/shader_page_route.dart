import 'package:flutter/material.dart';

import 'shader_transition_builders.dart';
import 'transition_config.dart';

/// A [PageRouteBuilder] that applies a GPU fragment shader as the transition
/// between the outgoing and incoming routes.
///
/// ## Usage
/// ```dart
/// Navigator.of(context).push(
///   ShaderPageRoute(
///     page: const NextPage(),
///     config: ShaderTransitionConfig.diamond(
///       direction: SweepDirection.leftToRight,
///     ),
///   ),
/// );
/// ```
///
/// ## Why `opaque: false`
///
/// This route sets `opaque: false` so that Flutter's [Navigator] continues
/// rendering the outgoing route underneath. Without this, the outgoing page
/// disappears immediately (black flash) because Flutter assumes an opaque
/// top route covers the entire screen and skips rendering routes below it.
///
/// With `opaque: false`, wherever the shader outputs `alpha == 0`, the
/// incoming page is transparent and the outgoing page shows through naturally.
class ShaderPageRoute<T> extends PageRouteBuilder<T> {
  ShaderPageRoute({
    required Widget page,
    ShaderTransitionConfig config = const ShaderTransitionConfig(),
    super.settings,
  }) : super(
          // CRITICAL: allows Flutter to keep rendering the outgoing route
          // underneath this one, so the shader mask reveals it correctly.
          opaque: false,
          barrierColor: null,
          pageBuilder: (_, __, ___) => page,
          transitionDuration: config.duration,
          reverseTransitionDuration: config.reverseDuration,
          transitionsBuilder: ShaderTransitionBuilders.create(config),
        );
}
