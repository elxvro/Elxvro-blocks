#!/usr/bin/env python3
"""Audit the native Play Services image loader in a release APK.

This is a warning tracker, not an assertion that a closed-source SDK is fixed.
Do not treat absence of a string as proof of absence of the API without DEX analysis.
"""
import sys
import zipfile
from pathlib import Path

apk = Path(sys.argv[1])
with zipfile.ZipFile(apk) as archive:
    dex_files = [item for item in archive.namelist() if item.endswith('.dex')]
    if not dex_files:
        raise SystemExit('No classes.dex in release APK')
    dex = b'\n'.join(archive.read(path) for path in dex_files)

checks = {
    'Play Services image-loader marker': b'LoadBitmapFromDiskRunnable' in dex,
    'BitmapFactory decodeFileDescriptor reference': b'decodeFileDescriptor' in dex,
    'Google Play Services image package': b'com/google/android/gms/common/images' in dex,
}
for name, present in checks.items():
    print(('PRESENT' if present else 'NOT FOUND') + ' : ' + name)
if all(checks.values()):
    print('NOTICE: Play Services BitmapFactory Play Console recommendation may persist.')
else:
    print('NOTICE: Review compiled SDK calls and the refreshed Play Console advisory; static strings alone are inconclusive.')
