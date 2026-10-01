import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:elxvro_blocks/app_state.dart';
import 'package:elxvro_blocks/models/game_mode.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('combo rush is a dedicated 120-second mode', () {
    final data = gameModeData[GameMode.comboRush]!;
    expect(data.id, 'combo_rush');
    expect(data.durationSeconds, 120);
    expect(data.title, 'COMBO RUSH');
  });

  test('combo rush records persist independently', () async {
    final state = AppState();
    await state.load();
    await state.recordComboRushResult(score: 4321, bestCombo: 7);

    expect(state.comboRushBestScore, 4321);
    expect(state.comboRushBestCombo, 7);

    final restored = AppState();
    await restored.load();
    expect(restored.comboRushBestScore, 4321);
    expect(restored.comboRushBestCombo, 7);
  });

  test('perfect clear bonus is fixed and persisted once per call', () async {
    final state = AppState();
    await state.load();
    final startCoins = state.coins;
    final startXp = state.xp;

    await state.grantPerfectClearBonus();

    expect(state.coins, startCoins + 100);
    expect(state.xp, startXp + 75);
  });
}
