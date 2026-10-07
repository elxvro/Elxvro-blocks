#!/usr/bin/env python3
from pathlib import Path
import sys

ROOT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path('.')


def read(rel: str) -> str:
    return (ROOT / rel).read_text(encoding='utf-8')


def write(rel: str, text: str) -> None:
    (ROOT / rel).write_text(text, encoding='utf-8')


def replace_once(rel: str, old: str, new: str) -> None:
    text = read(rel)
    count = text.count(old)
    if count != 1:
        raise SystemExit(
            f'v0.18.1 tournament anchor mismatch: {rel}: expected 1, found {count}: {old[:100]!r}'
        )
    write(rel, text.replace(old, new, 1))


def replace_block(rel: str, start: str, end: str, new_block: str) -> None:
    text = read(rel)
    if text.count(start) != 1:
        raise SystemExit(f'v0.18.1 tournament start mismatch: {rel}: {start!r}')
    start_i = text.index(start)
    end_i = text.find(end, start_i + len(start))
    if end_i < 0:
        raise SystemExit(f'v0.18.1 tournament end missing: {rel}: {end!r}')
    write(rel, text[:start_i] + new_block + text[end_i:])


# ---------------------------------------------------------------------------
# Adventure tournament progression: best scores, stars and tournament points.
# ---------------------------------------------------------------------------
replace_once(
    'lib/app_state.dart',
    "import 'package:shared_preferences/shared_preferences.dart';\n",
    "import 'package:shared_preferences/shared_preferences.dart';\n\n"
    "import 'models/adventure_level.dart';\n",
)

replace_once(
    'lib/app_state.dart',
    "  static const String _adventureCompletedKey = 'adventure_completed';\n",
    "  static const String _adventureCompletedKey = 'adventure_completed';\n"
    "  static const String _adventureBestScoresKey = 'adventure_best_scores';\n",
)

replace_once(
    'lib/app_state.dart',
    "  final Set<int> _adventureCompleted = <int>{};\n",
    "  final Set<int> _adventureCompleted = <int>{};\n"
    "  final Map<int, int> _adventureBestScores = <int, int>{};\n",
)

replace_once(
    'lib/app_state.dart',
    "      final savedAdventureLevel =\n"
    "          (prefs.getInt(_adventureUnlockedLevelKey) ?? 1).clamp(1, 60).toInt();\n",
    "      _adventureBestScores.clear();\n"
    "      for (final raw in\n"
    "          prefs.getStringList(_adventureBestScoresKey) ?? const <String>[]) {\n"
    "        final parts = raw.split(':');\n"
    "        if (parts.length != 2) continue;\n"
    "        final level = int.tryParse(parts[0]);\n"
    "        final score = int.tryParse(parts[1]);\n"
    "        if (level == null || score == null || level < 1 || level > 60) {\n"
    "          continue;\n"
    "        }\n"
    "        _adventureBestScores[level] = score < 0 ? 0 : score;\n"
    "      }\n"
    "      final savedAdventureLevel =\n"
    "          (prefs.getInt(_adventureUnlockedLevelKey) ?? 1).clamp(1, 60).toInt();\n",
)

