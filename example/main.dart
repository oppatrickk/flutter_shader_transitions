import 'dart:ui' as ui;

import 'package:flutter/material.dart';

void main() => runApp(MaterialApp(home: ShaderTransitionDemo()));

class ShaderTransitionDemo extends StatefulWidget {
  const ShaderTransitionDemo({super.key});

  @override
  State<ShaderTransitionDemo> createState() => _ShaderTransitionDemoState();
}

class _ShaderTransitionDemoState extends State<ShaderTransitionDemo> with SingleTickerProviderStateMixin {
  ui.FragmentShader? shader;
  late AnimationController _controller;
  bool _isRevealed = false;

  @override
  void initState() {
    super.initState();
    _loadShader();
    // Duration controls how fast the diamonds sweep across
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
  }

  Future<void> _loadShader() async {
    final program = await ui.FragmentProgram.fromAsset('shaders/diamond_transition.frag');
    setState(() {
      shader = program.fragmentShader();
    });
  }

  void _startTransition() {
    if (_isRevealed) {
      _controller.reverse(); // Cover screen
    } else {
      _controller.forward(); // Reveal screen
    }
    setState(() => _isRevealed = !_isRevealed);
  }

  @override
  Widget build(BuildContext context) {
    if (shader == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      body: Stack(
        children: [
          // BOTTOM LAYER: Your actual Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("HIDDEN CONTENT REVEALED", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Image.network('https://picsum.photos/400/300'),
                const SizedBox(height: 20),
                ElevatedButton(onPressed: _startTransition, child: const Text("Reset Transition")),
              ],
            ),
          ),

          // TOP LAYER: The Shader Transition
          // We use IgnorePointer so the user can click the buttons "through" the shader if it's transparent
          IgnorePointer(
            ignoring: _isRevealed,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: DiamondTransitionPainter(
                    shader: shader!,
                    // Note: 1.0 - value to make "forward" a reveal effect
                    progress: 1.0 - _controller.value,
                  ),
                  child: Container(),
                );
              },
            ),
          ),

          // Floating Action Button to trigger the effect
          Positioned(
            bottom: 30,
            right: 30,
            child: FloatingActionButton(onPressed: _startTransition, child: Icon(_isRevealed ? Icons.visibility_off : Icons.play_arrow)),
          ),
        ],
      ),
    );
  }
}

class DiamondTransitionPainter extends CustomPainter {
  final ui.FragmentShader shader;
  final double progress;

  DiamondTransitionPainter({required this.shader, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    shader.setFloat(0, progress); // uProgress
    shader.setFloat(1, size.width); // uResolution x
    shader.setFloat(2, size.height); // uResolution y
    shader.setFloat(3, 40.0); // uDiamondSize (Try changing this!)

    final paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(DiamondTransitionPainter oldDelegate) => oldDelegate.progress != progress;
}
