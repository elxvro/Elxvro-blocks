import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:elxvro_blocks/models/adventure_level.dart';

void main() {
  test('Adventure 2.0 point target rises on every level', () {
    var previous = 0;
    for (var level = 1; level <= adventureLevelCount; level++) {
      final data = adventureLevelFor(level);
      expect(data.fallingTargetScore, greaterThan(previous));
      previous = data.fallingTargetScore;
    }

    expect(adventureLevelFor(1).fallingTargetScore, 1000);
    expect(adventureLevelFor(60).fallingTargetScore, greaterThan(50000));
  });

  test('Adventure 2.0 speed never gets easier as levels rise', () {
    var previous = adventureLevelFor(1).fallingIntervalMs;
    for (var level = 2; level <= adventureLevelCount; level++) {
      final current = adventureLevelFor(level).fallingIntervalMs;
      expect(current, lessThanOrEqualTo(previous));
      previous = current;
    }
  });

  test('Falling Adventure completes by score and keeps level color cycling', () {
    final source =
        File('lib/screens/falling_blocks_screen.dart').readAsStringSync();
    expect(source, contains('_score >= _targetScore'));
    expect(source, contains('colorCycle'));
    expect(source, contains('_ghostCells'));
  });
}
