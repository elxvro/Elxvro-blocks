import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:elxvro_blocks/models/adventure_level.dart';
import 'package:elxvro_blocks/models/game_theme.dart';
import 'package:elxvro_blocks/widgets/premium_background.dart';
import 'package:elxvro_blocks/widgets/themed_block_tile.dart';

void main() {
  test('Falling Adventure gets progressively harder across 60 levels', () {
    final first = adventureLevelFor(1);
    final middle = adventureLevelFor(30);
    final last = adventureLevelFor(60);

    expect(first.fallingTargetLines, lessThan(middle.fallingTargetLines));
    expect(middle.fallingTargetLines, lessThanOrEqualTo(last.fallingTargetLines));
    expect(first.fallingIntervalMs, greaterThan(middle.fallingIntervalMs));
    expect(middle.fallingIntervalMs, greaterThan(last.fallingIntervalMs));
    expect(last.fallingTargetLines, lessThanOrEqualTo(26));
    expect(last.fallingIntervalMs, greaterThanOrEqualTo(135));
  });

  testWidgets('raindrop background and physical material blocks render',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PremiumBackground(
            top: Color(0xFF13516B),
            bottom: Color(0xFF061923),
            material: ThemeMaterial.glass,
            accent: Color(0xFFE8FCFF),
            child: Center(
              child: SizedBox(
                width: 48,
                height: 48,
                child: ThemedBlockTile(
                  material: ThemeMaterial.glass,
                  base: Color(0xFF63DDF7),
                  accent: Color(0xFFE8FCFF),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 120));
    expect(find.byType(PremiumBackground), findsOneWidget);
    expect(find.byType(ThemedBlockTile), findsOneWidget);
  });
}
