// On-device rendering checks for every transition.
//
// Unit tests can't load fragment shaders, so this suite runs on a real GPU
// backend (Impeller/Metal on iOS, Impeller/Vulkan or GLES on Android) and
// reads rendered pixels back to verify each mask's geometry.
//
//   flutter test integration_test -d <device-or-simulator-id>
//
// Every frame paints a red "outgoing" page under a blue "incoming" page
// masked by the transition, frozen at a known progress. The masked area is
// inset from the captured image's origin so coordinate-space mistakes (DPR
// scaling, absolute vs local FlutterFragCoord, y-flip) show up as wrong
// colors at the probe points.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shader_transitions/shader_transitions.dart';
import 'package:shader_transitions_example/main.dart';
import 'package:shader_transitions_example/screens/gallery_screen.dart';

const Color _red = Color(0xFFFF0000);
const Color _blue = Color(0xFF0000FF);
const Color _green = Color(0xFF00FF00);
const EdgeInsets _inset = EdgeInsets.fromLTRB(37, 53, 11, 7);

final Key _boundaryKey = UniqueKey();
final Key _areaKey = UniqueKey();

enum Px { red, blue, green, mixed }

Px _classify(int r, int g, int b) {
  bool hi(int v) => v > 190;
  bool lo(int v) => v < 70;
  if (hi(r) && lo(g) && lo(b)) return Px.red;
  if (lo(r) && lo(g) && hi(b)) return Px.blue;
  if (lo(r) && hi(g) && lo(b)) return Px.green;
  return Px.mixed;
}

/// A captured frame, addressed in normalized coordinates of the masked area.
class _Shot {
  _Shot(this._bytes, this._width, this._area, this._dpr);

  final ByteData _bytes;
  final int _width;
  final Rect _area; // logical px, relative to the captured boundary
  final double _dpr;

  (int, int, int) rgbAt(double u, double v) {
    final x = ((_area.left + u * _area.width) * _dpr).floor();
    final y = ((_area.top + v * _area.height) * _dpr).floor();
    final i = (y * _width + x) * 4;
    return (_bytes.getUint8(i), _bytes.getUint8(i + 1), _bytes.getUint8(i + 2));
  }

  Px at(double u, double v) {
    final (r, g, b) = rgbAt(u, v);
    return _classify(r, g, b);
  }

  /// `Px` at the centre of logical pixel ([col], [row]) of the masked area.
  Px atLogicalPixel(int col, int row) => at(
        (col + 0.5) / _area.width,
        (row + 0.5) / _area.height,
      );

  Size get areaSize => _area.size;
}

