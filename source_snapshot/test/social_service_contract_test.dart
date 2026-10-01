import 'package:flutter_test/flutter_test.dart';
import 'package:elxvro_blocks/services/play_games_ids.dart';
import 'package:elxvro_blocks/services/social_service.dart';

void main() {
  test('local social service remains safe and disconnected', () async {
    const service = LocalSocialService();

    final info = await service.connectionInfo();
    expect(info.connected, isFalse);
    expect(await service.signIn(), isFalse);
    await service.submitScore(leaderboardId: 'unused', score: 99);
    await service.unlockAchievement(achievementId: 'unused');
    await service.showLeaderboards();
    await service.showAchievements();
  });

  test('play games ids permits partial configuration', () {
    const ids = PlayGamesIds(
      classicLeaderboardId: 'classic-id',
      comboRushLeaderboardId: '',
      achievementIds: <String, String>{'first_game': 'achievement-first'},
    );

    expect(ids.classicLeaderboardId, 'classic-id');
    expect(ids.comboRushLeaderboardId, isEmpty);
    expect(ids.achievementIdFor('first_game'), 'achievement-first');
    expect(ids.achievementIdFor('unknown'), isNull);
  });

  test('fromEnvironment is safe when build defines are missing', () {
    const ids = PlayGamesIds.fromEnvironment();
    expect(ids.classicLeaderboardId, isA<String>());
    expect(ids.comboRushLeaderboardId, isA<String>());
    expect(ids.achievementIds.keys, containsAll(<String>[
      'first_game',
      'score_1000',
      'combo_3',
      'lines_25',
      'games_10',
      'blocks_250',
      'score_10000',
      'level_5',
      'perfect_3',
      'level_15',
    ]));
    expect(ids.achievementIdFor('not_configured_local_id'), isNull);
  });
}
