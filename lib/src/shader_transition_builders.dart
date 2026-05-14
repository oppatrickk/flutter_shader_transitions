import 'package:flutter/material.dart';

import 'shader_mask_widget.dart';
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
  /// The [ShaderMaskTransition] widget manages the [FragmentShader] lifecycle
  /// internally — creating it on mount and disposing it on unmount. This
  /// avoids dangling shader references on platforms (e.g. Flutter web/WASM)
  /// where native shader backing can be finalized independently of the Dart
  /// wrapper. Falls back to [FadeTransition] if the shader program was not
  /// preloaded.
  static RouteTransitionsBuilder create(ShaderTransitionConfig config) {
    return (
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
    ) {
      return ShaderMaskTransition(
        animation: animation,
        config: config,
        child: child,
      );
    };
  }
}
