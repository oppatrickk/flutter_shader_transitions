/// GPU-accelerated, shader-based screen transitions for Flutter.
///
/// ## Quick start
///
/// 1. **Preload shaders** at app startup (required — compiling shaders is slow):
///    ```dart
///    void main() async {
///      WidgetsFlutterBinding.ensureInitialized();
///      await ShaderTransitions.preload();
///      runApp(const MyApp());
///    }
///    ```
///
/// 2. **Push a route** using the convenience methods:
///    ```dart
///    // Diamond wipe
///    Navigator.of(context).push(ShaderTransitions.diamond(page: const NextPage()));
///
///    // Circular iris
///    Navigator.of(context).push(ShaderTransitions.circle(page: const NextPage()));
///
///    // Directional wipe
///    Navigator.of(context).push(ShaderTransitions.wipe(
///      page: const NextPage(),
///      direction: SweepDirection.rightToLeft,
///    ));
///    ```
///
/// 3. **go_router / auto_route** — use [ShaderTransitionBuilders.create]:
///    ```dart
///    CustomTransitionPage(
///      child: const NextPage(),
///      opaque: false,  // required!
///      transitionsBuilder: ShaderTransitionBuilders.create(
///        const ShaderTransitionConfig.diamond(),
///      ),
///    )
///    ```
library shader_transitions;

export 'src/transition_config.dart';
export 'src/shader_registry.dart' show ShaderRegistry;
export 'src/shader_page_route.dart';
export 'src/shader_transition_builders.dart';
// shader_mask_widget.dart is an internal implementation detail — not exported.

import 'package:flutter/widgets.dart';

import 'src/shader_page_route.dart';
import 'src/shader_registry.dart';
import 'src/transition_config.dart';

/// Main entry point for the shader_transitions package.
///
/// Use [preload] at app startup, then the convenience factory methods to
/// push shader-powered routes.
class ShaderTransitions {
  ShaderTransitions._();

  /// Pre-loads and compiles all fragment shader programs.
  ///
  /// Must be called before the first transition. Subsequent calls are no-ops.
  ///
  /// ```dart
  /// void main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   await ShaderTransitions.preload();
  ///   runApp(const MyApp());
  /// }
  /// ```
  static Future<void> preload() => ShaderRegistry.instance.preload();

  /// Whether shaders have been successfully preloaded.
  ///
  /// Use this to conditionally disable transition buttons until the app is
  /// ready, or to guard against missing preload calls.
  static bool get isReady => ShaderRegistry.instance.isLoaded;

  /// Pushes a diamond-wipe [ShaderPageRoute].
  ///
  /// ```dart
  /// Navigator.of(context).push(
  ///   ShaderTransitions.diamond(
  ///     page: const NextPage(),
  ///     direction: SweepDirection.leftToRight,
  ///   ),
  /// );
  /// ```
  static ShaderPageRoute<T> diamond<T>({
    required Widget page,
    SweepDirection direction = SweepDirection.topLeftToBottomRight,
    Duration transitionDuration = const Duration(milliseconds: 800),
    double size = 40.0,
    RouteSettings? settings,
  }) {
    return ShaderPageRoute<T>(
      page: page,
      config: ShaderTransitionConfig(
        type: TransitionType.diamond,
        direction: direction,
        transitionDuration: transitionDuration,
        size: size,
      ),
      settings: settings,
    );
  }

  /// Pushes a circular iris-wipe [ShaderPageRoute].
  ///
  /// ```dart
  /// Navigator.of(context).push(
  ///   ShaderTransitions.circle(page: const NextPage()),
  /// );
  /// ```
  static ShaderPageRoute<T> circle<T>({
    required Widget page,
    Duration transitionDuration = const Duration(milliseconds: 700),
    RouteSettings? settings,
  }) {
    return ShaderPageRoute<T>(
      page: page,
      config: ShaderTransitionConfig(
        type: TransitionType.circle,
        transitionDuration: transitionDuration,
      ),
      settings: settings,
    );
  }

  /// Pushes a linear directional-wipe [ShaderPageRoute].
  ///
  /// [softness] controls the feather width in pixels (0 = hard edge).
  ///
  /// ```dart
  /// Navigator.of(context).push(
  ///   ShaderTransitions.wipe(
  ///     page: const NextPage(),
  ///     direction: SweepDirection.topToBottom,
  ///   ),
  /// );
  /// ```
  static ShaderPageRoute<T> wipe<T>({
    required Widget page,
    SweepDirection direction = SweepDirection.leftToRight,
    Duration transitionDuration = const Duration(milliseconds: 600),
    double softness = 4.0,
    RouteSettings? settings,
  }) {
    return ShaderPageRoute<T>(
      page: page,
      config: ShaderTransitionConfig(
        type: TransitionType.wipe,
        direction: direction,
        transitionDuration: transitionDuration,
        size: softness,
      ),
      settings: settings,
    );
  }
}
