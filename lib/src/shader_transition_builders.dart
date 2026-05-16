import 'package:flutter/material.dart';

import 'shader_mask_widget.dart';
import 'transition_config.dart';

/// Factory + [PageTransitionsBuilder] for using a [ShaderTransition] with
/// any router.
///
/// - Flutter Navigator: prefer [ShaderPageRoute].
/// - **go_router**: `CustomTransitionPage(transitionsBuilder: ...)`.
/// - **auto_route**: `CustomRoute(transitionsBuilder: ...)`.
/// - App-wide default: [ShaderPageTransitionsBuilder] in
///   `ThemeData.pageTransitionsTheme`.
///
/// ## go_router
/// ```dart
/// GoRoute(
///   path: '/next',
///   pageBuilder: (context, state) => CustomTransitionPage(
///     key: state.pageKey,
///     child: const NextPage(),
///     opaque: false, // ← required for the outgoing page to show through
///     transitionDuration: const Duration(milliseconds: 800),
///     reverseTransitionDuration: const Duration(milliseconds: 800),
///     transitionsBuilder: ShaderTransitionBuilders.create(
///       const DiamondTransition(),
///     ),
///   ),
/// )
/// ```
///
/// ## auto_route
/// ```dart
/// AutoRoute(
///   page: NextRoute.page,
///   customRouteBuilder: <T>(context, child, page) => PageRouteBuilder<T>(
///     settings: page,
///     opaque: false,
///     pageBuilder: (_, __, ___) => child,
///     transitionsBuilder: ShaderTransitionBuilders.create(
///       const CircleTransition(),
///     ),
///   ),
/// )
/// ```
///
/// > **go_router / auto_route users:** set `opaque: false` on the page/route.
/// > Without it Flutter stops rendering the outgoing route, causing a black
/// > flash at the start of the transition.
class ShaderTransitionBuilders {
  ShaderTransitionBuilders._();

  /// Creates a [RouteTransitionsBuilder] for the given [transition].
  ///
  /// The [ShaderMaskTransition] manages the [FragmentShader] lifecycle
  /// internally and falls back to [FadeTransition] if shaders were not
  /// preloaded. [onStart] / [onComplete] / [onProgress] are forwarded so the
  /// app can play its own sound or react to progress.
  static RouteTransitionsBuilder create(
    ShaderTransition transition, {
    VoidCallback? onStart,
    VoidCallback? onComplete,
    ValueChanged<double>? onProgress,
  }) {
    return (
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
    ) {
      return ShaderMaskTransition(
        animation: animation,
        transition: transition,
        onStart: onStart,
        onComplete: onComplete,
        onProgress: onProgress,
        child: child,
      );
    };
  }
}

/// A [PageTransitionsBuilder] that applies a [ShaderTransition] app-wide via
/// `ThemeData.pageTransitionsTheme`.
///
/// ```dart
/// MaterialApp(
///   theme: ThemeData(
///     pageTransitionsTheme: const PageTransitionsTheme(
///       builders: {
///         TargetPlatform.android: ShaderPageTransitionsBuilder(
///           WipeTransition(direction: SweepDirection.leftToRight),
///         ),
///         TargetPlatform.iOS: ShaderPageTransitionsBuilder(CircleTransition()),
///       },
///     ),
///   ),
/// )
/// ```
///
/// Note: routes themselves must be non-opaque for the outgoing page to show
/// through. `MaterialPageRoute` is opaque by default, so for the full
/// cross-fade effect prefer [ShaderPageRoute]; this builder is best for
/// covered transitions (with a [TransitionCover]) where the incoming page is
/// the only thing that needs to be visible.
class ShaderPageTransitionsBuilder extends PageTransitionsBuilder {
  /// Creates an app-wide shader page transition.
  const ShaderPageTransitionsBuilder(this.transition);

  /// The shader transition applied to every matching route.
  final ShaderTransition transition;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return ShaderMaskTransition(
      animation: animation,
      transition: transition,
      child: child,
    );
  }
}
