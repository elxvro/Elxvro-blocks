import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('gameplay background does not use canvas/custom paint', () {
    final source = File('lib/widgets/gameplay_background.dart').readAsStringSync();
    expect(source, isNot(contains('CustomPaint')));
    expect(source, isNot(contains('Canvas ')));
    expect(source, isNot(contains('CustomPainter')));
    expect(source, contains('DecoratedBox'));
  });

  test('v0.22.1 final source localizes secondary screens', () {
    for (final screen in <String>[
      'rewards_screen.dart',
      'store_screen.dart',
      'daily_missions_screen.dart',
      'achievements_screen.dart',
      'stats_screen.dart',
      'social_hub_screen.dart',
      'profile_screen.dart',
    ]) {
      final source = File('lib/screens/$screen').readAsStringSync();
      expect(
        source.contains('AppStrings.current') ||
            source.contains('AppStrings(') ||
            source.contains('.f('),
        isTrue,
        reason: '$screen must use runtime localization',
      );
    }
  });
}
