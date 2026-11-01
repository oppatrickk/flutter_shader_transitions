// Renders the README demo GIFs into ../screenshots/.
//
//   cd example
//   flutter test --enable-impeller tool/readme_gifs_test.dart
//
// Fragment shaders render in `flutter test` when the test runs inside an app
// that depends on the package (so `packages/shader_transitions/...` assets
// resolve), so this needs no device or simulator.
//
// Frames are rendered at 2× and box-downsampled for anti-aliasing, mapped to
// one shared palette per GIF (no dithering, so unchanged areas stay
// byte-identical), and pixels that didn't change since the previous frame are
// written transparent — each frame then stores only what the transition
// touched.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:shader_transitions/shader_transitions.dart';

const int _frameMs = 40; // 25 fps; GIF delays are whole 1/100 s.
const int _supersample = 2;
const Size _squareSize = Size(320, 320);
const Size _heroSize = Size(640, 360);

final GlobalKey _boundaryKey = GlobalKey();

// ---------------------------------------------------------------------------
// Timelines
// ---------------------------------------------------------------------------

sealed class _Step {
  const _Step();
}

/// Shows [page] still for [ms].
class _Hold extends _Step {
  const _Hold(this.page, this.ms);
  final Widget page;
  final int ms;
}

/// [over] masked by [transition] on top of [under]: progress 0 → 1 (a push
/// revealing [over]) or, with [pop], 1 → 0 (popping [over] off again).
class _Play extends _Step {
  const _Play(this.transition, {required this.under, required this.over})
      : pop = false;
  const _Play.pop(this.transition, {required this.under, required this.over})
      : pop = true;
  final ShaderTransition transition;
  final Widget under;
  final Widget over;
  final bool pop;
}

/// A square loop: push the dark page, hold, pop back to the light one.
List<_Step> _squareLoop(ShaderTransition t) => [
      const _Hold(_lightPage, 700),
      _Play(t, under: _lightPage, over: _darkPage),
      const _Hold(_darkPage, 900),
      _Play.pop(t, under: _lightPage, over: _darkPage),
    ];

const Widget _lightPage = ColoredBox(
  color: Color(0xFFF1F5FB),
  child: Center(child: FlutterLogo(size: 150)),
);

const Widget _darkPage = ColoredBox(
  color: Color(0xFF042B59),
  child: Center(
    child: ColorFiltered(
      colorFilter: ColorFilter.mode(Color(0xFFFFFFFF), BlendMode.srcIn),
      child: FlutterLogo(size: 150),
    ),
  ),
);

Widget _scene(ui.Image image) =>
    RawImage(image: image, fit: BoxFit.cover, filterQuality: FilterQuality.high);

// ---------------------------------------------------------------------------
// Rendering
// ---------------------------------------------------------------------------

Future<img.Image> _renderFrame(
  WidgetTester tester,
  Widget content,
  Size size,
) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topLeft,
        child: RepaintBoundary(
          key: _boundaryKey,
          child: SizedBox.fromSize(size: size, child: content),
        ),
      ),
    ),
  );
  final boundary =
      tester.renderObject<RenderRepaintBoundary>(find.byKey(_boundaryKey));
  return (await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: _supersample.toDouble());
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final frame = _downsample(
      data!.buffer.asUint8List(),
      image.width,
      image.height,
    );
    image.dispose();
    return frame;
  }))!;
}

/// Box-filters an RGBA buffer down by [_supersample].
img.Image _downsample(Uint8List rgba, int width, int height) {
  const s = _supersample;
  final w = width ~/ s, h = height ~/ s;
  final out = Uint8List(w * h * 3);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      var r = 0, g = 0, b = 0;
      for (var dy = 0; dy < s; dy++) {
        var i = ((y * s + dy) * width + x * s) * 4;
        for (var dx = 0; dx < s; dx++, i += 4) {
          r += rgba[i];
          g += rgba[i + 1];
          b += rgba[i + 2];
        }
      }
      final o = (y * w + x) * 3;
      out[o] = r ~/ (s * s);
      out[o + 1] = g ~/ (s * s);
      out[o + 2] = b ~/ (s * s);
    }
  }
  return img.Image.fromBytes(
    width: w,
    height: h,
    bytes: out.buffer,
    numChannels: 3,
  );
}

Future<List<(img.Image, int)>> _renderTimeline(
  WidgetTester tester,
  List<_Step> steps,
  Size size,
) async {
  final frames = <(img.Image, int)>[];
  for (final step in steps) {
    switch (step) {
      case _Hold(:final page, :final ms):
        frames.add((await _renderFrame(tester, page, size), ms));
      case _Play(:final transition, :final under, :final over, :final pop):
        final n = (transition.duration.inMilliseconds / _frameMs).round();
        // Endpoints are the neighbouring holds; render only the in-betweens.
        for (var i = 1; i < n; i++) {
          final t = i / n;
          final progress = pop ? 1.0 - t : t;
          final content = Stack(
            fit: StackFit.expand,
            children: [
              under,
              Builder(
                builder: (context) =>
                    ShaderTransitionBuilders.create(transition)(
                  context,
                  AlwaysStoppedAnimation<double>(progress),
                  kAlwaysDismissedAnimation,
                  over,
                ),
              ),
            ],
          );
          frames.add((await _renderFrame(tester, content, size), _frameMs));
        }
    }
  }
  return frames;
}

// ---------------------------------------------------------------------------
// GIF encoding
// ---------------------------------------------------------------------------

