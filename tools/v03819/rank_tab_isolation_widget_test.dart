import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:elxvro_blocks/app_state.dart';
import 'package:elxvro_blocks/services/mode_leaderboards.dart';
import 'package:elxvro_blocks/services/play_games_ids.dart';
import 'package:elxvro_blocks/services/play_games_service.dart';
import 'package:elxvro_blocks/widgets/three_game_rankings.dart';

class _Auth implements GamesPlatformAdapter {
  @override
  Future<bool> signIn() async => true;
  @override
  Future<void> submitScore({required String leaderboardId, required int score}) async {}
  @override
  Future<void> unlockAchievement(String achievementId) async {}
  @override
  Future<void> showLeaderboards() async {}
  @override
  Future<void> showLeaderboard({required String leaderboardId}) async {}
  @override
  Future<void> showAchievements() async {}
}

class _Records implements PlayerRecordsAdapter {
  @override
  Future<String?> playerName() async => 'cazador6116';
  @override
  Future<int?> personalBest(String leaderboardId) async => 0;
}

class _Scores implements OnlineScoresAdapter {
  final pending = <String, Completer<List<OnlineRankingEntry>?>>{};
  @override
  Future<List<OnlineRankingEntry>?> loadScores({
    required String leaderboardId, required RankingPeriod period,
  }) => pending.putIfAbsent(
    leaderboardId + ':' + period.name,
    () => Completer<List<OnlineRankingEntry>?>(),
  ).future;

  void complete(String id, String period, List<OnlineRankingEntry> rows) =>
      pending[id + ':' + period]!.complete(rows);
}

Future<void> _wait(WidgetTester tester, _Scores scores, String key) async {
  for (var i = 0; i < 20 && !scores.pending.containsKey(key); i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
  expect(scores.pending.containsKey(key), isTrue);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));
  const ids = PlayGamesIds(
    classicLeaderboardId: 'classic-id',
    comboRushLeaderboardId: '',
    fallingBlocksLeaderboardId: 'falling-id',
    worldAdventureLeaderboardId: 'adventure-id',
    achievementIds: <String, String>{},
  );

  testWidgets('each ranking tab hides the previous result while loading', (tester) async {
    final app = AppState();
    await app.load();
    final scores = _Scores();
    final service = PlayGamesService(ids: ids, adapter: _Auth(), scoresAdapter: scores, playerRecordsAdapter: _Records());
    await tester.pumpWidget(MaterialApp(home: Scaffold(body:
      SingleChildScrollView(child: ThreeGameRankings(appState: app, service: service)))));
    await _wait(tester, scores, 'classic-id:weekly');
    scores.complete('classic-id', 'weekly', const <OnlineRankingEntry>[
      OnlineRankingEntry(rank: 1, name: 'Old Classic User', displayScore: '3010', rawScore: 3010),
    ]);
    await tester.pump();
    await tester.pump();
    expect(find.text('Old Classic User'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('rank_tab_fallingBlocks')));
    await tester.pump();
    await _wait(tester, scores, 'falling-id:weekly');
    expect(find.text('Old Classic User'), findsNothing);
    scores.complete('falling-id', 'weekly', const <OnlineRankingEntry>[
      OnlineRankingEntry(rank: 1, name: 'Falling User', displayScore: '420', rawScore: 420),
    ]);
    await tester.pump();
    await tester.pump();
    expect(find.text('Falling User'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('rank_tab_worldAdventure')));
    await tester.pump();
    await _wait(tester, scores, 'adventure-id:weekly');
    expect(find.text('Falling User'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

}
