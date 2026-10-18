#!/usr/bin/env python3
"""Patch the assembled v0.29.8 source: prevent midair lock and pause gravity.

All changes are surgical: no save-key, game-design, or monetization changes.
"""
from pathlib import Path
import sys

root = Path(sys.argv[1] if len(sys.argv) > 1 else 'extracted/elxvro-blocks')


def replace_once(content: str, old: str, new: str, description: str) -> str:
    actual = content.count(old)
    if actual != 1:
        raise RuntimeError(
            f'{description}: expected one anchor, got {actual}: {old[:75]!r}'
        )
    return content.replace(old, new, 1)


rules_file = root / 'lib/game/adventure_rise_rules.dart'
rules = rules_file.read_text()
# A collision with the *proposed* shifted stack must never lock the falling
# piece in midair. Defer the rise until the active piece has moved or landed.
rules = rules.replace('AdventureRiseOutcome.lockActivePiece',
                      'AdventureRiseOutcome.defer')
rules = replace_once(
    rules,
    'enum AdventureRiseOutcome { rise, lockActivePiece, overflow }',
    'enum AdventureRiseOutcome { rise, defer, overflow }',
    'rise outcome API',
)
rules_file.write_text(rules)

screen_file = root / 'lib/screens/falling_blocks_screen.dart'
screen = screen_file.read_text()
screen = replace_once(
    screen,
    '    if (_paused || _gameOver || _finishing) return;\n'
    '    _timer = Timer.periodic(_fallInterval, (_) {',
    '    if (_paused || _gameOver || _finishing || _locking) return;\n'
    '    _timer = Timer.periodic(_fallInterval, (_) {',
    'avoid ticking during settling',
)
screen = replace_once(
    screen,
    '      case AdventureRiseOutcome.lockActivePiece:\n'
    '        unawaited(_lockPiece());\n'
    '        return;',
    '      case AdventureRiseOutcome.defer:\n'
    '        // Keep the falling piece independent: only lock on actual landing.\n'
    '        // Retry the queued rise on the next fall tick.\n'
    '        _riseTicks = 7;\n'
    '        return;',
    'defer colliding rise rather than forcing a premature lock',
)
screen = replace_once(
    screen,
    '    while (mounted && !_gameOver && !_finishing) {\n'
    '      var moved = false;',
    '    while (mounted && !_gameOver && !_finishing) {\n'
    '      if (_paused) {\n'
    '        // Freeze falling stones and hold the outstanding piece lock.\n'
    '        await Future<void>.delayed(const Duration(milliseconds: 120));\n'
    '        continue;\n'
    '      }\n'
    '      var moved = false;',
    'suspend animated gravity during app pause',
)
screen = replace_once(
    screen,
    '      if (_isAdventure) await _settleFloatingBlocks();\n'
    '      _combo += 1;',
    '      if (_isAdventure) await _settleFloatingBlocks();\n'
    '      if (!mounted || _finishing) return;\n'
    '      _combo += 1;',
    'guard async settling after widget disposal',
)
screen_file.write_text(screen)

test_file = root / 'test/adventure_stability_test.dart'
test = test_file.read_text().replace(
    'AdventureRiseOutcome.lockActivePiece', 'AdventureRiseOutcome.defer',
)
test = replace_once(
    test,
    "test('rise collision requests locking before board rises', () {",
    "test('rise collision defers without locking or changing the board', () {",
    'existing collision test name',
)
test_file.write_text(test)

pubspec = root / 'pubspec.yaml'
pubspec.write_text(replace_once(
    pubspec.read_text(), 'version: 0.29.8+72', 'version: 0.29.9+73',
    'release version',
))
for test_path in (root / 'test').glob('*.dart'):
    old = test_path.read_text()
    new = old.replace('version: 0.29.8+72', 'version: 0.29.9+73')
    if new != old:
        test_path.write_text(new)

print('ELXVRO Blocks v0.29.9: safe rise deferral and paused gravity applied.')
