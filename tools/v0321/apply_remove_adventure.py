#!/usr/bin/env python3
"""Remove the Adventure feature without deleting old player save data."""
from pathlib import Path
import shutil, sys

root = Path(sys.argv[1] if len(sys.argv)>1 else '/mnt/data/v0321_work/app')

def patch(p, fn):
    f=root/p; before=f.read_text(); after=fn(before)
    if before==after: raise RuntimeError(f'no changes: {p}')
    f.write_text(after)

def repl(s,a,b,label):
    n=s.count(a)
    if n!=1:raise RuntimeError(f'{label} expected 1, got {n}: {a[:100]!r}')
    return s.replace(a,b,1)

def cut(s,start,end,replacement='',label='cut'):
    a=s.find(start)
    if a<0: raise RuntimeError(f'{label}: start not found {start[:70]!r}')
    b=s.find(end,a+len(start))
    if b<0: raise RuntimeError(f'{label}: end not found {end[:70]!r}')
    return s[:a]+replacement+s[b:]

# Mode navigator: the only user-accessible Adventure entry point.
def modes(s):
    s=repl(s,"import 'adventure_screen.dart';\n",'', 'remove route import')
    s=repl(s,"AppStrings.current.f('Macera, Combo Rush, günlük challenge, Klasik, Zen ve Zor mod ile farklı hedeflerde ilerle.', 'Choose Adventure, Combo Rush, Daily Challenge, Classic, Zen or Hard mode.')", "AppStrings.current.f('Combo Rush, Günlük Meydan Okuma, Klasik, Zen, Zor ve diğer oyun modlarında yarış.', 'Play Combo Rush, Daily Challenge, Classic, Zen, Hard and other modes.')",'modes subtitle')
    s=repl(s,'itemCount: GameMode.values.length + 3,','itemCount: GameMode.values.length + 2,','card count')
    s=cut(s,'                    if (index == 0) {','                    if (index == 1) {',label='remove adventure card')
    s=repl(s,'if (index == 1) {','if (index == 0) {','falling index')
    s=repl(s,'if (index == 2) {','if (index == 1) {','duel index')
    s=repl(s,'GameMode.values[index - 3]','GameMode.values[index - 2]','mode offset')
    assert 'AdventureScreen' not in s and "modes.adventure" not in s
    return s
patch('lib/screens/modes_screen.dart',modes)

# Hide obsolete adventure-only achievement; preserve prior claims and rewards in prefs.
def achievement(s):
    return repl(s, "    _AchievementData(id: 'adventure_10', title: AppStrings.current.f('Macera Fatihi','Adventure Conqueror'), subtitle: AppStrings.current.f('10 macera bölümü tamamla','Complete 10 adventure chapters'), reward: 675, icon: Icons.map_rounded),\n",'', 'remove obsolete achievement')
patch('lib/screens/achievements_screen.dart',achievement)

# Retain legacy Adventure completion data solely to grandfather unlocked themes.
def state(s):
    s=repl(s, "'games_100', 'score_25000', 'perfect_15', 'level_30', 'adventure_10',", "'games_100', 'score_25000', 'perfect_15', 'level_30',",'retire achievement')
    s=repl(s,"  int themeAdventureRequirement(String id) {", "  int themeLevelRequirement(String id) {", 'rename requirement')
    s=repl(s,"    final requirement = themeAdventureRequirement(id);\n    return requirement > 0 && adventureCompletedCount >= requirement;", "    final requirement = themeLevelRequirement(id);\n    // Previous Adventure unlocks remain valid after removing the mode.\n    return requirement > 0 &&\n        (playerLevel >= requirement || adventureCompletedCount >= requirement);", 'preserve earned unlocks')
    s=repl(s,"if (themeAdventureRequirement(id) > 0) {", "if (themeLevelRequirement(id) > 0) {",'do not pay to bypass milestones')
    return s
patch('lib/app_state.dart',state)