Widget _frame(ShaderTransition transition, double progress) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: RepaintBoundary(
      key: _boundaryKey,
      child: ColoredBox(
        color: const Color(0xFF000000),
        child: Padding(
          padding: _inset,
          child: SizedBox.expand(
            key: _areaKey,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: _red),
                Builder(
                  builder: (context) => ShaderTransitionBuilders.create(
                    transition,
                  )(
                    context,
                    AlwaysStoppedAnimation<double>(progress),
                    kAlwaysDismissedAnimation,
                    const ColoredBox(color: _blue),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

Future<_Shot> _render(
  WidgetTester tester,
  ShaderTransition transition,
  double progress,
) async {
  await tester.pumpWidget(_frame(transition, progress));
  await tester.pump();
  return _capture(tester, area: find.byKey(_areaKey));
}

/// Reads back what's under [_boundaryKey]; probes are normalized to [area]
/// (default: the whole boundary).
Future<_Shot> _capture(WidgetTester tester, {Finder? area}) async {
  final boundary =
      tester.renderObject<RenderRepaintBoundary>(find.byKey(_boundaryKey));
  final dpr = tester.view.devicePixelRatio;
  final image = await boundary.toImage(pixelRatio: dpr);
  final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  final width = image.width;
  image.dispose();

  final origin = tester.getTopLeft(find.byKey(_boundaryKey));
  final rect = tester.getRect(area ?? find.byKey(_boundaryKey)).shift(-origin);
  return _Shot(bytes, width, rect, dpr);
}

class _StatefulPage extends StatefulWidget {
  const _StatefulPage({super.key});

  @override
  State<_StatefulPage> createState() => _StatefulPageState();
}

class _StatefulPageState extends State<_StatefulPage> {
  @override
  Widget build(BuildContext context) => const ColoredBox(color: _blue);
}

void _expectProbes(_Shot shot, Map<(double, double), Px> probes) {
  for (final MapEntry(key: (u, v), value: expected) in probes.entries) {
    expect(
      shot.at(u, v),
      expected,
      reason: 'pixel at normalized ($u, $v) was rgb${shot.rgbAt(u, v)}',
    );
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await ShaderTransitions.preload();
  });

  testWidgets('every bundled shader compiles on this device', (tester) async {
    // If any .frag fails to load, preload() swallows the error and every
    // transition silently degrades to a FadeTransition.
    expect(ShaderTransitions.isReady, isTrue);
    for (final key in const [
      'diamond',
      'circle',
      'wipe',
      'clock',
      'polygon',
      'dissolve',
      'fade',
      'bars',
    ]) {
      final shader = ShaderRegistry.instance.createShader(key);
      expect(shader, isNotNull, reason: '$key.frag');
      shader!.dispose();
    }
  });

  group('mask geometry', () {
    testWidgets('wipe left → right', (tester) async {
      final shot = await _render(
        tester,
        const ShaderTransition.wipe(softness: 0),
        0.5,
      );
      _expectProbes(shot, {
        (0.05, 0.05): Px.blue,
        (0.25, 0.5): Px.blue,
        (0.45, 0.95): Px.blue,
        (0.55, 0.05): Px.red,
        (0.75, 0.5): Px.red,
        (0.95, 0.95): Px.red,
      });
    });

    testWidgets('wipe right → left', (tester) async {
      final shot = await _render(
        tester,
        const ShaderTransition.wipe(
          softness: 0,
          direction: SweepDirection.rightToLeft,
        ),
        0.5,
      );
      _expectProbes(shot, {
        (0.25, 0.5): Px.red,
        (0.75, 0.5): Px.blue,
      });
    });

    testWidgets('wipe top → bottom (y orientation)', (tester) async {
      final shot = await _render(
        tester,
        const ShaderTransition.wipe(
          softness: 0,
          direction: SweepDirection.topToBottom,
        ),
        0.3,
      );
      _expectProbes(shot, {
        (0.5, 0.1): Px.blue,
        (0.5, 0.25): Px.blue,
        (0.5, 0.35): Px.red,
        (0.5, 0.9): Px.red,
      });
    });

    testWidgets('wipe invert', (tester) async {
      final shot = await _render(
        tester,
        const ShaderTransition.wipe(softness: 0, invert: true),
        0.5,
      );
      _expectProbes(shot, {
        (0.25, 0.5): Px.red,
        (0.75, 0.5): Px.blue,
      });
    });

    testWidgets('circle from center', (tester) async {
      final shot = await _render(
        tester,
        const ShaderTransition.circle(feather: 0),
        0.5,
      );
      // Radius at 0.5 is half the centre→corner distance.
      _expectProbes(shot, {
        (0.5, 0.5): Px.blue,
        (0.5, 0.4): Px.blue,
        (0.6, 0.5): Px.blue,
        (0.02, 0.02): Px.red,
        (0.98, 0.02): Px.red,
        (0.02, 0.98): Px.red,
        (0.98, 0.98): Px.red,
      });
    });

    testWidgets('circle from top-left origin', (tester) async {
      final shot = await _render(
        tester,
        const ShaderTransition.circle(feather: 0, origin: Alignment.topLeft),
        0.5,
      );
      _expectProbes(shot, {
        (0.05, 0.05): Px.blue,
        (0.3, 0.3): Px.blue,
        (0.7, 0.7): Px.red,
        (0.95, 0.95): Px.red,
      });
    });

    testWidgets('circle invert (contracting)', (tester) async {
      final shot = await _render(
        tester,
        const ShaderTransition.circle(feather: 0, invert: true),
        0.5,
      );
      _expectProbes(shot, {
        (0.5, 0.5): Px.red,
        (0.02, 0.02): Px.blue,
        (0.98, 0.98): Px.blue,
      });
    });

    testWidgets('polygon (square) from center', (tester) async {
      final shot = await _render(
        tester,
        const ShaderTransition.polygon(sides: 4, feather: 0),
        0.4,
      );
      _expectProbes(shot, {
        (0.5, 0.5): Px.blue,
        (0.55, 0.55): Px.blue,
        (0.02, 0.02): Px.red,
        (0.98, 0.98): Px.red,
      });
    });

    testWidgets('clock sweeps clockwise from 3 o\'clock', (tester) async {
      final shot = await _render(
        tester,
        const ShaderTransition.clock(feather: 0),
        0.5,
      );
      // Half a turn clockwise (screen y down) reveals the lower half.
      _expectProbes(shot, {
        (0.5, 0.8): Px.blue,
        (0.8, 0.6): Px.blue,
        (0.2, 0.8): Px.blue,
        (0.5, 0.2): Px.red,
        (0.8, 0.4): Px.red,
        (0.2, 0.2): Px.red,
      });
    });

    testWidgets('bars left → right', (tester) async {
      final shot = await _render(
        tester,
        const ShaderTransition.bars(count: 4, softness: 0),
        0.5,
      );
      _expectProbes(shot, {
        for (var k = 0; k < 4; k++) ...{
          ((k + 0.25) / 4, 0.5): Px.blue,
          ((k + 0.75) / 4, 0.5): Px.red,
        },
      });
    });

    testWidgets('diamond top-left → bottom-right', (tester) async {
      final shot = await _render(
        tester,
        const ShaderTransition.diamond(),
        0.5,
      );
      // Behind the band everything is revealed; ahead of it nothing is.
      _expectProbes(shot, {
        (0.04, 0.04): Px.blue,
        (0.1, 0.15): Px.blue,
        (0.9, 0.85): Px.red,
        (0.96, 0.96): Px.red,
      });
    });

    testWidgets('fade is a uniform 50% mix', (tester) async {
      final shot = await _render(tester, const ShaderTransition.fade(), 0.5);
      for (final (u, v) in const [(0.1, 0.1), (0.5, 0.5), (0.9, 0.9)]) {
        final (r, g, b) = shot.rgbAt(u, v);
        expect(r, inInclusiveRange(90, 170), reason: 'red at ($u, $v)');
        expect(g, lessThan(40), reason: 'green at ($u, $v)');
        expect(b, inInclusiveRange(90, 170), reason: 'blue at ($u, $v)');
      }
    });

    testWidgets('dissolve is unstructured noise', (tester) async {
      final shot = await _render(
        tester,
        const ShaderTransition.dissolve(grain: 0),
        0.5,
      );
      // Sample one probe per logical pixel across a large block (large
      // coordinates stress the hash's float precision on mobile GPUs).
      final cols = (shot.areaSize.width - 1).floor();
      final rows = (shot.areaSize.height - 1).floor();
      var blue = 0, total = 0, sameH = 0, pairsH = 0, sameV = 0, pairsV = 0;
      final grid = List.generate(
        rows,
        (r) => List.generate(cols, (c) => shot.atLogicalPixel(c, r) == Px.blue),
      );
      for (var r = 0; r < rows; r++) {
        for (var c = 0; c < cols; c++) {
          total++;
          if (grid[r][c]) blue++;
          if (c + 1 < cols) {
            pairsH++;
            if (grid[r][c] == grid[r][c + 1]) sameH++;
          }
          if (r + 1 < rows) {
            pairsV++;
            if (grid[r][c] == grid[r + 1][c]) sameV++;
          }
        }
      }
      // Half the grains have crossed their threshold…
      expect(blue / total, inInclusiveRange(0.4, 0.6));
      // …and neighbours are uncorrelated: stripes or blocks from a broken
      // hash push neighbour agreement toward 0 or 1.
      expect(sameH / pairsH, inInclusiveRange(0.4, 0.6), reason: 'horizontal');
      expect(sameV / pairsV, inInclusiveRange(0.4, 0.6), reason: 'vertical');
    });

    testWidgets('settled animation shows the page unmasked', (tester) async {
      final shot = await _render(
        tester,
        const ShaderTransition.dissolve(grain: 0),
        1.0,
      );
      for (var r = 0; r < 40; r++) {
        for (var c = 0; c < 40; c++) {
          expect(shot.atLogicalPixel(c * 3, r * 5), Px.blue);
        }
      }
    });

    testWidgets('cover: color wipes in, then the page wipes in', (tester) async {
      const t = ShaderTransition.wipe(
        softness: 0,
        duration: Duration(milliseconds: 1000),
        cover: TransitionCover(color: _green),
      );
      // hold 0 → cover owns t∈[0, .5), page owns [.5, 1].
      _expectProbes(await _render(tester, t, 0.25), {
        (0.25, 0.5): Px.green,
        (0.75, 0.5): Px.red,
      });
      _expectProbes(await _render(tester, t, 0.75), {
        (0.25, 0.5): Px.blue,
        (0.75, 0.5): Px.green,
      });
    });
  });

  testWidgets('back swipe scrubs the real shader mask', (tester) async {
    final pageKey = GlobalKey<_StatefulPageState>();
    await tester.pumpWidget(
      RepaintBoundary(
        key: _boundaryKey,
        child: MaterialApp(
          // Pinned so the swipe is on wherever this suite runs.
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: Builder(
            builder: (context) => Scaffold(
              backgroundColor: _red,
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    ShaderPageRoute<void>(
                      page: _StatefulPage(key: pageKey),
                      transition: const ShaderTransition.wipe(
                        softness: 0,
                        duration: Duration(milliseconds: 300),
                      ),
                    ),
                  ),
                  child: const Text('push'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('push'));
    await tester.pumpAndSettle();
    final state = pageKey.currentState!;
    final size = tester.getSize(find.byKey(_boundaryKey));
    final routeAnimation =
        ModalRoute.of(pageKey.currentContext!)!.animation!;

    Future<TestGesture> swipe(double fraction) async {
      final gesture = await tester.startGesture(Offset(5, size.height / 2));
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(Offset(size.width * fraction / 10, 0));
        await tester.pump(const Duration(milliseconds: 50));
      }
      return gesture;
    }

    // Mid-swipe the wipe is rewound: its edge sits at `value` of the width.
    var gesture = await swipe(0.4);
    final value = routeAnimation.value;
    expect(value, inExclusiveRange(0.5, 0.75));
    var shot = await _capture(tester);
    _expectProbes(shot, {
      (value - 0.15, 0.5): Px.blue,
      (value + 0.15, 0.5): Px.red,
    });
    // Switching the mask on must not rebuild the page from scratch.
    expect(pageKey.currentState, same(state));

    // Released before halfway: restored, same page state, fully unmasked.
    await gesture.up();
    await tester.pumpAndSettle();
    expect(routeAnimation.value, 1.0);
    expect(pageKey.currentState, same(state));
    shot = await _capture(tester);
    _expectProbes(shot, {(0.95, 0.5): Px.blue, (0.02, 0.5): Px.blue});

    // Released past halfway: popped back to the red page.
    gesture = await swipe(0.7);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(pageKey.currentState, isNull);
    shot = await _capture(tester);
    _expectProbes(shot, {(0.1, 0.1): Px.red, (0.9, 0.9): Px.red});
  });

  testWidgets('example app: push and pop every transition', (tester) async {
    await tester.pumpWidget(const ShaderTransitionsDemo());
    await tester.pumpAndSettle();

    for (final option in types) {
      await tester.ensureVisible(find.text(option.label));
      await tester.tap(find.text(option.label));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Test transition'));
      await tester.tap(find.text('Test transition'));
      // Let the shader route run mid-flight for a few frames, then settle.
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(find.text('Pop (reverse transition)'), findsOneWidget);

      await tester.tap(find.text('Pop (reverse transition)'));
      await tester.pumpAndSettle();
      expect(find.text('Test transition'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Shader Transitions'), findsOneWidget);
    }
  });
}