replace_block(
    'lib/app_state.dart',
    "  int get adventureCompletedCount => _adventureCompleted.length;\n",
    "  Future<void> recordComboRushResult({\n",
    "  int get adventureCompletedCount => _adventureCompleted.length;\n\n"
    "  double get adventureProgress =>\n"
    "      (adventureCompletedCount / 60).clamp(0.0, 1.0).toDouble();\n\n"
    "  bool isAdventureLevelUnlocked(int level) =>\n"
    "      level >= 1 && level <= adventureUnlockedLevel;\n\n"
    "  bool isAdventureLevelCompleted(int level) =>\n"
    "      _adventureCompleted.contains(level);\n\n"
    "  int adventureBestScoreForLevel(int level) =>\n"
    "      _adventureBestScores[level] ?? 0;\n\n"
    "  int adventureStarsForLevel(int level) {\n"
    "    if (!_adventureCompleted.contains(level)) return 0;\n"
    "    final target = adventureLevelFor(level).targetScore;\n"
    "    final score = adventureBestScoreForLevel(level);\n"
    "    if (score >= (target * 1.5).round()) return 3;\n"
    "    if (score >= (target * 1.2).round()) return 2;\n"
    "    return 1;\n"
    "  }\n\n"
    "  int get adventureTotalStars {\n"
    "    var total = 0;\n"
    "    for (final level in _adventureCompleted) {\n"
    "      total += adventureStarsForLevel(level);\n"
    "    }\n"
    "    return total;\n"
    "  }\n\n"
    "  int get adventureTournamentScore =>\n"
    "      adventureCompletedCount * 1000 + adventureTotalStars;\n\n"
    "  Future<int> completeAdventureLevel({\n"
    "    required int level,\n"
    "    required int reward,\n"
    "    required int score,\n"
    "  }) async {\n"
    "    if (level < 1 || level > 60) {\n"
    "      return 0;\n"
    "    }\n\n"
    "    final firstCompletion = _adventureCompleted.add(level);\n"
    "    final currentBest = _adventureBestScores[level] ?? 0;\n"
    "    if (score > currentBest) {\n"
    "      _adventureBestScores[level] = score;\n"
    "    }\n"
    "    if (level >= adventureUnlockedLevel && adventureUnlockedLevel < 60) {\n"
    "      adventureUnlockedLevel = level + 1;\n"
    "    }\n\n"
    "    final earned = firstCompletion ? reward : 0;\n"
    "    if (earned > 0) {\n"
    "      coins += earned;\n"
    "    }\n"
    "    notifyListeners();\n\n"
    "    try {\n"
    "      final prefs = await SharedPreferences.getInstance();\n"
    "      final completed = _adventureCompleted.toList()..sort();\n"
    "      final scoreLevels = _adventureBestScores.keys.toList()..sort();\n"
    "      await prefs.setInt(_adventureUnlockedLevelKey, adventureUnlockedLevel);\n"
    "      await prefs.setStringList(\n"
    "        _adventureCompletedKey,\n"
    "        completed.map((level) => '$level').toList(growable: false),\n"
    "      );\n"
    "      await prefs.setStringList(\n"
    "        _adventureBestScoresKey,\n"
    "        scoreLevels\n"
    "            .map((level) => '$level:${_adventureBestScores[level] ?? 0}')\n"
    "            .toList(growable: false),\n"
    "      );\n"
    "      if (earned > 0) {\n"
    "        await prefs.setInt(_coinsKey, coins);\n"
    "      }\n"
    "    } catch (error) {\n"
    "      debugPrint('ELXVRO adventure tournament save failed: $error');\n"
    "    }\n\n"
    "    return earned;\n"
    "  }\n\n",
)

# ---------------------------------------------------------------------------
# Dedicated Play Games leaderboard ID for Adventure Tournament.
# ---------------------------------------------------------------------------
replace_once(
    'lib/services/play_games_ids.dart',
    "    required this.comboRushLeaderboardId,\n"
    "    required this.achievementIds,\n",
    "    required this.comboRushLeaderboardId,\n"
    "    this.adventureLeaderboardId = '',\n"
    "    required this.achievementIds,\n",
)

replace_once(
    'lib/services/play_games_ids.dart',
    "        comboRushLeaderboardId = const String.fromEnvironment(\n"
    "          'ELXVRO_PG_COMBO_RUSH_LEADERBOARD_ID',\n"
    "          defaultValue: 'CgkI6arsvtAGEAIQAg',\n"
    "        ),\n"
    "        achievementIds = const <String, String>{\n",
    "        comboRushLeaderboardId = const String.fromEnvironment(\n"
    "          'ELXVRO_PG_COMBO_RUSH_LEADERBOARD_ID',\n"
    "          defaultValue: 'CgkI6arsvtAGEAIQAg',\n"
    "        ),\n"
    "        adventureLeaderboardId = const String.fromEnvironment(\n"
    "          'ELXVRO_PG_ADVENTURE_LEADERBOARD_ID',\n"
    "          defaultValue: 'CgkI6arsvtAGEAIQBA',\n"
    "        ),\n"
    "        achievementIds = const <String, String>{\n",
)

