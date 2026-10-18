#!/usr/bin/env python3
"""Upgrade Google Play Games SDKs in the assembled v0.29.6 source without changing save data."""
from pathlib import Path
import sys

root = Path(sys.argv[1] if len(sys.argv) > 1 else 'extracted/elxvro-blocks')
pubspec = root / 'pubspec.yaml'
text = pubspec.read_text()
updates = {
    'version: 0.29.6+70': 'version: 0.29.8+72',
    '  games_services: 5.0.0': '  games_services: 5.3.0',
    '  games_services_platform_interface: 5.0.0': '  games_services_platform_interface: 5.3.0',
}
for old, new in updates.items():
    if text.count(old) != 1:
        raise SystemExit(f'Unexpected dependency/version anchor: {old}')
    text = text.replace(old, new, 1)
pubspec.write_text(text)

# Several test files assert the release version as an exact string.
for test in (root / 'test').glob('*.dart'):
    content = test.read_text()
    updated = content.replace('version: 0.29.6+70', 'version: 0.29.8+72')
    if content != updated:
        test.write_text(updated)

# No changes to the score / achievement service, app state, credentials, or save keys.
print('Play Games Flutter packages upgraded to 5.3.0; release 0.29.8+72.')
