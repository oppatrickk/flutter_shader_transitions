import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shader_transitions/shader_transitions.dart';

void main() {
  group('ShaderTransition named constructors', () {
    test('return the matching subtype', () {
      const transitions = <ShaderTransition>[
        ShaderTransition.diamond(),
        ShaderTransition.circle(),
        ShaderTransition.wipe(),
        ShaderTransition.clock(),
        ShaderTransition.polygon(),
        ShaderTransition.dissolve(),
        ShaderTransition.fade(),
        ShaderTransition.bars(),
      ];
      expect(transitions.map((t) => t.runtimeType), [
        DiamondTransition,
        CircleTransition,
        WipeTransition,
        ClockTransition,
        PolygonTransition,
        DissolveTransition,
        FadeShaderTransition,
        BarsTransition,
      ]);
    });

    test('use the subtype defaults when arguments are omitted', () {
      const diamond = ShaderTransition.diamond() as DiamondTransition;
      expect(diamond.cellSize, 40.0);
      expect(diamond.feather, 0.0);
      expect(diamond.direction, SweepDirection.topLeftToBottomRight);
      expect(diamond.duration, const Duration(milliseconds: 800));
      expect(diamond.cover, isNull);
      expect(diamond.invert, isFalse);

      const polygon = ShaderTransition.polygon() as PolygonTransition;
      expect(polygon.sides, 6);
      expect(polygon.origin, Alignment.center);
      expect(polygon.duration, const Duration(milliseconds: 700));

      expect(
        const ShaderTransition.fade().duration,
        const Duration(milliseconds: 400),
      );
    });

    test('forward every argument', () {
      const cover = TransitionCover(
        color: Colors.black,
        hold: Duration(milliseconds: 200),
      );
      const bars = ShaderTransition.bars(
        count: 9,
        softness: 1.5,
        direction: SweepDirection.topToBottom,
        duration: Duration(milliseconds: 950),
        cover: cover,
        invert: true,
      ) as BarsTransition;
      expect(bars.count, 9);
      expect(bars.softness, 1.5);
      expect(bars.direction, SweepDirection.topToBottom);
      expect(bars.duration, const Duration(milliseconds: 950));
      expect(bars.cover, same(cover));
      expect(bars.invert, isTrue);
    });

    test('drive ShaderPageRoute timing', () {
      final route = ShaderPageRoute<void>(
        page: const SizedBox(),
        transition: const ShaderTransition.clock(
          duration: Duration(milliseconds: 1234),
        ),
      );
      expect(route.transitionDuration, const Duration(milliseconds: 1234));
      expect(
          route.reverseTransitionDuration, const Duration(milliseconds: 1234));
      expect(route.opaque, isFalse);
    });
  });
}
