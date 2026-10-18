#!/usr/bin/env python3
"""Adapt ELXVRO Blocks v0.29.8 for Android edge-to-edge and efficient bitmaps."""
from pathlib import Path
import argparse

def replace_exact(text: str, old: str, new: str, title: str) -> str:
    if text.count(old) != 1:
        raise SystemExit(f"{title}: expected one source anchor, got {text.count(old)}")
    return text.replace(old, new, 1)

def apply_dart(root: Path) -> None:
    main = root / 'lib/main.dart'
    data = main.read_text()
    data = replace_exact(
        data, "import 'package:flutter/material.dart';",
        "import 'package:flutter/material.dart';\nimport 'package:flutter/services.dart';",
        'Flutter services import',
    )
    data = replace_exact(
        data, '      WidgetsFlutterBinding.ensureInitialized();',
        '''      WidgetsFlutterBinding.ensureInitialized();
      // Android 15+ uses edge-to-edge; opt in on earlier Android too.
      unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ));''',
        'Flutter edge-to-edge activation',
    )
    main.write_text(data)

    # The splash PNG is 1024px; constrain its actual decode/cache footprint.
    launch = root / 'lib/screens/launch_screen.dart'
    data = launch.read_text()
    data = replace_exact(
        data,
        "                    width: 170,\n                    height: 170,\n                    filterQuality:",
        "                    width: 170,\n                    height: 170,\n                    cacheWidth: 340,\n                    cacheHeight: 340,\n                    filterQuality:",
        'Splash bitmap decode size',
    )
    launch.write_text(data)
    screens = list((root / 'lib/screens').glob('*.dart'))
    without_safe_area = [p.name for p in screens
                         if 'Scaffold(' in p.read_text()
                         and 'SafeArea(' not in p.read_text()]
    if without_safe_area:
        raise SystemExit(f'Scaffold without SafeArea: {without_safe_area}')
    print(f'Flutter edge-to-edge enabled, splash bitmap downsampled; '
          f'{len(screens)} screens audited for SafeArea.')

def apply_android(root: Path) -> None:
    # FlutterActivity is an Activity, not ComponentActivity.
    # WindowCompat supports it without changing the Flutter embedding.
    mains = list((root / 'android/app/src/main/kotlin').rglob('MainActivity.kt'))
    if len(mains) != 1:
        raise SystemExit(f'Expected one Kotlin MainActivity, found {mains}')
    kotlin = mains[0]
    data = kotlin.read_text()
    data = replace_exact(
        data,
        'import io.flutter.embedding.android.FlutterActivity',
        'import android.os.Bundle\nimport androidx.core.view.WindowCompat\n'
        'import io.flutter.embedding.android.FlutterActivity',
        'Kotlin edge-to-edge imports',
    )
    data = replace_exact(
        data,
        'class MainActivity : FlutterActivity()',
        '''class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Draw behind both system bars. No deprecated bar color setters:
        // WindowCompat.enableEdgeToEdge would inline them under R8.
        WindowCompat.setDecorFitsSystemWindows(window, false)
        val insets = WindowCompat.getInsetsController(window, window.decorView)
        insets.isAppearanceLightStatusBars = false
        insets.isAppearanceLightNavigationBars = false
    }
}''',
        'MainActivity edge-to-edge handler',
    )
    kotlin.write_text(data)
    gradle = root / 'android/app/build.gradle.kts'
    if not gradle.is_file():
        raise SystemExit('Expected Kotlin Gradle DSL from Flutter 3.47.4')
    data = gradle.read_text()
    data = replace_exact(data, 'compileSdk = flutter.compileSdkVersion',
                         'compileSdk = 36', 'Android compile SDK 36')
    data += '''\n// WindowCompat edge-to-edge API (AndroidX Core 1.17+).
dependencies {
    implementation("androidx.core:core-ktx:1.17.0")
    // Use Google Play Games v2 SDK released September 2026.
    implementation("com.google.android.gms:play-services-games-v2:22.1.0")
    implementation("com.google.android.gms:play-services-base:18.11.0")
    implementation("com.google.android.gms:play-services-basement:18.12.0")
}
'''
    gradle.write_text(data)
    assert 'WindowCompat.setDecorFitsSystemWindows(window, false)' in kotlin.read_text()
    assert 'androidx.core:core-ktx:1.17.0' in gradle.read_text()
    assert 'play-services-games-v2:22.1.0' in gradle.read_text()
    assert 'play-services-base:18.11.0' in gradle.read_text()
    assert 'play-services-basement:18.12.0' in gradle.read_text()
    print('Android 15/16 edge-to-edge configured without direct bar color APIs.')

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--dart', type=Path)
    parser.add_argument('--android', type=Path)
    args = parser.parse_args()
    if bool(args.dart) == bool(args.android):
        parser.error('Supply exactly one of --dart / --android')
    (apply_dart(args.dart) if args.dart else apply_android(args.android))
