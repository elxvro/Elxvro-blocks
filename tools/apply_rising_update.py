#!/usr/bin/env python3
"""Apply the v0.29.0 gameplay and economy changes to the v0.28.9 build source.
Patch in place so v0.28.7/8/9 additions and existing saves survive.
"""
from pathlib import Path
import difflib
import subprocess

root = Path("extracted/elxvro-blocks")
source = Path("source_snapshot/lib/screens/falling_blocks_screen.dart")
base = subprocess.check_output([
    "git", "show",
    "origin/work-v0.28.9-weekly-challenge:source_snapshot/lib/screens/falling_blocks_screen.dart",
], text=True)
updated = source.read_text()
# Apply the last successfully built gameplay snapshot first, then the
# small speed/line-clear adjustments after the base patch.
updated = subprocess.check_output([
    "git", "show",
    "087251224a62733114ed549973886bcfb25a87ef:source_snapshot/lib/screens/falling_blocks_screen.dart",
], text=True)
diff = "".join(difflib.unified_diff(
    base.splitlines(keepends=True),
    updated.splitlines(keepends=True),
    fromfile="a/lib/screens/falling_blocks_screen.dart",
    tofile="b/lib/screens/falling_blocks_screen.dart",
))
result = subprocess.run(
    ["patch", "--batch", "--fuzz=2", "-p1", "-d", str(root)],
    input=diff, text=True, capture_output=True,
)
print(result.stdout, result.stderr)
if result.returncode:
    raise SystemExit("Adventure patch did not apply cleanly")

gameplay_path = root / "lib/screens/falling_blocks_screen.dart"
gameplay = gameplay_path.read_text()
changes = [
    ("max(105, level.fallingIntervalMs - _riseCount * 14)", "max(420, level.fallingIntervalMs)"),
    ("final limit = max(2, 6 - _riseCount ~/ 4);", "const limit = 8;"),
    ("    var overflow = false;\\n    for (final cell in _piece.cells) {",
     "    var overflow = false;\\n    final placedRows = <int>{};\\n    for (final cell in _piece.cells) {"),
    ("        _board[r][c] = _piece.colorIndex;\\n",
     "        _board[r][c] = _piece.colorIndex;\\n        placedRows.add(r);\\n"),
    ("    for (var r = 0; r < _rows; r++) {\\n      if (_board[r].every((cell) => cell >= 0)) cleared.add(r);\\n    }",
     "    for (final r in placedRows) {\\n      if (_board[r].every((cell) => cell >= 0)) cleared.add(r);\\n    }\\n    cleared.sort();"),
]
for old, new in changes:
    if old not in gameplay:
        raise SystemExit("Gameplay adjustment anchor missing: " + old[:70])
    gameplay = gameplay.replace(old, new, 1)
gameplay_path.write_text(gameplay)

state_path = root / "lib/app_state.dart"
state = state_path.read_text()
def replace_once(old, new):
    global state
    if old not in state:
        raise ValueError("Economy patch anchor missing: " + old[:70])
    state = state.replace(old, new, 1)

replace_once(
    "static const int weeklyRewardAmount = 250;",
    "static const int weeklyRewardAmount = 80;",
)
state = state.replace(
    "const rewards = <int>[50, 75, 100, 125, 150, 200, 300];",
    "const rewards = <int>[10, 15, 20, 25, 30, 40, 60];",
)
start = state.index("  int themePrice(String id) {")
end = state.index("\n  Future<void> load()", start)
state = state[:start] + """  int themePrice(String id) {
    // Old unlocks and milestone themes remain accessible.
    switch (id) {
      case 'classic': return 0;
      case 'night': return 2400;
      case 'marble': return 3600;
      case 'fire':
      case 'nature': return 4800;
      case 'aurora': return 7200;
      case 'arctic': return 9000;
      case 'copper': return 10500;
      case 'obsidian':
      case 'polar_aurora':
      case 'magma': return 0;
      default: return 6000;
    }
  }
""" + state[end:]
state_path.write_text(state)
pubspec = root / "pubspec.yaml"
p = pubspec.read_text()
assert "version: 0.28.9+63" in p
pubspec.write_text(p.replace("version: 0.28.9+63", "version: 0.29.3+67"))
print("Applied rising adventure and economy update.")
