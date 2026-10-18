import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:elxvro_blocks/game/drag_step_accumulator.dart';

void main() {
  test('fractional motion carries into subsequent events', () {
    final drag = DragStepAccumulator();
    expect(drag.update(10, 0).horizontal, 0);
    expect(drag.update(10, 0).horizontal, 0);
    expect(drag.update(6, 0).horizontal, 1);
    expect(drag.update(20, 0).horizontal, 1);
    expect(drag.update(-46, 0).horizontal, -2);
    drag.reset();
    expect(drag.update(20, 0).horizontal, 0);
  });

  test('fast swipes perform bounded multi-step moves in both directions', () {
    final drag = DragStepAccumulator();
    expect(drag.update(115, 0).horizontal, 5);
    expect(drag.update(-69, 0).horizontal, -3);
    expect(drag.update(2000, 0).horizontal, 6);
    drag.reset();
    expect(drag.update(-2000, 0).horizontal, -6);
  });

  test('downward movement accumulates; upward does not soft-drop', () {
    final drag = DragStepAccumulator();
    expect(drag.update(0, 14).downward, 0);
    expect(drag.update(0, 42).downward, 2);
    expect(drag.update(0, -70).downward, 0);
    expect(drag.update(0, 28).downward, 1);
    drag.reset();
    expect(drag.update(0, 20).downward, 0);
  });

  test('invalid pointer deltas cannot poison controls', () {
    final drag = DragStepAccumulator();
    drag.update(15, 12);
    final ignored = drag.update(double.nan, double.infinity);
    expect(ignored.horizontal, 0);
    expect(ignored.downward, 0);
    expect(drag.update(10, 15).horizontal, 0);
    expect(drag.update(13, 13).horizontal, 1);
  });

  test('events never process more than six cells per update', () {
    final drag = DragStepAccumulator();
    for (var i = 0; i < 2000; i++) {
      final steps = drag.update(i.isEven ? 17 : -11, 9);
      expect(steps.horizontal.abs(), lessThanOrEqualTo(6));
      expect(steps.downward, inInclusiveRange(0, 6));
    }
  });

  test('board caches palette/cell decoration and uses isolated FX', () {
    final screen = File('lib/screens/falling_blocks_screen.dart').readAsStringSync();
    final effects = File('lib/widgets/falling_impact_overlay.dart').readAsStringSync();
    final audio = File('lib/services/audio_service.dart').readAsStringSync();
    expect(screen, contains('final palette = _palette;'));
    expect(screen, contains('if (!filled) return emptyCell;'));
    expect(screen, contains('addAutomaticKeepAlives: false'));
    expect(screen, contains('onPanCancel: _onPanCancel'));
    expect(screen, contains('void _softDrop(int steps)'));
    expect(screen, contains('widget.appState.performanceMode ? 440 : 880'));
    expect(screen, contains('_fallImpactController.stop()'));
    expect(effects, contains('final sprites = List<Image>.generate('));
    expect(effects, contains('child: sprites[shard % sprites.length]'));
    expect(effects, contains('RepaintBoundary(child: IgnorePointer('));
    expect(audio, contains("asset.contains('_place_v')"));
    expect(audio, contains('now - previous < 45'));
  });
}
