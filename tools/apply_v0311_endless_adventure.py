#!/usr/bin/env python3
"""v0.31.1: unlimited Adventure runs with theme-aware worlds and power stones."""
from pathlib import Path
import sys
root = Path(sys.argv[1] if len(sys.argv) > 1 else '.')

def change(file, old, new, label):
    path = root / file
    source = path.read_text()
    count = source.count(old)
    if count != 1:
        raise RuntimeError(f'{label}: expected one anchor, found {count}')
    path.write_text(source.replace(old, new, 1))

p='lib/screens/falling_blocks_screen.dart'
change(p, "import '../game/adventure_quest.dart';", "import '../game/adventure_quest.dart';\nimport '../game/adventure_specials.dart';\nimport '../widgets/adventure_world_backdrop.dart';\nimport '../widgets/adventure_special_tile.dart';", 'new imports')
change(p,'  int _riseTicks = 0;', '  int _riseTicks = 0;\n  int _shieldCharges = 0;', 'shield state')
change(p, '    _riseTicks = 0;\n    _locking = false;', '    _riseTicks = 0;\n    _shieldCharges = 0;\n    _locking = false;', 'reset shield')
change(p, '''    if (code != null && _random.nextInt(5) == 0) return code;
    return _random.nextInt(7);''', '''    if (code != null && _random.nextInt(5) == 0) return code;
    final bonus = AdventureStone.forWorld(_quest!.mission.world, _random.nextInt(12));
    if (bonus != null) return bonus;
    return _random.nextInt(7);''', 'random themed stones')
change(p, '''  void _riseBoard() {
    if (!_isAdventure || _paused || _gameOver || _finishing || _locking) return;
    final hole''', '''  void _riseBoard() {
    if (!_isAdventure || _paused || _gameOver || _finishing || _locking) return;
    if (_shieldCharges > 0) {
      // Consume one shield instead of adding a dangerous rising row.
      setState(() => _shieldCharges--);
      return;
    }
    final hole''', 'shield against rising rows')
change(p, '''      final clearedCells = <int>[
        for (final r in cleared) ..._board[r],
      ];''','''      final clearedCells = <int>[
        for (final r in cleared) ..._board[r],
      ];
      // Pulse stones discharge into adjacent rows before full rows are removed.
      final pulseRemoved = _isAdventure
          ? AdventureStone.discharge(_board, cleared)
          : 0;
      if (_isAdventure) {
        _shieldCharges = (_shieldCharges + AdventureStone.shields(clearedCells))
            .clamp(0, 3).toInt();
      }''','pulse and shield collect')
change(p, '''      _score += base * _difficultyLevel + comboBonus;''','''      _score += base * _difficultyLevel + comboBonus;
      if (_isAdventure) {
        _score += AdventureStone.bonusScore(clearedCells) + pulseRemoved * 25;
      }''','stone points with unlimited score')
change(p, '''    if (_quest?.completed == true) {
      _locking = false;
      await _finish(success: true);
      return;
    }

''', '''    // Adventure objectives are milestones, never an automatic game-ending score
    // limit. The run continues until the board overflows or the player loses.

''','remove quest auto-end')
change(p, '''    // Mission objectives, not endless score, determine Adventure victory.
    final completed = _isAdventure ? success && _quest!.completed : success;''', '''    // Score is uncapped. On defeat, reward any Adventure milestone achieved
    // during the run without ever ending the game early for points.
    final completed = _isAdventure ? _quest!.completed : success;''', 'evaluate quest only at loss')
change(p, '''        child: SafeArea(
          child: Column(''', '''        child: Stack(fit: StackFit.expand, children: <Widget>[
          if (_isAdventure)
            AdventureWorldBackdrop(world: _quest!.mission.world, theme: _theme),
          SafeArea(
          child: Column(''', 'adventure-only layered background')
change(p, '''              _Controls(
                accent: levelAccent,
                onRotate: _rotate,
                onDrop: _hardDrop,
              ),
            ],
          ),
        ),
      ),''','''              _Controls(
                accent: levelAccent,
                onRotate: _rotate,
                onDrop: _hardDrop,
              ),
            ],
          ),
        ),
        ]),
      ),''','close background stack')
