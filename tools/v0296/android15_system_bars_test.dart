import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Flutter uses edge-to-edge without writing deprecated system bar colors', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains('SystemUiMode.edgeToEdge'));
    expect(source, isNot(contains('statusBarColor: Colors.transparent')));
    expect(source, isNot(contains('systemNavigationBarColor: Colors.transparent')));
    expect(source, contains('SafeArea('));
  });

  test('MainActivity configures edge-to-edge without deprecated window bar APIs', () {
    final activity = File(
      'android/app/src/main/kotlin/com/elxvro/elxvro_blocks/MainActivity.kt',
    ).readAsStringSync();
    expect(activity, contains('WindowCompat.setDecorFitsSystemWindows(window, false)'));
    expect(activity, contains('isAppearanceLightStatusBars = false'));
    expect(activity, contains('isAppearanceLightNavigationBars = false'));
    expect(activity, isNot(contains('window.setStatusBarColor(')));
    expect(activity, isNot(contains('window.setNavigationBarColor(')));
    expect(activity, isNot(contains('window.statusBarColor =')));
    expect(activity, isNot(contains('window.navigationBarColor =')));
  });
}
