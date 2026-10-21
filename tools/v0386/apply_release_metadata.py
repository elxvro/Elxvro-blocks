from pathlib import Path
import sys

root = Path(sys.argv[1])
pub = root / 'pubspec.yaml'
s = pub.read_text()
assert s.count('version: 0.38.5+113') == 1
pub.write_text(s.replace('version: 0.38.5+113', 'version: 0.38.6+114'))
count = 0
for path in (root / 'test').glob('*.dart'):
    s = path.read_text()
    if 'version: 0.38.5+113' in s:
        count += s.count('version: 0.38.5+113')
        path.write_text(s.replace('version: 0.38.5+113', 'version: 0.38.6+114'))
assert count == 7, count

info = root / 'lib/services/app_build_info.dart'
assert not info.exists()
info.write_text("""/// User-facing release version. Updated with pubspec for each release.
abstract final class AppBuildInfo {
  static const String version = '0.38.6';
  static const int buildNumber = 114;
  static const String versionLabel = '$version ($buildNumber)';
}
""")

p = root / 'lib/screens/support_screen.dart'
s = p.read_text()
assert s.count("import '../l10n/app_strings.dart';") == 1
s = s.replace("import '../l10n/app_strings.dart';",
              "import '../l10n/app_strings.dart';\nimport '../services/app_build_info.dart';")
assert s.count('[ELXVRO Blocks v0.38.2]') == 1
s = s.replace('[ELXVRO Blocks v0.38.2]', '[ELXVRO Blocks v${AppBuildInfo.version}]')
assert s.count('Version: 0.38.2 (110)') == 1
p.write_text(s.replace('Version: 0.38.2 (110)', 'Version: ${AppBuildInfo.versionLabel}'))

p = root / 'lib/screens/settings_screen.dart'
s = p.read_text()
assert s.count("import '../services/audio_service.dart';") == 1
s = s.replace("import '../services/audio_service.dart';",
              "import '../services/audio_service.dart';\nimport '../services/app_build_info.dart';")
assert s.count('v0.38.2  •  ') == 1
p.write_text(s.replace('v0.38.2  •  ', 'v${AppBuildInfo.version}  •  '))

p = root / 'test/v0287_support_test.dart'
s = p.read_text()
assert s.count("expect(support, contains('Version: 0.38.2 (110)'));") == 1
p.write_text(s.replace("expect(support, contains('Version: 0.38.2 (110)'));",
                      "expect(support, contains(r'Version: ${AppBuildInfo.versionLabel}'));"))

p = root / 'test/v0386_release_consistency_test.dart'
assert not p.exists()
p.write_text("""import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:elxvro_blocks/services/app_build_info.dart';

void main() {
  test('support and settings use actual published build 114', () {
    expect(AppBuildInfo.version, '0.38.6');
    expect(AppBuildInfo.buildNumber, 114);
    expect(AppBuildInfo.versionLabel, '0.38.6 (114)');
    expect(File('pubspec.yaml').readAsStringSync(), contains('version: 0.38.6+114'));
    final support = File('lib/screens/support_screen.dart').readAsStringSync();
    final settings = File('lib/screens/settings_screen.dart').readAsStringSync();
    expect(support, contains(r'Version: ${AppBuildInfo.versionLabel}'));
    expect(settings, contains(r'v${AppBuildInfo.version}  •'));
    expect(support, isNot(contains('Version: 0.38.2 (110)')));
    expect(settings, isNot(contains('v0.38.2')));
  });
}
""")
(root / 'V0386_RELEASE_NOTES.md').write_text(
    '# ELXVRO Blocks v0.38.6 (Build 114)\n\n'
    '- Fixed obsolete v0.38.2 displayed in help mail and settings.\n'
    '- Preserved v0.38.5 Google Play Games automatic connection.\n'
    '- Preserved Google Play Billing 8, 10 locales, Arabic layout, all game modes.\n'
    '- Three full Flutter analysis and regression test passes required.\n'
)
print('Applied v0.38.6 release metadata fix; updated 7 existing tests')