change(p, '''                              if (_isAdventure && fixedColor >= AdventureSpecial.ice) {
                                final marker = switch (fixedColor) {
                                  AdventureSpecial.ice => Icons.ac_unit_rounded,
                                  AdventureSpecial.crystal => Icons.diamond_rounded,
                                  _ => Icons.hexagon_rounded,
                                };
                                return Stack(fit: StackFit.expand, children: <Widget>[
                                  tile,
                                  Center(child: Icon(marker, size: 14,
                                    color: Colors.white.withValues(alpha: .94))),
                                ]);
                              }''','''                              if (_isAdventure && fixedColor >= AdventureSpecial.ice) {
                                return AdventureSpecialTile(
                                  code: fixedColor,
                                  theme: _theme,
                                  base: base,
                                  accent: _theme.blockAccent,
                                );
                              }''','new theme-aware special tile')
change(p, '''                  turkish: widget.appState.languageCode == 'tr',
                ),''', '''                  turkish: widget.appState.languageCode == 'tr',
                  shieldCharges: _shieldCharges,
                ),''', 'HUD shield counter')

hud='lib/widgets/adventure_mission_hud.dart'
change(hud, '''    required this.turkish,
  });''', '''    required this.turkish,
    this.shieldCharges = 0,
  });''','HUD param')
change(hud, '''  final bool turkish;
''','''  final bool turkish;
  final int shieldCharges;
''','HUD field')
change(hud, '''      child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        Row(children: <Widget>[''', '''      child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        Row(children: <Widget>[
          const Icon(Icons.all_inclusive_rounded, size: 13, color: Colors.white70),
          const SizedBox(width: 5),
          Expanded(child: Text(
            turkish ? 'SINIRSIZ SKOR • KAYBEDENE KADAR OYNA'
                : 'UNLIMITED SCORE • PLAY UNTIL DEFEAT',
            style: const TextStyle(color: Colors.white70, fontSize: 9,
              fontWeight: FontWeight.w800),
          )),
          if (shieldCharges > 0) ...<Widget>[
            Icon(Icons.shield_rounded, color: accent, size: 13),
            Text(' ×$shieldCharges', style: TextStyle(color: accent,
              fontSize: 10, fontWeight: FontWeight.w900)),
          ],
          if (progress.completed)
            const Icon(Icons.check_circle_rounded, color: Color(0xFF66EAA0), size: 14),
        ]),
        const SizedBox(height: 6),
        Row(children: <Widget>[''', 'endless HUD callout')

result='lib/widgets/adventure_result_dialog.dart'
change(result, "(turkish ? 'GÖREV TAMAMLANAMADI' : 'MISSION FAILED')",
       "(turkish ? 'KOŞU SONA ERDİ • GÖREV EKSİK' : 'RUN ENDED • QUEST INCOMPLETE')", 'defeat dialog wording')
change(result, "(turkish ? 'BÖLÜM TAMAMLANDI!' : 'LEVEL COMPLETE!')",
       "(turkish ? 'KOŞU BİTTİ • GÖREV BAŞARILI!' : 'RUN ENDED • QUEST COMPLETE!')", 'success dialog wording')

# Previous levels retain stored targetScore metadata; it is no longer a stop rule.
level='lib/models/adventure_level.dart'
change(level, "'$fallingTargetScore puana ulaş • hız ve renk her bölüm değişir',\n        'Reach $fallingTargetScore points • speed and colors change every level',",
             "'Kaybedene kadar skor topla • görevleri tamamla',\n        'Score until defeat • complete your objectives',", 'level description')

pubspec=root/'pubspec.yaml'
content=pubspec.read_text()
if content.count('version: 0.31.0+76') != 1:
    raise RuntimeError('Unexpected release version')
pubspec.write_text(content.replace('version: 0.31.0+76','version: 0.31.1+77',1))
for test in (root/'test').glob('*.dart'):
    content=test.read_text().replace('version: 0.31.0+76','version: 0.31.1+77')
    test.write_text(content)
print('v0.31.1 Adventure-only endless scoring and theme stones integrated.')