replace_once(
    'lib/services/play_games_ids.dart',
    "  final String comboRushLeaderboardId;\n"
    "  final Map<String, String> achievementIds;\n",
    "  final String comboRushLeaderboardId;\n"
    "  final String adventureLeaderboardId;\n"
    "  final Map<String, String> achievementIds;\n",
)

replace_once(
    'lib/services/play_games_ids.dart',
    "      comboRushLeaderboardId.trim().isNotEmpty ||\n"
    "      achievementIds.values.any((value) => value.trim().isNotEmpty);\n",
    "      comboRushLeaderboardId.trim().isNotEmpty ||\n"
    "      adventureLeaderboardId.trim().isNotEmpty ||\n"
    "      achievementIds.values.any((value) => value.trim().isNotEmpty);\n",
)

# ---------------------------------------------------------------------------
# Open the dedicated Adventure Tournament leaderboard directly.
# ---------------------------------------------------------------------------
replace_once(
    'lib/services/play_games_service.dart',
    "  Future<void> showLeaderboards();\n\n"
    "  Future<void> showAchievements();\n",
    "  Future<void> showLeaderboards();\n\n"
    "  Future<void> showLeaderboard({required String leaderboardId});\n\n"
    "  Future<void> showAchievements();\n",
)

replace_once(
    'lib/services/play_games_service.dart',
    "  @override\n"
    "  Future<void> showAchievements() async {\n"
    "    await GamesServices.showAchievements();\n"
    "  }\n",
    "  @override\n"
    "  Future<void> showLeaderboard({required String leaderboardId}) async {\n"
    "    await GamesServices.showLeaderboards(\n"
    "      androidLeaderboardID: leaderboardId,\n"
    "    );\n"
    "  }\n\n"
    "  @override\n"
    "  Future<void> showAchievements() async {\n"
    "    await GamesServices.showAchievements();\n"
    "  }\n",
)

replace_once(
    'lib/services/play_games_service.dart',
    "  @override\n"
    "  Future<void> showAchievements() async {\n"
    "    try {\n"
    "      if (!await _ensureConnected()) return;\n"
    "      await _adapter.showAchievements();\n",
    "  Future<void> showLeaderboard({required String leaderboardId}) async {\n"
    "    final id = leaderboardId.trim();\n"
    "    if (id.isEmpty) return;\n"
    "    try {\n"
    "      if (!await _ensureConnected()) return;\n"
    "      await _adapter.showLeaderboard(leaderboardId: id);\n"
    "    } catch (error, stackTrace) {\n"
    "      _lastError = error.toString();\n"
    "      debugPrint('ELXVRO Play Games tournament UI failed: $error');\n"
    "      debugPrintStack(stackTrace: stackTrace);\n"
    "    }\n"
    "  }\n\n"
    "  @override\n"
    "  Future<void> showAchievements() async {\n"
    "    try {\n"
    "      if (!await _ensureConnected()) return;\n"
    "      await _adapter.showAchievements();\n",
)

# ---------------------------------------------------------------------------
# Submit Adventure Tournament score after successful adventure completion.
# ---------------------------------------------------------------------------
replace_once(
    'lib/screens/game_screen.dart',
    "                level: adventure.number,\n"
    "                reward: adventure.reward,\n"
    "              )\n",
    "                level: adventure.number,\n"
    "                reward: adventure.reward,\n"
    "                score: _score,\n"
    "              )\n",
)

replace_once(
    'lib/screens/game_screen.dart',
    "    if (adventure == null) {\n"
    "      await _syncPlayGamesAfterRound();\n"
    "    }\n",
    "    if (adventure == null) {\n"
    "      await _syncPlayGamesAfterRound();\n"
    "    } else if (success) {\n"
    "      await _syncAdventureTournament();\n"
    "    }\n",
)

