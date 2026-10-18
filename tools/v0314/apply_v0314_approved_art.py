#!/usr/bin/env python3
"""Adventure-only high-resolution background integration."""
from pathlib import Path
import sys

root = Path(sys.argv[1] if len(sys.argv) > 1 else 'extracted/elxvro-blocks')

def patch(rel, pairs):
    p = root / rel
    s = p.read_text()
    for label, old, new in pairs:
        amount = s.count(old)
        if amount != 1:
            raise RuntimeError(f'{rel}: {label}: expected one occurrence, got {amount}')
        s = s.replace(old, new, 1)
    p.write_text(s)

patch('lib/widgets/adventure_world_backdrop.dart', [
    ('top tint', 'theme.backgroundTop.withValues(alpha: 0.59)', 'theme.backgroundTop.withValues(alpha: 0.17)'),
    ('middle tint', 'theme.backgroundBottom.withValues(alpha: 0.53)', 'theme.backgroundBottom.withValues(alpha: 0.22)'),
    ('bottom tint', 'theme.backgroundBottom.withValues(alpha: 0.82)', 'theme.backgroundBottom.withValues(alpha: 0.48)'),
    ('image filter', 'filterQuality: FilterQuality.medium,', 'filterQuality: FilterQuality.high,'),
])
patch('lib/screens/adventure_screen.dart', [
    ('less opaque scrim', 'const ColoredBox(color: Color(0x55030716))', 'const ColoredBox(color: Color(0x24030716))'),
    ('world card size', 'height: 139,', 'height: 175,'),
    ('reveal world art',
     'colors: <Color>[Color(0xEE060C1D), Color(0x99071024),\n                    Color(0x08000000)]',
     'colors: <Color>[Color(0xB0060C1D), Color(0x45071024),\n                    Color(0x08000000)]'),
    ('hero size', 'Container(height: 180,', 'Container(height: 225,'),
    ('card image framing', 'alignment: const Alignment(0, .15)', 'alignment: const Alignment(0, -.08)'),
])
patch('pubspec.yaml', [('release', 'version: 0.31.3+79', 'version: 0.31.4+80')])
for p in (root / 'test').glob('*.dart'):
    s = p.read_text()
    if '0.31.3+79' in s:
        p.write_text(s.replace('0.31.3+79', '0.31.4+80'))

test = root / 'test/adventure_world_images_test.dart'
s = test.read_text()
needle = 'expect(bytes.lengthInBytes, greaterThan(30000), reason:path);'
if s.count(needle) != 1:
    raise RuntimeError('Expected one world artwork regression threshold')
test.write_text(s.replace(needle,
    'expect(bytes.lengthInBytes, greaterThan(110000), reason:path);', 1))

for path in ('lib/screens/home_screen.dart', 'lib/screens/game_screen.dart',
             'lib/models/game_theme.dart', 'lib/services/audio_service.dart',
             'lib/app_state.dart'):
    if not (root / path).is_file():
        raise RuntimeError('Missing protected game file: ' + path)
print('v0.31.4 image-backed Adventure backgrounds and theme-safe UI adjustments applied')
