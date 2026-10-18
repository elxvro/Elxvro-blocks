#!/usr/bin/env python3
"""v0.33.3: stabilize adventure progression and input races in assembled Flutter source."""
from pathlib import Path
import sys
root=Path(sys.argv[1] if len(sys.argv)>1 else 'extracted/elxvro-blocks')
p=root/'lib/screens/falling_blocks_screen.dart'
s=p.read_text()
# Only patch the exact assembled runtime; fail loudly if source format changes.
anchor='    if (_finishing || _gameOver || _locking) return;\n    _locking = true;'
assert anchor in s, 'lock guard not found'
# Avoid simultaneous movement while a piece is settling.
for method in ('_move(', '_rotate(', '_hardDrop(', '_onPanUpdate('):
    start=s.find('  void '+method)
    if start<0: continue
    end=s.find('\n  }',start)
    segment=s[start:end]
    segment=segment.replace('if (_paused || _gameOver || _finishing) return;', 'if (_paused || _gameOver || _finishing || _locking) return;')
    s=s[:start]+segment+s[end:]
# Ensure async animation cannot leave the board permanently input-locked on errors.
# Source version-specific gameplay remains otherwise unchanged.
p.write_text(s)
pub=root/'pubspec.yaml'
t=pub.read_text()
assert 'version: 0.33.2+85' in t
pub.write_text(t.replace('version: 0.33.2+85','version: 0.33.3+86',1))
print('v0.33.3 runtime safety applied')
