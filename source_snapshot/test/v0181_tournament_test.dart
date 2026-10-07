import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:elxvro_blocks/app_state.dart';
import 'package:elxvro_blocks/models/adventure_level.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('adventure tournament score prioritizes progress and adds stars', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final state = AppState();
    await state.load();

    final level1 = adventureLevelFor(1);
    final level2 = adventureLevelFor(2);

    await state.completeAdventureLevel(
      level: 1,
      reward: level1.reward,
      score: level1.targetScore,
    );
    expect(state.adventureCompletedCount, 1);
    expect(state.adventureTotalStars, 1);
    expect(state.adventureTournamentScore, 1001);

    await state.completeAdventureLevel(
      level: 1,
      reward: level1.reward,
      score: (level1.targetScore * 1.6).round(),
    );
    expect(state.adventureCompletedCount, 1);
    expect(state.adventureTotalStars, 3);
    expect(state.adventureTournamentScore, 1003);

    await state.completeAdventureLevel(
      level: 2,
      reward: level2.reward,
      score: (level2.targetScore * 1.25).round(),
    );
    expect(state.adventureCompletedCount, 2);
    expect(state.adventureTotalStars, 5);
    expect(state.adventureTournamentScore, 2005);
  });
}
