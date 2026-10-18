import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:elxvro_blocks/widgets/adventure_world_backdrop.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('all six Adventure worlds contain image art', () async {
    for (var world=0; world<6; world++) {
      final path=AdventureWorldBackdrop.assetFor(world);
      final bytes=await rootBundle.load(path);
      expect(bytes.lengthInBytes, greaterThan(30000), reason:path);
    }
    expect(AdventureWorldBackdrop.assetFor(-9), endsWith('world_0.webp'));
    expect(AdventureWorldBackdrop.assetFor(99), endsWith('world_5.webp'));
  });
  test('backdrop is pre-rendered art rather than Canvas painting', () {
    final source=File('lib/widgets/adventure_world_backdrop.dart').readAsStringSync();
    expect(source, contains('Image.asset('));
    expect(source, isNot(contains('CustomPaint(')));
    expect(source, isNot(contains('Canvas canvas')));
    final map=File('lib/screens/adventure_screen.dart').readAsStringSync();
    expect(map, contains('AdventureWorldBackdrop(world: world, theme: theme)'));
    expect(map, contains('AssetImage(AdventureWorldBackdrop.assetFor(index))'));
    final falling=File('lib/screens/falling_blocks_screen.dart').readAsStringSync();
    expect(falling, contains('AdventureWorldBackdrop(world: _quest!.mission.world, theme: _theme)'));
    expect(File('lib/screens/game_screen.dart').readAsStringSync(),
      isNot(contains('AdventureWorldBackdrop(')));
  });
}
