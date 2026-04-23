import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'shader_mask_widget.dart';
import 'shader_registry.dart';
import 'transition_config.dart';

/// Factory for creating [RouteTransitionsBuilder] closures backed by a
/// fragment shader.
///
/// The returned builder is compatible with:
/// - Flutter's [PageRouteBuilder.transitionsBuilder]
/// - **go_router**: `CustomTransitionPage(transitionsBuilder: ...)`
/// - **auto_route**: `CustomRoute(transitionsBuilder: ...)`
///
/// ## go_router usage
/// ```dart
/// GoRoute(
///   path: '/next',
///   pageBuilder: (context, state) => CustomTransitionPage(
///     key: state.pageKey,
///     child: const NextPage(),
///     opaque: false,  // ← required for the outgoing page to show through
///     transitionDuration: const Duration(milliseconds: 800),
///     reverseTransitionDuration: const Duration(milliseconds: 800),
///     transitionsBuilder: ShaderTransitionBuilders.create(
///       const ShaderTransitionConfig.diamond(),
///     ),
///   ),
/// )
/// ```
///
/// ## auto_route usage
/// ```dart
/// AutoRoute(
///   page: NextRoute.page,
///   customRouteBuilder: <T>(context, child, page) => PageRouteBuilder<T>(
///     settings: page,
///     opaque: false,
///     pageBuilder: (_, __, ___) => child,
///     transitionsBuilder: ShaderTransitionBuilders.create(
///       const ShaderTransitionConfig.circle(),
///     ),
///   ),
/// )
/// ```
///
/// > **Important for go_router / auto_route users:** You must set
/// > `opaque: false` on the page/route. Without it, Flutter stops rendering
/// > the outgoing route underneath, causing a black flash at transition start.
class ShaderTransitionBuilders {
  ShaderTransitionBuilders._();

  /// Creates a [RouteTransitionsBuilder] closure for the given [config].
  ///
  /// The [ui.FragmentShader] is created once when this method is called
  /// (i.e., at route construction time) and is reused for every animation
  /// frame — uniform values are updated in-place rather than reallocating.
  ///
  /// If [ShaderRegistry] has not been preloaded, or if shader loading failed,
  /// the returned builder falls back to a [FadeTransition].
  static RouteTransitionsBuilder create(ShaderTransitionConfig config) {
    final ui.FragmentShader? shader =
        ShaderRegistry.instance.createShader(config.type.name);

    return (
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
    ) {
      if (shader == null) {
        // Graceful fallback when shaders are unavailable.
        return FadeTransition(opacity: animation, child: child);
      }
      return ShaderMaskTransition(
        shader: shader,
        animation: animation,
        config: config,
        child: child,
      );
    };
  }
}
