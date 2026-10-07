import 'package:flutter_test/flutter_test.dart';
import 'package:elxvro_blocks/services/play_games_ids.dart';
import 'package:elxvro_blocks/services/play_games_service.dart';

class FakeGamesPlatformAdapter implements GamesPlatformAdapter {
  bool signInResult = true;
  Object? signInError;
  int signInCalls = 0;
  final List<(String, int)> scores = <(String, int)>[];
  final List<String> achievements = <String>[];
  int leaderboardUiCalls = 0;
  final List<String> specificLeaderboardUiCalls = <String>[];
  int achievementUiCalls = 0;

  @override
  Future<bool> signIn() async {
    signInCalls += 1;
    if (signInError != null) throw signInError!;
    return signInResult;
  }

  @override
  Future<void> submitScore({required String leaderboardId, required int score}) async {
    scores.add((leaderboardId, score));
  }

  @override
  Future<void> unlockAchievement(String achievementId) async {
    achievements.add(achievementId);
  }

  @override
  Future<void> showLeaderboards() async => leaderboardUiCalls += 1;

  @override
  Future<void> showLeaderboard({required String leaderboardId}) async {
    specificLeaderboardUiCalls.add(leaderboardId);
  }

  @override
  Future<void> showAchievements() async => achievementUiCalls += 1;
}

void main() {
  const ids = PlayGamesIds(
    classicLeaderboardId: 'classic',
    comboRushLeaderboardId: 'rush',
    achievementIds: <String, String>{'first_game': 'ach-first'},
  );

  test('sign in success updates connection status', () async {
    final adapter = FakeGamesPlatformAdapter();
    final service = PlayGamesService(ids: ids, adapter: adapter);

    expect(await service.signIn(), isTrue);
    expect((await service.connectionInfo()).connected, isTrue);
  });

  test('sign in exception is contained and reported offline', () async {
    final adapter = FakeGamesPlatformAdapter()..signInError = StateError('offline');
    final service = PlayGamesService(ids: ids, adapter: adapter);

    expect(await service.signIn(), isFalse);
    expect((await service.connectionInfo()).connected, isFalse);
  });

  test('blank leaderboard id is skipped without platform call', () async {
    final adapter = FakeGamesPlatformAdapter();
    final service = PlayGamesService(ids: ids, adapter: adapter);

    await service.submitScore(leaderboardId: '', score: 1234);
    expect(adapter.scores, isEmpty);
  });

  test('configured score submits exact id and score', () async {
    final adapter = FakeGamesPlatformAdapter();
    final service = PlayGamesService(ids: ids, adapter: adapter);

    await service.submitScore(leaderboardId: 'classic', score: 4321);
    expect(adapter.scores, <(String, int)>[('classic', 4321)]);
  });

  test('blank achievement id is skipped and configured id unlocks once', () async {
    final adapter = FakeGamesPlatformAdapter();
    final service = PlayGamesService(ids: ids, adapter: adapter);

    await service.unlockAchievement(achievementId: '');
    await service.unlockAchievement(achievementId: 'ach-first');
    expect(adapter.achievements, <String>['ach-first']);
  });

  test('specific leaderboard opens exact tournament id', () async {
    final adapter = FakeGamesPlatformAdapter();
    final service = PlayGamesService(ids: ids, adapter: adapter);

    await service.showLeaderboard(leaderboardId: 'adventure');

    expect(adapter.specificLeaderboardUiCalls, <String>['adventure']);
  });

  test('leaderboard and achievement UI can sign in lazily without throwing', () async {
    final adapter = FakeGamesPlatformAdapter();
    final service = PlayGamesService(ids: ids, adapter: adapter);

    await service.showLeaderboards();
    await service.showAchievements();

    expect(adapter.signInCalls, 1);
    expect(adapter.leaderboardUiCalls, 1);
    expect(adapter.achievementUiCalls, 1);
  });
}
