import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

// Tuned to match Cupertino's back swipe (flutter/lib/src/cupertino/route.dart).
const double _kBackGestureWidth = 20.0;
const double _kMinFlingVelocity = 1.0; // Screen widths per second.
const Duration _kMaxSettleDuration = Duration(milliseconds: 350);
const Curve _kSettleCurve = Curves.fastEaseInToSlowEaseOut;

/// Detects an iOS-style back swipe from the leading screen edge and hands
/// the drag to a [ShaderBackGestureController], which scrubs the route's
/// shader transition backwards under the finger.
///
/// Internal to the package: [ShaderPageRoute] wires it up.
class ShaderBackGestureDetector extends StatefulWidget {
  const ShaderBackGestureDetector({
    super.key,
    required this.enabledCallback,
    required this.onStartPopGesture,
    required this.child,
  });

  /// Checked on each pointer down; the swipe only starts when this is true.
  final ValueGetter<bool> enabledCallback;

  /// Creates the controller that drives the route for one swipe.
  final ValueGetter<ShaderBackGestureController> onStartPopGesture;

  final Widget child;

  @override
  State<ShaderBackGestureDetector> createState() =>
      _ShaderBackGestureDetectorState();
}

class _ShaderBackGestureDetectorState extends State<ShaderBackGestureDetector> {
  ShaderBackGestureController? _controller;
  late final HorizontalDragGestureRecognizer _recognizer;

  @override
  void initState() {
    super.initState();
    _recognizer = HorizontalDragGestureRecognizer(debugOwner: this)
      ..onStart = _handleDragStart
      ..onUpdate = _handleDragUpdate
      ..onEnd = _handleDragEnd
      ..onCancel = _handleDragCancel;
  }

  @override
  void dispose() {
    _recognizer.dispose();
    // Disposed mid-swipe (e.g. the route was removed): release the
    // navigator's user-gesture flag once the frame is done.
    final controller = _controller;
    if (controller != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (controller.navigator.mounted) {
          controller.navigator.didStopUserGesture();
        }
      });
      _controller = null;
    }
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    assert(_controller == null);
    _controller = widget.onStartPopGesture();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _controller?.dragUpdate(
      _toLogical(details.primaryDelta! / context.size!.width),
    );
  }

  void _handleDragEnd(DragEndDetails details) {
    _controller?.dragEnd(
      _toLogical(details.velocity.pixelsPerSecond.dx / context.size!.width),
    );
    _controller = null;
  }

  void _handleDragCancel() {
    // May fire without a matching start (paired with the pointer down).
    _controller?.dragEnd(0.0);
    _controller = null;
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (widget.enabledCallback()) _recognizer.addPointer(event);
  }

  // Positive = towards dismissing, whichever edge is "back" for the locale.
  double _toLogical(double value) => switch (Directionality.of(context)) {
        TextDirection.rtl => -value,
        TextDirection.ltr => value,
      };

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasDirectionality(context));
    // Widen the hit strip on the notch/rounded-corner side.
    final padding = MediaQuery.paddingOf(context);
    final edgeInset = switch (Directionality.of(context)) {
      TextDirection.rtl => padding.right,
      TextDirection.ltr => padding.left,
    };
    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        PositionedDirectional(
          start: 0.0,
          width: math.max(edgeInset, _kBackGestureWidth),
          top: 0.0,
          bottom: 0.0,
          child: Listener(
            onPointerDown: _handlePointerDown,
            behavior: HitTestBehavior.translucent,
          ),
        ),
      ],
    );
  }
}

/// Drives a route's [AnimationController] from a back swipe, in logical
/// units: 1.0 = route fully shown, 0.0 = fully dismissed.
class ShaderBackGestureController {
  ShaderBackGestureController({
    required this.navigator,
    required this.controller,
    required this.getIsCurrent,
    required this.getIsActive,
  }) {
    navigator.didStartUserGesture();
  }

  final NavigatorState navigator;
  final AnimationController controller;
  final ValueGetter<bool> getIsCurrent;
  final ValueGetter<bool> getIsActive;

  /// The finger moved by [delta] screen widths towards dismissing.
  void dragUpdate(double delta) {
    controller.value -= delta;
  }

  /// The finger lifted with [velocity] in screen widths per second.
  void dragEnd(double velocity) {
    final bool isCurrent = getIsCurrent();
    final bool stay;
    if (!isCurrent) {
      // Navigated away mid-swipe (e.g. a programmatic pop): finish in
      // whichever direction the stack now implies.
      stay = getIsActive();
    } else if (velocity.abs() >= _kMinFlingVelocity) {
      stay = velocity <= 0;
    } else {
      stay = controller.value > 0.5;
    }

    TickerFuture? settle;
    if (stay) {
      settle = controller.animateTo(
        1.0,
        duration: _settleDuration(1.0 - controller.value),
        curve: _kSettleCurve,
      );
    } else {
      if (isCurrent) navigator.pop();
      // pop() may already have settled if the swipe reached 0.
      if (controller.isAnimating) {
        settle = controller.animateBack(
          0.0,
          duration: _settleDuration(controller.value),
          curve: _kSettleCurve,
        );
      }
    }

    if (settle != null && controller.isAnimating) {
      // Hold the user-gesture flag until the settle ends (the future
      // resolves after the final status notification), so the route's
      // transition callbacks stay quiet for the whole interaction. Also
      // fires if the settle is interrupted or the controller is disposed —
      // a stuck flag would leave every route ignoring pointers.
      settle.whenCompleteOrCancel(() {
        if (navigator.mounted) navigator.didStopUserGesture();
      });
    } else {
      navigator.didStopUserGesture();
    }
  }

  /// The rest of the transition at its own pace, capped so a long transition
  /// still settles snappily after the finger lifts.
  Duration _settleDuration(double remaining) {
    final full = controller.duration ?? _kMaxSettleDuration;
    final ms = (full.inMilliseconds * remaining).round();
    return Duration(
      milliseconds: math.min(ms, _kMaxSettleDuration.inMilliseconds),
    );
  }
}
