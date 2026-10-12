import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('real material audio build pipeline is included', () {
    expect(File('tool/fetch_real_material_audio.sh').existsSync(), isTrue);
    expect(File('REAL_AUDIO_CREDITS.md').existsSync(), isTrue);
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('version: 0.24.0+48'));
  });
}
