import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:elxvro_blocks/app_state.dart';
import 'package:elxvro_blocks/models/adventure_level.dart';
import 'package:elxvro_blocks/models/game_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('new premium themes are present and adventure-gated', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final state = AppState();
    await state.load();

    expect(gameThemes.any((theme) => theme.id == 'obsidian'), isTrue);
    expect(gameThemes.any((theme) => theme.id == 'polar_aurora'), isTrue);
    expect(gameThemes.any((theme) => theme.id == 'magma'), isTrue);
    expect(state.isThemeUnlocked('obsidian'), isFalse);

    for (var level = 1; level <= 15; level++) {
      final data = adventureLevelFor(level);
      await state.completeAdventureLevel(
        level: level,
        reward: data.reward,
        score: data.targetScore,
      );
    }

    expect(state.isThemeUnlocked('obsidian'), isTrue);
    expect(state.isThemeUnlocked('polar_aurora'), isFalse);
  });

  test('Falling Blocks best score only moves upward and persists', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final state = AppState();
    await state.load();

    await state.recordFallingBlocksScore(4200);
    await state.recordFallingBlocksScore(1200);
    expect(state.fallingBlocksBestScore, 4200);

    final restored = AppState();
    await restored.load();
    expect(restored.fallingBlocksBestScore, 4200);
  });
}
