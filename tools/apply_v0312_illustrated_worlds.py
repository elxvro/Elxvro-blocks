#!/usr/bin/env python3
"""Integrate illustrated Adventure-only scenery over assembled v0.31.1 source."""
from pathlib import Path
import sys
root = Path(sys.argv[1] if len(sys.argv)>1 else 'extracted/elxvro-blocks')
pub = root/'pubspec.yaml'
raw=pub.read_text()
assert raw.count('version: 0.31.1+77')==1, 'Unexpected source version'
assert raw.count('    - assets/images/\n')==1, 'Flutter assets anchor changed'
pub.write_text(raw.replace('version: 0.31.1+77', 'version: 0.31.2+78',1).replace('    - assets/images/\n','    - assets/images/\n    - assets/images/adventure_worlds/\n',1))
for test in (root/'test').glob('*.dart'):
    old=test.read_text()
    newer=old.replace('0.31.1+77','0.31.2+78')
    if newer!=old: test.write_text(newer)
print('Illustrated Adventure assets and version 0.31.2+78 configured.')
