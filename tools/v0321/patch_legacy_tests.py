from pathlib import Path
import sys
root=Path(sys.argv[1] if len(sys.argv)>1 else '/mnt/data/v0321_work/app')
def cut(s,a,b,r=''):
    x=s.index(a);y=s.index(b,x+len(a));return s[:x]+r+s[y:]
(root/'test/v021_experience_test.dart').unlink(missing_ok=True)
p=root/'test/v018_features_test.dart';s=p.read_text().replace("import 'package:elxvro_blocks/models/adventure_level.dart';\n",'')
p.write_text(cut(s,"  test('adventure contains 60 progressively harder levels', () {", "  test('daily challenge rules"))
p=root/'test/v020_experience_test.dart';s=p.read_text().replace("import 'package:elxvro_blocks/models/adventure_level.dart';\n",'')
p.write_text(cut(s,"  test('Falling Adventure gets progressively harder across 60 levels', () {", "  testWidgets('raindrop background"))
p=root/'test/v019_features_test.dart';s=p.read_text().replace("import 'package:elxvro_blocks/models/adventure_level.dart';\n",'')
replacement="""  test('retired Adventure themes use player levels and grandfather legacy unlocks', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final state = AppState();
    await state.load();
    for (final id in <String>['obsidian', 'polar_aurora', 'magma']) {
      expect(gameThemes.any((theme) => theme.id == id), isTrue);
      expect(state.isThemeUnlocked(id), isFalse);
    }
    SharedPreferences.setMockInitialValues(<String, Object>{
      'xp': AppState.xpForLevel(15),
    });
    final leveled = AppState();
    await leveled.load();
    expect(leveled.isThemeUnlocked('obsidian'), isTrue);
    expect(leveled.isThemeUnlocked('polar_aurora'), isFalse);
    SharedPreferences.setMockInitialValues(<String, Object>{
      'adventure_completed': List<String>.generate(15, (i) => '${i + 1}'),
    });
    final legacy = AppState();
    await legacy.load();
    expect(legacy.isThemeUnlocked('obsidian'), isTrue);
  });

"""
p.write_text(cut(s,"  test('new premium themes are present and adventure-gated', () async {", "  test('Falling Blocks best score",replacement))
p=root/'test/v0230_ten_languages_test.dart';s=p.read_text()
s=s.replace("import 'package:elxvro_blocks/models/adventure_level.dart';\n",'')
s=s.replace("        l.t('adventure.title'),\n",'')
s=s.replace("        adventureLevelFor(5).title,\n        adventureLevelFor(5).objective,\n",'')
p.write_text(s)
for p in (root/'test').glob('*.dart'):
    original=p.read_text()
    if 'version: 0.32.0+81' in original:
        p.write_text(original.replace('version: 0.32.0+81', 'version: 0.32.1+82'))

# Keep regression coverage aligned with the surviving non-Adventure modes.
# The arcade board now clamps its computed width to the available viewport
# instead of using the retired old sizing formula.
p = root / 'test/v022_language_gameplay_test.dart'
text = p.read_text()
if text.count("expect(falling, contains('constraints.maxWidth *'));") != 1:
    raise RuntimeError('Expected legacy Falling Blocks board sizing assertion')
text = text.replace(
    "expect(falling, contains('constraints.maxWidth *'));",
    "expect(falling, contains('constraints.maxWidth - 6'));",
    1,
)
p.write_text(text)

# The retired adventure_10 achievement reduces ranked achievements from 20
# to 19; existing claimed reward state stays in SharedPreferences.
p = root / 'test/v0280_merit_missions_test.dart'
text = p.read_text()
if text.count('expect(AppState.rankedAchievementIds.length, 20);') != 1:
    raise RuntimeError('Expected old ranked achievement count')
text = text.replace(
    'expect(AppState.rankedAchievementIds.length, 20);',
    "expect(AppState.rankedAchievementIds.length, 19);\n"
    "    expect(AppState.rankedAchievementIds, isNot(contains('adventure_10')));",
    1,
)
p.write_text(text)

print('Retired obsolete Adventure regression tests while retaining other game tests.')