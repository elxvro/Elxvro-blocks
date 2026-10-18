#!/usr/bin/env python3
"""Apply v0.29.6 adventure fixes to the v0.29.4 assembled Flutter source."""
from pathlib import Path
import sys

root = Path(sys.argv[1] if len(sys.argv) > 1 else 'extracted/elxvro-blocks')

def replace_one(source, old, new, name):
    hits = source.count(old)
    if hits != 1:
        raise RuntimeError(f'{name}: expected one patch anchor, got {hits}')
    return source.replace(old, new, 1)

screen_path = root / 'lib/screens/falling_blocks_screen.dart'
screen = screen_path.read_text()
screen = replace_one(screen, "import '../models/adventure_level.dart';",
    "import '../models/adventure_level.dart';\nimport '../game/adventure_rise_rules.dart';", 'rise engine import')
start = screen.index('  void _riseBoard() {')
end = screen.index('\n  bool _canPlace(', start)
screen = screen[:start] + '''  void _riseBoard() {
    if (!_isAdventure || _paused || _gameOver || _finishing || _locking) return;
    final hole = _random.nextInt(_cols);
    final incoming = List<int>.generate(
      _cols, (col) => col == hole ? -1 : _random.nextInt(7),
    );
    final decision = planAdventureRise(
      board: _board,
      activeCells: _piece.cells,
      activeRow: _row,
      activeCol: _col,
      incomingRow: incoming,
    );
    switch (decision.outcome) {
      case AdventureRiseOutcome.overflow:
        unawaited(_finish(success: false));
        return;
      case AdventureRiseOutcome.lockActivePiece:
        unawaited(_lockPiece());
        return;
      case AdventureRiseOutcome.rise:
        setState(() => _board = decision.board!);
        _restartTimer();
    }
  }
''' + screen[end:]
for method in ['void _move(int delta)', 'void _rotate()', 'void _hardDrop()',
               'void _onPanUpdate(DragUpdateDetails details)']:
    old = f'  {method} {{\n    if (_paused || _gameOver || _finishing) return;'
    new = f'  {method} {{\n    if (_paused || _gameOver || _finishing || _locking) return;'
    screen = replace_one(screen, old, new, f'lock guard for {method}')
screen = replace_one(screen,
    '    _finishing = true;\n    _timer?.cancel();\n\n    if (_isAdventure) {',
    '''    _finishing = true;
    _timer?.cancel();
    // Endless mode ends on defeat; a high score qualifies as completion.
    final completed = _isAdventure
        ? _score >= widget.adventureLevel!.targetScore
        : success;

    if (_isAdventure) {''', 'terminal completion check')
screen = replace_one(screen,
    '        level: level.number,\n        reward: 0,\n        score: _score,',
    '        level: level.number,\n        reward: completed ? level.reward : 0,\n        score: _score,\n        completed: completed,', 'terminal reward')
screen = replace_one(screen,
    '    if (success) {\n      unawaited(AudioService.instance.playReward());',
    '    if (completed) {\n      unawaited(AudioService.instance.playReward());', 'terminal audio')
screen = replace_one(screen,
    '                ? (success\n                    ? AppStrings.current.f(',
    '                ? (completed\n                    ? AppStrings.current.f(', 'terminal dialog title')
screen = replace_one(screen,
    'color: success ? _palette.first : const Color(0xFFFFD98B),',
    'color: completed ? _palette.first : const Color(0xFFFFD98B),', 'terminal dialog color')
screen_path.write_text(screen)

state_path = root / 'lib/app_state.dart'
state = state_path.read_text()
state = replace_one(state,
    '    required int reward,\n    required int score,\n  }) async {\n    if (level < 1 || level > 60)',
    '    required int reward,\n    required int score,\n    bool completed = true,\n  }) async {\n    if (level < 1 || level > 60)', 'progression API')
state = replace_one(state,
    '    final firstCompletion = _adventureCompleted.add(level);',
    '    final firstCompletion = completed && _adventureCompleted.add(level);', 'completion vs unlock')
state_path.write_text(state)

pubspec = root / 'pubspec.yaml'
pubspec.write_text(replace_one(pubspec.read_text(),
    'version: 0.29.4+68', 'version: 0.29.6+70', 'release version'))
for path in (root / 'test').glob('*.dart'):
    original = path.read_text()
    adjusted = original.replace('version: 0.29.4+68', 'version: 0.29.6+70')
    if adjusted != original:
        path.write_text(adjusted)
print('Applied v0.29.6+70 adventure collision, locking and progression fixes.')