Uint8List _encodeGif(List<(img.Image, int)> frames) {
  final w = frames.first.$1.width, h = frames.first.$1.height;

  // Shared palette from a montage of sampled frames (both pages and the
  // in-between blends), leaving one slot for transparency.
  final step = math.max(1, frames.length ~/ 24);
  final samples = [
    for (var i = 0; i < frames.length; i += step) frames[i].$1,
  ];
  final montage = img.Image(width: w, height: h * samples.length);
  for (var i = 0; i < samples.length; i++) {
    img.compositeImage(montage, samples[i], dstY: i * h);
  }
  final source = img.OctreeQuantizer(montage, numberOfColors: 255).palette;
  final colors = source.numColors;
  final palette = img.PaletteUint8(colors + 1, 4);
  final pr = Int32List(colors), pg = Int32List(colors), pb = Int32List(colors);
  for (var i = 0; i < colors; i++) {
    pr[i] = source.getRed(i).toInt();
    pg[i] = source.getGreen(i).toInt();
    pb[i] = source.getBlue(i).toInt();
    palette.setRgba(i, pr[i], pg[i], pb[i], 255);
  }
  final transparent = colors;
  palette.setRgba(transparent, 0, 0, 0, 0);

  // Exact nearest-colour lookup (the octree's own lookup can miss colours
  // that weren't in the sample), cached per RGB.
  final cache = <int, int>{};
  int nearest(int r, int g, int b) => cache[(r << 16) | (g << 8) | b] ??= () {
        var best = 0, bestD = 1 << 30;
        for (var i = 0; i < colors; i++) {
          final dr = r - pr[i], dg = g - pg[i], db = b - pb[i];
          final d = 2 * dr * dr + 4 * dg * dg + 3 * db * db;
          if (d < bestD) {
            bestD = d;
            best = i;
          }
        }
        return best;
      }();

  final encoder = img.GifEncoder(dispose: 1); // keep previous frame
  Uint8List? previous;
  for (final (frame, ms) in frames) {
    final rgb = frame.toUint8List();
    final indices = Uint8List(w * h);
    for (var p = 0, i = 0; p < indices.length; p++, i += 3) {
      indices[p] = nearest(rgb[i], rgb[i + 1], rgb[i + 2]);
    }
    final written = Uint8List.fromList(indices);
    if (previous != null) {
      for (var p = 0; p < written.length; p++) {
        if (written[p] == previous[p]) written[p] = transparent;
      }
    }
    previous = indices;
    encoder.addFrame(
      img.Image.fromBytes(
        width: w,
        height: h,
        bytes: written.buffer,
        numChannels: 1,
        palette: palette,
      ),
      duration: (ms / 10).round(),
    );
  }
  return encoder.finish()!;
}

Future<void> _writeGif(
  WidgetTester tester,
  String name,
  List<_Step> steps,
  Size size,
) async {
  final frames = await _renderTimeline(tester, steps, size);
  final bytes = _encodeGif(frames);
  final file = File('../screenshots/$name.gif');
  await tester.runAsync(() => file.writeAsBytes(bytes));
  // ignore: avoid_print
  print('${file.path}: ${frames.length} frames, '
      '${(bytes.length / 1024).toStringAsFixed(0)} KB');
}

Future<ui.Image> _loadScene(String path) async {
  final bytes = await File(path).readAsBytes();
  final codec = await ui.instantiateImageCodec(
    bytes,
    targetWidth: (_heroSize.width * _supersample).round(),
  );
  return (await codec.getNextFrame()).image;
}

void main() {
  testWidgets('render README GIFs', (tester) async {
    await tester.runAsync(ShaderTransitions.preload);
    expect(ShaderTransitions.isReady, isTrue, reason: 'shaders must load');

    const squares = <String, ShaderTransition>{
      'diamond': ShaderTransition.diamond(),
      'circle': ShaderTransition.circle(),
      'wipe': ShaderTransition.wipe(softness: 6),
      'clock': ShaderTransition.clock(),
      'polygon': ShaderTransition.polygon(),
      'dissolve': ShaderTransition.dissolve(),
      'fade': ShaderTransition.fade(),
      'bars': ShaderTransition.bars(),
      'cover-fade': ShaderTransition.wipe(
        softness: 6,
        duration: Duration(milliseconds: 1600),
        cover: TransitionCover(
          color: Color(0xFF000000),
          hold: Duration(milliseconds: 600),
        ),
      ),
    };
    for (final MapEntry(key: name, value: t) in squares.entries) {
      await _writeGif(tester, name, _squareLoop(t), _squareSize);
    }

    // Hero reel: the two game scenes, cycling diamond → circle → wipe →
    // cover, ending where it started so the loop is seamless.
    final scenes = (await tester.runAsync(() async => (
          await _loadScene('assets/scene_1.jpg'),
          await _loadScene('assets/scene_2.jpg'),
        )))!;
    final meadow = _scene(scenes.$1), cave = _scene(scenes.$2);
    await _writeGif(
      tester,
      'hero',
      [
        _Hold(meadow, 900),
        _Play(
          const ShaderTransition.diamond(duration: Duration(milliseconds: 900)),
          under: meadow,
          over: cave,
        ),
        _Hold(cave, 700),
        _Play(const ShaderTransition.circle(), under: cave, over: meadow),
        _Hold(meadow, 700),
        _Play(
          const ShaderTransition.wipe(
            softness: 8,
            direction: SweepDirection.topLeftToBottomRight,
            duration: Duration(milliseconds: 700),
          ),
          under: meadow,
          over: cave,
        ),
        _Hold(cave, 700),
        _Play(
          const ShaderTransition.circle(
            duration: Duration(milliseconds: 1400),
            cover: TransitionCover(
              color: Color(0xFF000000),
              hold: Duration(milliseconds: 300),
            ),
          ),
          under: cave,
          over: meadow,
        ),
      ],
      _heroSize,
    );
  }, timeout: const Timeout(Duration(minutes: 10)));
}