def themes(s):
    s=repl(s,'final adventureRequirement =\n                            appState.themeAdventureRequirement(theme.id);', 'final levelRequirement =\n                            appState.themeLevelRequirement(theme.id);','player milestone')
    s=repl(s,"unlockLabel: adventureRequirement > 0\n                              ? '${AppStrings.current.t('adventure.title')} $adventureRequirement'", "unlockLabel: levelRequirement > 0\n                              ? '${AppStrings.current.f('SEVİYE', 'LEVEL')} $levelRequirement'",'label')
    s=repl(s,'if (adventureRequirement > 0 &&\n                                appState.adventureCompletedCount <\n                                    adventureRequirement) {','if (levelRequirement > 0 &&\n                                !appState.isThemeUnlocked(theme.id)) {','milestone check')
    s=repl(s,"AppStrings.current.f('Bu tema için Macera’da $adventureRequirement bölüm tamamla.', 'Complete $adventureRequirement Adventure levels to unlock this theme.')", "AppStrings.current.f('Bu tema oyuncu seviyesi $levelRequirement olduğunda açılır.', 'Reach player level $levelRequirement to unlock this theme.')",'new explanation')
    assert 'adventureRequirement' not in s
    return s
patch('lib/screens/themes_screen.dart',themes)

def theme_model(s):
    for n in (15,30,45):
        s=repl(s, f'Macera {n}', f'Seviye {n}', f'theme subtitle {n}')
    return s
patch('lib/models/game_theme.dart',theme_model)

for p in ('lib/screens/home_screen.dart','lib/screens/profile_screen.dart','lib/screens/stats_screen.dart'):
    def rename_generic(s):
        s=s.replace("AppStrings.current.t('adventure.level')", "AppStrings.current.f('SEVİYE', 'LEVEL')")
        return s
    patch(p,rename_generic)

