import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shader_transitions/shader_transitions.dart';

// Shaders can't load in unit tests, so routes render the FadeTransition
// fallback — the swipe logic under test is independent of the mask.

final GlobalKey<_CounterPageState> _pageKey = GlobalKey();

class _CounterPage extends StatefulWidget {
  const _CounterPage({super.key, this.canPop = true});

  final bool canPop;

  @override
  State<_CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<_CounterPage> {
  int count = 0;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.canPop,
      child: ColoredBox(
        color: const Color(0xFF0000FF),
        child: Center(child: Text('page $count')),
      ),
    );
  }
}

class _Calls {
  int starts = 0;
  int completes = 0;
}

Future<_Calls> _pushPage(
  WidgetTester tester, {
  required TargetPlatform platform,
  bool? swipeBack,
  bool canPop = true,
  TextDirection textDirection = TextDirection.ltr,
}) async {
  final calls = _Calls();
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(platform: platform),
      builder: (context, child) =>
          Directionality(textDirection: textDirection, child: child!),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(
                ShaderPageRoute<void>(
                  page: _CounterPage(key: _pageKey, canPop: canPop),
                  transition: const ShaderTransition.wipe(
                    duration: Duration(milliseconds: 300),
                  ),
                  swipeBack: swipeBack,
                  onStart: () => calls.starts++,
                  onComplete: () => calls.completes++,
                ),
              ),
              child: const Text('push'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('push'));
  await tester.pumpAndSettle();
  expect(find.text('page 0'), findsOneWidget);
  return calls;
}

Animation<double> get _routeAnimation =>
    ModalRoute.of(_pageKey.currentContext!)!.animation!;

NavigatorState get _navigator => Navigator.of(_pageKey.currentContext!);

/// Drags slowly (no fling) from the leading edge by [fraction] of the width.
Future<TestGesture> _slowDrag(
  WidgetTester tester,
  double fraction, {
  bool fromRight = false,
}) async {
  final width = tester.view.physicalSize.width / tester.view.devicePixelRatio;
  final start = Offset(fromRight ? width - 5 : 5, 300);
  final gesture = await tester.startGesture(start);
  final total = width * fraction * (fromRight ? -1 : 1);
  const steps = 10;
  for (var i = 0; i < steps; i++) {
    await gesture.moveBy(Offset(total / steps, 0));
    await tester.pump(const Duration(milliseconds: 100));
  }
  return gesture;
}

void main() {
  testWidgets('iOS: dragging scrubs the transition backwards',
      (tester) async {
    await _pushPage(tester, platform: TargetPlatform.iOS);
    final gesture = await _slowDrag(tester, 0.4);
    // Touch slop eats the first few px, so allow some tolerance.
    expect(_routeAnimation.value, closeTo(0.6, 0.05));
    expect(_navigator.userGestureInProgress, isTrue);
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('iOS: releasing past halfway pops', (tester) async {
    await _pushPage(tester, platform: TargetPlatform.iOS);
    final navigator = _navigator;
    final gesture = await _slowDrag(tester, 0.7);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('page 0'), findsNothing);
    expect(find.text('push'), findsOneWidget);
    expect(navigator.userGestureInProgress, isFalse);
  });

  testWidgets('iOS: releasing before halfway restores the page and its state',
      (tester) async {
    await _pushPage(tester, platform: TargetPlatform.iOS);
    final state = _pageKey.currentState!..count = 7;
    final gesture = await _slowDrag(tester, 0.3);
    // The mask switching on mid-swipe must not rebuild the page from scratch.
    expect(_pageKey.currentState, same(state));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(_routeAnimation.value, 1.0);
    expect(_pageKey.currentState, same(state));
    expect(_pageKey.currentState!.count, 7);
    expect(_navigator.userGestureInProgress, isFalse);
  });

  testWidgets('iOS: a fling pops even from a short drag', (tester) async {
    await _pushPage(tester, platform: TargetPlatform.iOS);
    await tester.flingFrom(const Offset(5, 300), const Offset(150, 0), 1500);
    await tester.pumpAndSettle();
    expect(find.text('page 0'), findsNothing);
  });

  testWidgets('settling after release takes at most 350 ms', (tester) async {
    await _pushPage(tester, platform: TargetPlatform.iOS);
    final gesture = await _slowDrag(tester, 0.3);
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(_routeAnimation.value, 1.0);
  });

  testWidgets('a swipe does not fire onStart / onComplete', (tester) async {
    final calls = await _pushPage(tester, platform: TargetPlatform.iOS);
    expect((calls.starts, calls.completes), (1, 1));

    var gesture = await _slowDrag(tester, 0.3); // cancelled
    await gesture.up();
    await tester.pumpAndSettle();
    expect((calls.starts, calls.completes), (1, 1));

    gesture = await _slowDrag(tester, 0.7); // pops
    await gesture.up();
    await tester.pumpAndSettle();
    expect((calls.starts, calls.completes), (1, 1));

    // A normal push afterwards still reports.
    await tester.tap(find.text('push'));
    await tester.pumpAndSettle();
    expect((calls.starts, calls.completes), (2, 2));
  });

  testWidgets('macOS follows iOS and swipes back', (tester) async {
    await _pushPage(tester, platform: TargetPlatform.macOS);
    final gesture = await _slowDrag(tester, 0.7);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('page 0'), findsNothing);
  });

  testWidgets('Android: no swipe back by default', (tester) async {
    await _pushPage(tester, platform: TargetPlatform.android);
    final gesture = await _slowDrag(tester, 0.7);
    expect(_routeAnimation.value, 1.0);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('page 0'), findsOneWidget);
  });

  testWidgets('swipeBack: true enables it on Android', (tester) async {
    await _pushPage(tester, platform: TargetPlatform.android, swipeBack: true);
    final gesture = await _slowDrag(tester, 0.7);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('page 0'), findsNothing);
  });

  testWidgets('swipeBack: false disables it on iOS', (tester) async {
    await _pushPage(tester, platform: TargetPlatform.iOS, swipeBack: false);
    final gesture = await _slowDrag(tester, 0.7);
    expect(_routeAnimation.value, 1.0);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('page 0'), findsOneWidget);
  });

  testWidgets('PopScope(canPop: false) blocks the swipe', (tester) async {
    await _pushPage(tester, platform: TargetPlatform.iOS, canPop: false);
    final gesture = await _slowDrag(tester, 0.7);
    expect(_routeAnimation.value, 1.0);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('page 0'), findsOneWidget);
  });

  testWidgets('drags away from the edge are ignored', (tester) async {
    await _pushPage(tester, platform: TargetPlatform.iOS);
    final gesture = await tester.startGesture(const Offset(200, 300));
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(const Offset(50, 0));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(_routeAnimation.value, 1.0);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('page 0'), findsOneWidget);
  });

  testWidgets('RTL: swipes from the right edge', (tester) async {
    await _pushPage(
      tester,
      platform: TargetPlatform.iOS,
      textDirection: TextDirection.rtl,
    );
    final gesture = await _slowDrag(tester, 0.7, fromRight: true);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('page 0'), findsNothing);
  });

  testWidgets('ShaderTransitions shortcuts forward swipeBack', (tester) async {
    final route = ShaderTransitions.circle<void>(
      page: const SizedBox(),
      swipeBack: false,
    );
    expect(route.swipeBack, isFalse);
    expect(ShaderTransitions.wipe<void>(page: const SizedBox()).swipeBack,
        isNull);
  });
}
