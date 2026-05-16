/// GPU-accelerated, shader-based screen transitions for Flutter.
///
/// ## Quick start
///
/// 1. **Preload shaders** at app startup (compiling shaders is slow):
///    ```dart
///    void main() async {
///      WidgetsFlutterBinding.ensureInitialized();
///      await ShaderTransitions.preload();
///      runApp(const MyApp());
///    }
///    ```
///
/// 2. **Push a route**:
///    ```dart
///    Navigator.of(context).push(
///      ShaderTransitions.diamond(page: const NextPage()),
///    );
///    Navigator.of(context).push(
///      ShaderTransitions.circle(page: const NextPage(), invert: true),
///    );
///    Navigator.of(context).push(
///      ShaderTransitions.wipe(
///        page: const NextPage(),
///        direction: SweepDirection.rightToLeft,
///      ),
///    );
///    ```
///
/// 3. **go_router / auto_route** — use [ShaderTransitionBuilders.create];
///    app-wide — use [ShaderPageTransitionsBuilder].
library shader_transitions;

export 'src/transition_config.dart';
export 'src/shader_registry.dart' show ShaderRegistry;
export 'src/shader_page_route.dart';
export 'src/shader_transition_builders.dart';
// shader_mask_widget.dart is an internal implementation detail.

import 'package:flutter/widgets.dart';

import 'src/shader_page_route.dart';
import 'src/shader_registry.dart';
import 'src/transition_config.dart';

/// Entry point: [preload] at startup, then the factory methods to push
/// shader-powered routes.
class ShaderTransitions {
  ShaderTransitions._();

  /// Pre-compiles all bundled fragment shaders. Call before the first
  /// transition; subsequent calls are no-ops.
  static Future<void> preload() => ShaderRegistry.instance.preload();

  /// Whether [preload] has completed successfully.
  static bool get isReady => ShaderRegistry.instance.isLoaded;

  /// Pushes a [DiamondTransition] route.
  static ShaderPageRoute<T> diamond<T>({
    required Widget page,
    SweepDirection direction = SweepDirection.topLeftToBottomRight,
    Duration duration = const Duration(milliseconds: 800),
    double cellSize = 40.0,
    double feather = 0.0,
    bool invert = false,
    TransitionCover? cover,
    RouteSettings? settings,
  }) {
    return ShaderPageRoute<T>(
      page: page,
      transition: DiamondTransition(
        direction: direction,
        duration: duration,
        cellSize: cellSize,
        feather: feather,
        invert: invert,
        cover: cover,
      ),
      settings: settings,
    );
  }

  /// Pushes a [CircleTransition] (iris) route. Set [invert] for a
  /// contracting iris; [origin] to start from a corner or tap point.
  static ShaderPageRoute<T> circle<T>({
    required Widget page,
    Alignment origin = Alignment.center,
    Duration duration = const Duration(milliseconds: 700),
    double feather = 2.0,
    bool invert = false,
    TransitionCover? cover,
    RouteSettings? settings,
  }) {
    return ShaderPageRoute<T>(
      page: page,
      transition: CircleTransition(
        origin: origin,
        duration: duration,
        feather: feather,
        invert: invert,
        cover: cover,
      ),
      settings: settings,
    );
  }

  /// Pushes a [WipeTransition] route. [softness] is the feather width in px
  /// (0 = hard edge); [rotation] tilts the edge in radians.
  static ShaderPageRoute<T> wipe<T>({
    required Widget page,
    SweepDirection direction = SweepDirection.leftToRight,
    Duration duration = const Duration(milliseconds: 600),
    double softness = 4.0,
    double rotation = 0.0,
    bool invert = false,
    TransitionCover? cover,
    RouteSettings? settings,
  }) {
    return ShaderPageRoute<T>(
      page: page,
      transition: WipeTransition(
        direction: direction,
        duration: duration,
        softness: softness,
        rotation: rotation,
        invert: invert,
        cover: cover,
      ),
      settings: settings,
    );
  }
}
