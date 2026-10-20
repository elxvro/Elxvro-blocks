from pathlib import Path
import sys
root=Path(sys.argv[1])
for test in (root/'test').glob('*.dart'):
    txt=test.read_text()
    txt=txt.replace('version: 0.36.2+97','version: 0.37.0+98')
    test.write_text(txt)

shell=root/'lib/screens/premium_navigation_shell.dart'
s=shell.read_text()
s=s.replace('color: _muted, height: 105)),','color: _muted, height: 114)),')
s=s.replace('color: const Color(0xFFB9DAED), height: 105))','color: const Color(0xFFB9DAED), height: 114))')
s=s.replace('color: const Color(0xFFE6A87A), height: 105))','color: const Color(0xFFE6A87A), height: 114))')
s=s.replace('color: _gold, height: 131, featured: true))','color: _gold, height: 140, featured: true))')
s=s.replace('child: Column(mainAxisAlignment: MainAxisAlignment.center,\n      children: <Widget>[\n        Icon(icon, size: featured ? 37 : 31',
            'child: Column(mainAxisAlignment: MainAxisAlignment.center,\n      children: <Widget>[\n        Icon(icon, size: featured ? 34 : 27')
s=s.replace('const SizedBox(height: 7),\n        Text(value, maxLines: 1',
            'const SizedBox(height: 5),\n        Text(value, maxLines: 1')
shell.write_text(s)

widget_test=root/'test/widget_test.dart'
widget_test.write_text('''import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:elxvro_blocks/app_state.dart';
import 'package:elxvro_blocks/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('ELXVRO v0.37.0 reference navigation is the startup home', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final state = AppState();
    await state.load();
    await tester.pumpWidget(ElxvroBlocksApp(appState: state));
    await tester.pump();
    expect(find.byKey(const ValueKey<String>('premium_journey')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('premium_nav_1')));
    await tester.pump();
    expect(find.byKey(const ValueKey<String>('premium_classic_mode')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('premium_falling_mode')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('premium_adventure_mode')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
''')
nav_test=root/'test/v0370_reference_navigation_test.dart'
nt=nav_test.read_text()
nt=nt.replace("    expect(find.text('HESAP'), findsOneWidget);",
              "    await tester.scrollUntilVisible(find.text('HESAP'), 180.0);\n    expect(find.text('HESAP'), findsOneWidget);")
nav_test.write_text(nt)
print('v0370 hotfix applied',root)