import 'package:flutter/material.dart';
import 'package:shader_transitions/shader_transitions.dart';

import 'screens/gallery_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Compile all fragment shaders before the first frame is drawn.
  // This prevents GPU compilation jank on the very first transition.
  await ShaderTransitions.preload();

  runApp(const ShaderTransitionsDemo());
}

class ShaderTransitionsDemo extends StatelessWidget {
  const ShaderTransitionsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shader Transitions',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const GalleryScreen(),
    );
  }
}