replace_once(
    'lib/screens/game_screen.dart',
    "  Future<void> _syncPlayGamesAfterRound() async {\n",
    "  Future<void> _syncAdventureTournament() async {\n"
    "    const ids = PlayGamesIds.fromEnvironment();\n"
    "    final leaderboardId = ids.adventureLeaderboardId.trim();\n"
    "    if (leaderboardId.isEmpty) return;\n"
    "    final service = PlayGamesService(ids: ids);\n"
    "    await service.submitScore(\n"
    "      leaderboardId: leaderboardId,\n"
    "      score: widget.appState.adventureTournamentScore,\n"
    "    );\n"
    "  }\n\n"
    "  Future<void> _syncPlayGamesAfterRound() async {\n",
)

# ---------------------------------------------------------------------------
# Dedicated tournament section in Leadership Center.
# ---------------------------------------------------------------------------
replace_once(
    'lib/screens/social_hub_screen.dart',
    "                        _WeeklyCard(appState: appState),\n"
    "                        const SizedBox(height: 18),\n"
    "                        const _SectionTitle('GOOGLE PLAY GAMES'),\n",
    "                        _WeeklyCard(appState: appState),\n"
    "                        const SizedBox(height: 18),\n"
    "                        const _SectionTitle('MACERA TURNUVASI'),\n"
    "                        const SizedBox(height: 10),\n"
    "                        _AdventureTournamentCard(appState: appState),\n"
    "                        const SizedBox(height: 18),\n"
    "                        const _SectionTitle('GOOGLE PLAY GAMES'),\n",
)

