class PlayGamesIds {
  const PlayGamesIds({
    required this.classicLeaderboardId,
    required this.comboRushLeaderboardId,
    required this.achievementIds,
  });

  const PlayGamesIds.fromEnvironment()
      : classicLeaderboardId = const String.fromEnvironment(
          'ELXVRO_PG_CLASSIC_LEADERBOARD_ID',
        ),
        comboRushLeaderboardId = const String.fromEnvironment(
          'ELXVRO_PG_COMBO_RUSH_LEADERBOARD_ID',
        ),
        achievementIds = const <String, String>{
          'first_game': String.fromEnvironment('ELXVRO_PG_ACH_FIRST_GAME'),
          'score_1000': String.fromEnvironment('ELXVRO_PG_ACH_SCORE_1000'),
          'combo_3': String.fromEnvironment('ELXVRO_PG_ACH_COMBO_3'),
          'lines_25': String.fromEnvironment('ELXVRO_PG_ACH_LINES_25'),
          'games_10': String.fromEnvironment('ELXVRO_PG_ACH_GAMES_10'),
          'blocks_250': String.fromEnvironment('ELXVRO_PG_ACH_BLOCKS_250'),
          'score_10000': String.fromEnvironment('ELXVRO_PG_ACH_SCORE_10000'),
          'level_5': String.fromEnvironment('ELXVRO_PG_ACH_LEVEL_5'),
          'perfect_3': String.fromEnvironment('ELXVRO_PG_ACH_PERFECT_3'),
          'level_15': String.fromEnvironment('ELXVRO_PG_ACH_LEVEL_15'),
        };

  final String classicLeaderboardId;
  final String comboRushLeaderboardId;
  final Map<String, String> achievementIds;

  String? achievementIdFor(String localId) {
    final value = achievementIds[localId]?.trim() ?? '';
    return value.isEmpty ? null : value;
  }

  bool get hasAnyRemoteConfiguration =>
      classicLeaderboardId.trim().isNotEmpty ||
      comboRushLeaderboardId.trim().isNotEmpty ||
      achievementIds.values.any((value) => value.trim().isNotEmpty);
}
