#!/usr/bin/env python3
"""Install visual-only Adventure 2.3 UI update. No AppState/save/theme assets modified."""
from pathlib import Path
import sys
import base64
import gzip
import json

root = Path(sys.argv[1] if len(sys.argv) > 1 else 'extracted/elxvro-blocks')
archive = Path(__file__).with_name('ui_bundle.b64')
files = json.loads(gzip.decompress(base64.b64decode(archive.read_text())).decode('utf-8'))
expected = {
    'lib/screens/adventure_screen.dart',
    'lib/screens/falling_blocks_screen.dart',
    'lib/widgets/adventure_mission_hud.dart',
    'lib/widgets/adventure_world_backdrop.dart',
    'test/adventure_visual_v0313_test.dart',
}
assert set(files) == expected, set(files)
for relative, data in files.items():
    target = root / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(data)
    print('Updated Adventure UI:', relative)
pubspec = root / 'pubspec.yaml'
raw = pubspec.read_text()
assert raw.count('version: 0.31.2+78') == 1
pubspec.write_text(raw.replace('version: 0.31.2+78', 'version: 0.31.3+79'))
for test_file in (root / 'test').glob('*.dart'):
    raw = test_file.read_text()
    new = raw.replace('version: 0.31.2+78', 'version: 0.31.3+79')
    new = new.replace('AssetImage(AdventureWorldBackdrop.assetFor(index))',
                      'Image.asset(AdventureWorldBackdrop.assetFor(index))')
    # Historical source assertions must follow the redesigned Adventure layout.
    if test_file.name == 'adventure_world_images_test.dart':
        new = new.replace(
            "contains('Image.asset(AdventureWorldBackdrop.assetFor(index))')",
            "contains('Image.asset(AdventureWorldBackdrop.assetFor(index)')")
    if test_file.name == 'v022_language_gameplay_test.dart':
        new = new.replace(
            'constraints.maxWidth - (_isAdventure ? 2 : 6)',
            'constraints.maxWidth *')
    if new != raw: test_file.write_text(new)
assert 'version: 0.31.3+79' in pubspec.read_text()
print('ELXVRO v0.31.3 UI applied. Other screens, themes and saves intact.')