replace_once(
    'lib/screens/social_hub_screen.dart',
    "class _ConnectionCard extends StatelessWidget {\n",
    "class _AdventureTournamentCard extends StatelessWidget {\n"
    "  const _AdventureTournamentCard({required this.appState});\n\n"
    "  final AppState appState;\n\n"
    "  Future<void> _openRanking(BuildContext context) async {\n"
    "    final service = PlayGamesService.production();\n"
    "    final leaderboardId = service.ids.adventureLeaderboardId.trim();\n"
    "    if (leaderboardId.isEmpty) {\n"
    "      ScaffoldMessenger.of(context).showSnackBar(\n"
    "        const SnackBar(\n"
    "          content: Text('Macera Turnuvası Play Games kimliği henüz eklenmedi.'),\n"
    "        ),\n"
    "      );\n"
    "      return;\n"
    "    }\n"
    "    await service.submitScore(\n"
    "      leaderboardId: leaderboardId,\n"
    "      score: appState.adventureTournamentScore,\n"
    "    );\n"
    "    if (!context.mounted) return;\n"
    "    await service.showLeaderboard(leaderboardId: leaderboardId);\n"
    "  }\n\n"
    "  @override\n"
    "  Widget build(BuildContext context) {\n"
    "    final service = PlayGamesService.production();\n"
    "    final online = service.ids.adventureLeaderboardId.trim().isNotEmpty;\n"
    "    return Container(\n"
    "      padding: const EdgeInsets.all(18),\n"
    "      decoration: BoxDecoration(\n"
    "        borderRadius: BorderRadius.circular(24),\n"
    "        gradient: LinearGradient(\n"
    "          colors: <Color>[\n"
    "            const Color(0xFFFFC86E).withValues(alpha: 0.13),\n"
    "            const Color(0xFF0B3840).withValues(alpha: 0.50),\n"
    "          ],\n"
    "        ),\n"
    "        border: Border.all(\n"
    "          color: const Color(0xFFFFD98B).withValues(alpha: 0.28),\n"
    "        ),\n"
    "      ),\n"
    "      child: Column(\n"
    "        crossAxisAlignment: CrossAxisAlignment.start,\n"
    "        children: <Widget>[\n"
    "          Row(\n"
    "            children: <Widget>[\n"
    "              Container(\n"
    "                width: 46,\n"
    "                height: 46,\n"
    "                decoration: BoxDecoration(\n"
    "                  shape: BoxShape.circle,\n"
    "                  color: const Color(0xFFFFC86E).withValues(alpha: 0.12),\n"
    "                  border: Border.all(\n"
    "                    color: const Color(0xFFFFD98B).withValues(alpha: 0.28),\n"
    "                  ),\n"
    "                ),\n"
    "                child: const Icon(\n"
    "                  Icons.emoji_events_rounded,\n"
    "                  color: Color(0xFFFFD98B),\n"
    "                ),\n"
    "              ),\n"
    "              const SizedBox(width: 12),\n"
    "              const Expanded(\n"
    "                child: Column(\n"
    "                  crossAxisAlignment: CrossAxisAlignment.start,\n"
    "                  children: <Widget>[\n"
    "                    Text(\n"
    "                      'GLOBAL MACERA TURNUVASI',\n"
    "                      style: TextStyle(\n"
    "                        color: Colors.white,\n"
    "                        fontWeight: FontWeight.w900,\n"
    "                        letterSpacing: 0.8,\n"
    "                      ),\n"
    "                    ),\n"
    "                    SizedBox(height: 3),\n"
    "                    Text(\n"
    "                      'Bölüm ilerlemesi + yıldız performansı',\n"
    "                      style: TextStyle(color: Colors.white54, fontSize: 10),\n"
    "                    ),\n"
    "                  ],\n"
    "                ),\n"
    "              ),\n"
    "              Container(\n"
    "                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),\n"
    "                decoration: BoxDecoration(\n"
    "                  borderRadius: BorderRadius.circular(999),\n"
    "                  color: const Color(0xFFFFC86E).withValues(alpha: 0.10),\n"
    "                ),\n"
    "                child: Text(\n"
    "                  online ? 'GLOBAL' : 'YEREL',\n"
    "                  style: const TextStyle(\n"
    "                    color: Color(0xFFFFD98B),\n"
    "                    fontSize: 8,\n"
    "                    fontWeight: FontWeight.w900,\n"
    "                  ),\n"
    "                ),\n"
    "              ),\n"
    "            ],\n"
    "          ),\n"
    "          const SizedBox(height: 15),\n"
    "          Row(\n"
    "            children: <Widget>[\n"
    "              Expanded(\n"
    "                child: _MiniStat(\n"
    "                  label: 'BÖLÜM',\n"
    "                  value: '${appState.adventureCompletedCount}/60',\n"
    "                ),\n"
    "              ),\n"
    "              const SizedBox(width: 8),\n"
    "              Expanded(\n"
    "                child: _MiniStat(\n"
    "                  label: 'YILDIZ',\n"
    "                  value: '${appState.adventureTotalStars}/180',\n"
    "                ),\n"
    "              ),\n"
    "              const SizedBox(width: 8),\n"
    "              Expanded(\n"
    "                child: _MiniStat(\n"
    "                  label: 'TURNUVA',\n"
    "                  value: '${appState.adventureTournamentScore}',\n"
    "                ),\n"
    "              ),\n"
    "            ],\n"
    "          ),\n"
    "          const SizedBox(height: 13),\n"
    "          Text(\n"
    "            'Her tamamlanan bölüm 1000 turnuva puanı verir. 2 ve 3 yıldız daha iyi skorla kazanılır.',\n"
    "            style: TextStyle(\n"
    "              color: Colors.white.withValues(alpha: 0.48),\n"
    "              fontSize: 9,\n"
    "              height: 1.4,\n"
    "            ),\n"
    "          ),\n"
    "          const SizedBox(height: 13),\n"
    "          SizedBox(\n"
    "            width: double.infinity,\n"
    "            child: FilledButton.icon(\n"
    "              onPressed: () => _openRanking(context),\n"
    "              icon: Icon(online ? Icons.leaderboard_rounded : Icons.lock_clock_rounded),\n"
    "              label: Text(online ? 'GLOBAL SIRALAMAYI AÇ' : 'PLAY GAMES ID BEKLİYOR'),\n"
    "              style: FilledButton.styleFrom(\n"
    "                backgroundColor: const Color(0xFFC7863C),\n"
    "                foregroundColor: const Color(0xFF160D06),\n"
    "                padding: const EdgeInsets.symmetric(vertical: 13),\n"
    "              ),\n"
    "            ),\n"
    "          ),\n"
    "        ],\n"
    "      ),\n"
    "    );\n"
    "  }\n"
    "}\n\n"
    "class _ConnectionCard extends StatelessWidget {\n",
)

print('ELXVRO Blocks v0.18.1 Adventure Tournament patch applied successfully.')