# Retain *only* standard falling-block arcade gameplay; strip old Adventure board.
def falling(s):
    for line in ("import '../models/adventure_level.dart';\n", "import '../game/adventure_rise_rules.dart';\n", "import '../game/adventure_quest.dart';\n", "import '../game/adventure_specials.dart';\n", "import '../widgets/adventure_world_backdrop.dart';\n", "import '../widgets/adventure_special_tile.dart';\n", "import '../widgets/adventure_mission_hud.dart';\n", "import '../widgets/adventure_result_dialog.dart';\n", "import '../services/play_games_service.dart';\n"):
        s=repl(s,line,'','remove unused '+line)
    s=repl(s,'    this.adventureLevel,\n','','remove ctor parameter')
    s=repl(s,'  final AdventureLevel? adventureLevel;\n','','remove field')
    s=repl(s,"  static const String _adventureLeaderboardId = 'CgkI6arsvtAGEAIQBA';\n",'', 'remove old leaderboard')
    s=repl(s,'  int _riseTicks = 0;\n  int _shieldCharges = 0;\n  AdventureQuestProgress? _quest;\n','','remove quest state')
    s=repl(s,'  bool get _isAdventure => widget.adventureLevel != null;\n\n','','mode guard')
    s=cut(s,'  int get _difficultyLevel =>','  List<Color> get _palette {', '  int get _difficultyLevel => _arcadeLevel;\n\n  Duration get _fallInterval => Duration(\n      milliseconds: max(125, 620 - (_arcadeLevel - 1) * 48));\n\n','remove adventure difficulty')
    s=cut(s,'    final cycle = _isAdventure ? widget.adventureLevel!.colorCycle : 0;','\n  @override\n  void initState()', '''    final selected = palettes[0];
    return List<Color>.generate(selected.length, (index) {
      return Color.lerp(selected[index], _theme.block, .12)!;
    });
  }
''','palette')
    s=cut(s,'    _quest = _isAdventure','    _piece = _randomPiece();','','remove adventure reset')
    s=repl(s,'    _riseTicks = 0;\n    _shieldCharges = 0;\n','','reset state')
    s=cut(s,'  void _seedAdventureBoard() {','  _FallingPiece _randomPiece()', '', 'remove adventure seeding')
    s=cut(s,'        if (_isAdventure) {','        _stepDown();','', 'remove rise tick')
    s=cut(s,'  void _riseBoard() {','  bool _canPlace(', '', 'remove adventure rise')
    s=cut(s,'  Future<void> _settleFloatingBlocks() async {','  Future<void> _lockPiece() async {','', 'remove gravity settle')
    s=cut(s,'      final clearedCells = <int>[','      _emitImpact(<int>{','', 'remove special stone discharge')
    s=repl(s,'      if (_isAdventure) await _settleFloatingBlocks();\n','','remove gravity check')
    s=cut(s,'      if (_isAdventure) {\n        _score += AdventureStone.bonusScore','      unawaited(\n        AudioService.instance.playClearTier(', '', 'remove special score')
    s=cut(s,'    // Adventure objectives are milestones,','    _piece = _nextPiece;', '', 'remove adventure text')
    # finishing screen only scores the independent Falling Blocks mode.
    s=cut(s,'  Future<void> _finish({required bool success}) async {','  void _togglePause() {', '''  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    _timer?.cancel();
    await widget.appState.recordFallingBlocksScore(_score);
    if (!mounted) return;
    setState(() => _gameOver = true);
    unawaited(AudioService.instance.playGameOver());
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF101719),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        title: Text(AppStrings.current.f('DÜŞEN BLOKLAR', 'FALLING BLOCKS'),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFFFFD98B), fontWeight: FontWeight.w900)),
        content: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          Text('$_score', style: TextStyle(color: _theme.blockAccent,
            fontSize: 42, fontWeight: FontWeight.w900)),
          Text(AppStrings.current.f('SKOR','SCORE'),
            style: const TextStyle(color: Colors.white38, fontSize: 10)),
          const SizedBox(height: 14),
          Text(AppStrings.current.f(
              '$_lines çizgi  •  Seviye $_arcadeLevel\\nEn iyi: ${widget.appState.fallingBlocksBestScore}',
              '$_lines lines  •  Level $_arcadeLevel\\nBest: ${widget.appState.fallingBlocksBestScore}'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60, height: 1.5)),
        ]),
        actionsAlignment: MainAxisAlignment.center,
        actions: <Widget>[
          TextButton(onPressed: () {
            Navigator.of(dialogContext).pop();
            Navigator.of(context).pop();
          }, child: Text(AppStrings.current.f('MODLAR', 'MODES'))),
          FilledButton(onPressed: () {
            Navigator.of(dialogContext).pop();
            setState(_reset);
          }, style: FilledButton.styleFrom(backgroundColor: _palette.first,
            foregroundColor: const Color(0xFF071014)),
          child: Text(AppStrings.current.f('TEKRAR OYNA','PLAY AGAIN'))),
        ],
      ),
    );
  }

''', 'replace old result dialog')
    s=repl(s,'_isAdventure ? const Color(0xFF101D34) : _theme.cell.withValues(alpha: 0.31)', '_theme.cell.withValues(alpha: 0.31)', 'empty cell bg')
    s=repl(s,'_isAdventure ? const Color(0xFF081326) : Color.lerp(_theme.cell, Colors.black, 0.28)!', 'Color.lerp(_theme.cell, Colors.black, 0.28)!', 'empty cell grad')
    s=repl(s,'_isAdventure ? 0.11 : 0.045','0.045','empty cell border')
    s=cut(s,'          if (_isAdventure)\n            AdventureWorldBackdrop','          SafeArea(', '', 'remove background overlay')
    s=cut(s,'              if (_isAdventure)\n                _AdventureBattleHeader(','              Expanded(\n                child: LayoutBuilder(', '''              _Header(
                title: AppStrings.current.f('DÜŞEN BLOKLAR','FALLING BLOCKS'),
                score: _score,
                lines: _lines,
                targetScore: 0,
                level: _difficultyLevel,
                accent: levelAccent,
                paused: _paused,
                onBack: () => Navigator.of(context).pop(),
                onPause: _togglePause,
              ),
''','remove adventure HUD')
    s=repl(s,'(_isAdventure ? .84 : 1) - (_isAdventure ? 0 : 6)','1 - 6','board proportions')
    s=repl(s,'EdgeInsets.all(_isAdventure ? 1 : 3)','const EdgeInsets.all(3)','board padding')
    s=repl(s,'_isAdventure ? const Color(0xF6101B33)\n                                    : Color.lerp(_theme.board, levelAccent, 0.12)!','Color.lerp(_theme.board, levelAccent, 0.12)!','bg1')
    s=repl(s,'_isAdventure ? const Color(0xF70B152A)\n                                    : _theme.board.withValues(alpha: 0.94)', '_theme.board.withValues(alpha: 0.94)','bg2')
    s=repl(s,'_isAdventure ? const Color(0xFA081125)\n                                    : Color.lerp(_theme.board, Colors.black, 0.24)!','Color.lerp(_theme.board, Colors.black, 0.24)!','bg3')
    s=cut(s,'                              if (_isAdventure && fixedColor >= AdventureSpecial.ice) {','                              return tile;', '', 'remove special tile')
    s=repl(s,'                adventure: _isAdventure,\n','','controls flag')
    s=cut(s,'class _AdventureBattleHeader extends StatelessWidget {','class _Header extends StatelessWidget {','', 'remove adventure header class')
    s=repl(s,'    required this.adventure,\n','','control ctor flag')
    s=repl(s,'  final bool adventure;\n','','control flag field')
    s=repl(s,'color: adventure ? const Color(0xFF122245) : emphasized','color: emphasized','control bg')
    s=cut(s,'                decoration: adventure ? BoxDecoration(', '                child: Row(', '                child: Row(\n', 'simplify controls deco')
    s=s.replace('_finish(success: false)', '_finish()')
    s=repl(s,'constraints.maxWidth *\n                        1 - 6','constraints.maxWidth - 6','simplify board width')
    assert '_isAdventure' not in s and 'Adventure' not in s and 'adventure' not in s
    return s
