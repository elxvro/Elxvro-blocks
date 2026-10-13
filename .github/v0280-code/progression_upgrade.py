from pathlib import Path
import sys

root=Path(sys.argv[1])
def patch(name,old,new):
    p=root/name; s=p.read_text(encoding='utf-8')
    if s.count(old)!=1: raise RuntimeError(f'anchor {name}: {s.count(old)} - {old[:60]!r}')
    p.write_text(s.replace(old,new,1),encoding='utf-8')

patch('pubspec.yaml','version: 0.27.0+53','version: 0.28.0+54')
for name in ('test/real_material_audio_test.dart','test/v0240_features_test.dart'):
    patch(name,'version: 0.27.0+53','version: 0.28.0+54')
patch('lib/screens/home_screen.dart',"badge: 'v0.27.0'","badge: 'v0.28.0'")
patch('lib/screens/settings_screen.dart',"'v0.27.0  •  ","'v0.28.0  •  ")

s='lib/app_state.dart'
patch(s,"  static const String _dailyBestScoreKey = 'daily_best_score';",
"""  static const String _dailyBestScoreKey = 'daily_best_score';
  static const String _dailyComboKey = 'daily_combo_max_v028';
  static const String _dailyPerfectKey = 'daily_perfect_v028';
  static const String _dailyBlocksKey = 'daily_blocks_v028';
  static const String _dailyTotalScoreKey = 'daily_total_score_v028';""")
patch(s,'  int dailyBestScore = 0;',
"""  int dailyBestScore = 0;
  int dailyMaxCombo = 0;
  int dailyPerfectClears = 0;
  int dailyPlacedBlocks = 0;
  int dailyTotalScore = 0;""")
patch(s,"        dailyBestScore = prefs.getInt(_dailyBestScoreKey) ?? 0;",
"""        dailyBestScore = prefs.getInt(_dailyBestScoreKey) ?? 0;
        dailyMaxCombo = prefs.getInt(_dailyComboKey) ?? 0;
        dailyPerfectClears = prefs.getInt(_dailyPerfectKey) ?? 0;
        dailyPlacedBlocks = prefs.getInt(_dailyBlocksKey) ?? 0;
        dailyTotalScore = prefs.getInt(_dailyTotalScoreKey) ?? 0;""")
# Reset metrics both on cold start and midnight refresh.
text=(root/s).read_text(encoding='utf-8')
needle="""        dailyBestScore = 0;
        await _saveDaily(prefs, today);"""
assert text.count(needle)==2, text.count(needle)
text=text.replace(needle,"""        dailyBestScore = 0;
        dailyMaxCombo = 0;
        dailyPerfectClears = 0;
        dailyPlacedBlocks = 0;
        dailyTotalScore = 0;
        await _saveDaily(prefs, today);""")
(root/s).write_text(text,encoding='utf-8')
patch(s,
"""    dailyLines += clearedLines;
    if (score > dailyBestScore) {""",
"""    dailyLines += clearedLines;
    dailyMaxCombo = combo > dailyMaxCombo ? combo : dailyMaxCombo;
    dailyPerfectClears += perfectClearsThisGame;
    dailyPlacedBlocks += placedBlocks;
    dailyTotalScore += score;
    if (score > dailyBestScore) {""")
patch(s,'    await prefs.setInt(_dailyBestScoreKey, dailyBestScore);',
"""    await prefs.setInt(_dailyBestScoreKey, dailyBestScore);
    await prefs.setInt(_dailyComboKey, dailyMaxCombo);
    await prefs.setInt(_dailyPerfectKey, dailyPerfectClears);
    await prefs.setInt(_dailyBlocksKey, dailyPlacedBlocks);
    await prefs.setInt(_dailyTotalScoreKey, dailyTotalScore);""")
patch(s,
"""    if (dailyLines >= 20) completed += 1;
    return completed;""",
"""    if (dailyLines >= 20) completed += 1;
    if (dailyGames >= 6) completed += 1;
    if (dailyLines >= 45) completed += 1;
    if (dailyBestScore >= 12000) completed += 1;
    if (dailyMaxCombo >= 7) completed += 1;
    if (dailyPlacedBlocks >= 200) completed += 1;
    if (dailyPerfectClears >= 2) completed += 1;
    if (dailyTotalScore >= 40000) completed += 1;
    return completed;""")
start=(root/s).read_text(encoding='utf-8').index('  int get unlockedAchievements {')
end=(root/s).read_text(encoding='utf-8').index('  bool achievementUnlocked(String id) {',start)
p=root/s; content=p.read_text(encoding='utf-8')
content=content[:start]+"""  static const List<String> rankedAchievementIds = <String>[
    'first_game', 'score_1000', 'combo_3', 'lines_25', 'games_10',
    'blocks_250', 'score_10000', 'level_5', 'perfect_3', 'level_15',
    'combo_5', 'combo_8', 'lines_100', 'lines_500', 'blocks_1000',
    'games_100', 'score_25000', 'perfect_15', 'level_30', 'adventure_10',
  ];

  int get unlockedAchievements =>
      rankedAchievementIds.where(achievementUnlocked).length;

  int get achievementRating =>
      rankedAchievementIds.where(achievementUnlocked).length * 100 +
      (playerLevel * 10);

  String get achievementLeague {
    final points = achievementRating;
    if (points >= 1900) return 'EFSANE • LEGEND';
    if (points >= 1350) return 'ELMAS • DIAMOND';
    if (points >= 900) return 'PLATİN • PLATINUM';
    if (points >= 550) return 'ALTIN • GOLD';
    if (points >= 250) return 'GÜMÜŞ • SILVER';
    return 'BRONZ • BRONZE';
  }

"""+content[end:]
p.write_text(content,encoding='utf-8')
patch(s,
"""      case 'level_15':
        return playerLevel >= 15;
      default:""",
"""      case 'level_15':
        return playerLevel >= 15;
      case 'combo_5':
        return maxCombo >= 5;
      case 'combo_8':
        return maxCombo >= 8;
      case 'lines_100':
        return totalLines >= 100;
      case 'lines_500':
        return totalLines >= 500;
      case 'blocks_1000':
        return totalBlocks >= 1000;
      case 'games_100':
        return gamesPlayed >= 100;
      case 'score_25000':
        return bestScore >= 25000;
      case 'perfect_15':
        return perfectClears >= 15;
      case 'level_30':
        return playerLevel >= 30;
      case 'adventure_10':
        return adventureCompletedCount >= 10;
      default:""")
# Google Play remote new achievement IDs are optional, blank by default.
p=root/'lib/services/play_games_ids.dart'; a=p.read_text(encoding='utf-8')
anchor="          'level_15': String.fromEnvironment('ELXVRO_PG_ACH_LEVEL_15'),"
assert a.count(anchor)==1
add="\n".join("          '"+k+"': String.fromEnvironment('ELXVRO_PG_ACH_"+k.upper()+"')," for k in
 ('combo_5','combo_8','lines_100','lines_500','blocks_1000','games_100','score_25000','perfect_15','level_30','adventure_10'))
p.write_text(a.replace(anchor,anchor+"\n"+add),encoding='utf-8')
print("Ranked achievements, durable metrics and challenging daily progress added")
