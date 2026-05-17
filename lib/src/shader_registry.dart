import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

/// Singleton cache of compiled [ui.FragmentProgram] instances.
///
/// Call [preload] once at app startup (before [runApp]) to compile all shaders.
/// This prevents jank on the first transition because GPU shader compilation
/// is deferred until the program is first used.
///
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await ShaderRegistry.instance.preload();
///   runApp(const MyApp());
/// }
/// ```
class ShaderRegistry {
  ShaderRegistry._();

  /// The global singleton instance.
  static final ShaderRegistry instance = ShaderRegistry._();

  final Map<String, ui.FragmentProgram> _programs = {};
  bool _loaded = false;

  /// Whether [preload] has completed successfully.
  bool get isLoaded => _loaded;

  // Shaders declared in this package's pubspec.yaml are accessed via the
  // 'packages/<package_name>/' prefix — both from within the package itself
  // and from consuming applications.
  static const String _packagePrefix = 'packages/shader_transitions/';

  static const List<String> _shaderKeys = [
    'diamond',
    'circle',
    'wipe',
    'clock',
    'polygon',
    'dissolve',
    'fade',
    'bars',
  ];

  /// Compiles and caches all shader programs.
  ///
  /// Safe to call multiple times — subsequent calls are no-ops.
  ///
  /// If compilation fails (e.g. on the HTML web renderer which does not
  /// support [ui.FragmentProgram]), the error is caught and logged. All
  /// transitions will then fall back to a [FadeTransition].
  Future<void> preload() async {
    if (_loaded) return;
    try {
      await Future.wait(
        _shaderKeys.map((key) => _loadProgram(key)),
      );
      _loaded = true;
    } catch (e) {
      debugPrint('shader_transitions: Failed to load shaders — '
          'transitions will fall back to FadeTransition. Error: $e');
    }
  }

  Future<void> _loadProgram(String key) async {
    _programs[key] = await ui.FragmentProgram.fromAsset(
      '${_packagePrefix}shaders/$key.frag',
    );
  }

  /// Creates a fresh [ui.FragmentShader] from the cached program for [key].
  ///
  /// Returns `null` if [preload] has not been called or failed.
  ///
  /// A new [ui.FragmentShader] instance is returned each call — it holds
  /// mutable uniform state and must not be shared between routes.
  ui.FragmentShader? createShader(String key) =>
      _programs[key]?.fragmentShader();
}
