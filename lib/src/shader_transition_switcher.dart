import 'package:flutter/widgets.dart';

import 'shader_mask_widget.dart';
import 'transition_config.dart';

/// An [AnimatedSwitcher] analog that runs a [ShaderTransition] between two
/// child widgets instead of between routes.
///
/// When [child] is replaced by a widget that [Widget.canUpdate] reports as
/// different (different runtime type or [Key]), the old child is shader-
/// masked away and the new one revealed, driven by an internal controller of
/// `transition.duration`. Key your children so swaps are detected:
///
/// ```dart
/// ShaderTransitionSwitcher(
///   transition: const CircleTransition(),
///   onStart: () => audio.play('whoosh'),
///   child: KeyedSubtree(
///     key: ValueKey(pageIndex),
///     child: pages[pageIndex],
///   ),
/// )
/// ```
///
/// [onStart] / [onComplete] / [onProgress] fire per swap — use [onStart] to
/// trigger your own sound (this package bundles no audio).
class ShaderTransitionSwitcher extends StatefulWidget {
  const ShaderTransitionSwitcher({
    super.key,
    required this.child,
    this.transition = const DiamondTransition(),
    this.onStart,
    this.onComplete,
    this.onProgress,
  });

  /// The current child. Replace it (with a distinct key/type) to animate.
  final Widget child;

  /// The transition used for each swap.
  final ShaderTransition transition;

  /// Called when a swap animation starts.
  final VoidCallback? onStart;

  /// Called when a swap animation completes.
  final VoidCallback? onComplete;

  /// Called every tick with progress in `[0, 1]`.
  final ValueChanged<double>? onProgress;

  @override
  State<ShaderTransitionSwitcher> createState() =>
      _ShaderTransitionSwitcherState();
}

class _ShaderTransitionSwitcherState extends State<ShaderTransitionSwitcher>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Widget? _outgoing;
  late Widget _incoming;

  @override
  void initState() {
    super.initState();
    _incoming = widget.child;
    _controller = AnimationController(
      vsync: this,
      duration: widget.transition.duration,
      value: 1.0, // start settled — no transition on first build
    )..addStatusListener(_onStatus);
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _outgoing != null) {
      // Drop the old child once it's fully covered.
      setState(() => _outgoing = null);
    }
  }

  @override
  void didUpdateWidget(ShaderTransitionSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!Widget.canUpdate(oldWidget.child, widget.child)) {
      _outgoing = _incoming;
      _incoming = widget.child;
      _controller
        ..duration = widget.transition.duration
        ..forward(from: 0.0);
    } else {
      _incoming = widget.child;
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onStatus);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_outgoing == null) return _incoming;
    return Stack(
      fit: StackFit.expand,
      children: [
        _outgoing!,
        ShaderMaskTransition(
          animation: _controller,
          transition: widget.transition,
          onStart: widget.onStart,
          onComplete: widget.onComplete,
          onProgress: widget.onProgress,
          child: _incoming,
        ),
      ],
    );
  }
}