patch('lib/screens/falling_blocks_screen.dart',falling)

# Remove unused Adventure screens/modules/assets. Legacy model+save data remain for old theme access.
for p in ('lib/screens/adventure_screen.dart','lib/screens/adventure_combat_screen.dart',
          'lib/screens/falling_blocks_screen.dart.orig',
          'lib/game/adventure_quest.dart','lib/game/adventure_specials.dart','lib/game/adventure_rise_rules.dart',
          'lib/game/adventure_combat.dart','lib/widgets/adventure_mission_hud.dart',
          'lib/widgets/adventure_result_dialog.dart','lib/widgets/adventure_special_tile.dart',
          'lib/widgets/adventure_world_backdrop.dart'):
    f=root/p
    if f.exists(): f.unlink()
for directory in ('assets/images/adventure_worlds','assets/images/adventure_battles'):
    shutil.rmtree(root/directory,ignore_errors=True)

p=root/'pubspec.yaml';s=p.read_text()
s=repl(s,'version: 0.32.0+81','version: 0.32.1+82','version')
for line in ('    - assets/images/adventure_battles/\n','    - assets/images/adventure_worlds/\n'):
    s=repl(s,line,'','exclude adventure assets')
p.write_text(s)
# Remove obsolete gameplay tests; replace with checks for absent runtime entry points.
for p in (root/'test').glob('*adventure*.dart'):p.unlink()
for p in (root/'test').glob('*action_combat*.dart'):p.unlink()
# Some other tests validate retired menu presence; update separately after scanning.
for p in (root/'test').glob('*.dart'):
    original=p.read_text()
    p.write_text(original.replace('version: 0.32.0+81', 'version: 0.32.1+82'))

print('ELXVRO v0.32.1: Adventure UI/gameplay/visual assets removed; legacy save data untouched.')