import 'package:flutter_test/flutter_test.dart';
import 'package:shader_transitions_example/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    // ShaderTransitions.preload() is skipped in tests — shaders gracefully
    // fall back to FadeTransition when not preloaded.
    await tester.pumpWidget(const ShaderTransitionsDemo());
    expect(find.text('Shader Transitions'), findsOneWidget);
  });
}
