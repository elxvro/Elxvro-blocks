#!/usr/bin/env python3
"""Keep previous-release test fixtures and Settings in sync with pubspec."""
from pathlib import Path
import re
import sys

root = Path(sys.argv[1] if len(sys.argv) > 1 else '.')
pubspec = (root / 'pubspec.yaml').read_text(encoding='utf-8')
match = re.search(r'^version:\s*(\d+\.\d+\.\d+\+\d+)\s*$', pubspec, re.M)
assert match, 'Missing pubspec release version'
current = match.group(1)
assert current == '0.38.21+129', f'Unexpected release version: {current}'
previous = '0.38.20+128'
fixtures = (
    'play_games_sdk_regression_test.dart',
    'real_material_audio_test.dart',
    'remove_adventure_test.dart',
    'v0240_features_test.dart',
    'v0287_support_test.dart',
    'v0372_classic_theme_restoration_test.dart',
    'v0373_play_console_checks_test.dart',
)
for name in fixtures:
    file = root / 'test' / name
    data = file.read_text(encoding='utf-8')
    old = f"contains('version: {previous}')"
    new = f"contains('version: {current}')"
    assert data.count(old) == 1, f'Fixture version anchor changed: {name}'
    file.write_text(data.replace(old, new), encoding='utf-8')
screen = root / 'lib/screens/settings_screen.dart'
data = screen.read_text(encoding='utf-8')
old = "'v0.38.20  •"
new = "'v0.38.21  •"
assert data.count(old) == 1, 'Settings version label changed'
screen.write_text(data.replace(old, new), encoding='utf-8')
assert all(f"contains('version: {current}')" in (root / 'test' / n).read_text() for n in fixtures)
assert new in screen.read_text()
assert not any(f"contains('version: {previous}')" in p.read_text() for p in (root / 'test').glob('*.dart'))
print('PASS: Release version contract, 7 fixtures and Settings updated') 
