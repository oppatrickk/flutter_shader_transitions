import 'package:flutter/material.dart';

import 'shader_back_gesture.dart';
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
///
/// ## Swipe back
///
/// On iOS and macOS the route supports the platform back swipe: drag from
/// the leading screen edge and the shader transition scrubs backwards under
/// the finger, then pops or restores on release — the same thresholds as
/// `CupertinoPageRoute`. Control it with [swipeBack].
class ShaderPageRoute<T> extends PageRouteBuilder<T> {
  ShaderPageRoute({
    required Widget page,
    this.transition = const DiamondTransition(),
    VoidCallback? onStart,
    VoidCallback? onComplete,
    ValueChanged<double>? onProgress,
    this.swipeBack,
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
          transitionsBuilder: ShaderTransitionBuilders.create(
            transition,
            onStart: onStart,
            onComplete: onComplete,
            onProgress: onProgress,
          ),
        );

  /// The shader transition rendered between routes.
  final ShaderTransition transition;

  /// Whether an edge swipe pops this route (the iOS back gesture).
  ///
  /// `null` (the default) follows the platform, like [MaterialPageRoute]:
  /// enabled when [ThemeData.platform] is iOS or macOS, disabled elsewhere.
  /// Even when enabled, the swipe is refused wherever a pop would be — the
  /// first route, a `PopScope(canPop: false)`, or mid-transition.
  final bool? swipeBack;

  bool _swipeBackEnabled(BuildContext context) =>
      swipeBack ??
      switch (Theme.of(context).platform) {
        TargetPlatform.iOS || TargetPlatform.macOS => true,
        _ => false,
      };

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final transitioned =
        super.buildTransitions(context, animation, secondaryAnimation, child);
    if (!_swipeBackEnabled(context)) return transitioned;
    return ShaderBackGestureDetector(
      enabledCallback: () => popGestureEnabled,
      onStartPopGesture: _startPopGesture,
      child: transitioned,
    );
  }

  ShaderBackGestureController _startPopGesture() {
    assert(popGestureEnabled);
    return ShaderBackGestureController(
      navigator: navigator!,
      controller: controller!, // protected access — this route owns it
      getIsCurrent: () => isCurrent,
      getIsActive: () => isActive,
    );
  }
}
