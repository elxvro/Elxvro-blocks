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

  test('v0.22.1 localization patch covers secondary screens', () {
    final patch = File('../../.github/scripts/apply_v0221.py').readAsStringSync();
    for (final screen in <String>[
      'rewards_screen.dart',
      'store_screen.dart',
      'daily_missions_screen.dart',
      'achievements_screen.dart',
      'stats_screen.dart',
      'social_hub_screen.dart',
      'profile_screen.dart',
    ]) {
      expect(patch, contains(screen));
    }
    expect(patch, contains('NEW PERSONAL BEST'));
    expect(patch, contains('DAILY MISSIONS'));
    expect(patch, contains('LEADERBOARD HUB'));
  });
}
