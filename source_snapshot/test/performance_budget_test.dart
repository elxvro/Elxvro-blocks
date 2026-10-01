import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:elxvro_blocks/effects/fracture_effect.dart';
import 'package:elxvro_blocks/game/board_engine.dart';
import 'package:elxvro_blocks/models/game_theme.dart';

void main() {
  final largeClear = List<BoardCell>.generate(
    20,
    (index) => BoardCell(index ~/ 10, index % 10),
  );

  test('large crystal clear stays inside the smooth-effect particle budget', () {
    final burst = buildFractureBurst(
      clearedCells: largeClear,
      material: ThemeMaterial.crystal,
      lineCount: 4,
      performanceMode: false,
      seed: 172,
    );

    expect(burst.particles.length, lessThanOrEqualTo(220));
    expect(burst.particles.length, greaterThanOrEqualTo(120));
  });

  test('game screen caps simultaneously painted fracture particles', () {
    final source = File('lib/screens/game_screen.dart').readAsStringSync();
    expect(source, contains('maxVisibleParticles'));
    expect(source, contains('.take(maxVisibleParticles)'));
  });

  test('regular tile outer glow avoids per-tile blur filters', () {
    final source = File('lib/widgets/themed_block_tile.dart').readAsStringSync();
    final start = source.indexOf('void _paintOuterGlow');
    final end = source.indexOf('void _paintContactShadow', start);

    expect(start, greaterThanOrEqualTo(0));
    expect(end, greaterThan(start));

    final glowBody = source.substring(start, end);
    expect(glowBody, isNot(contains('MaskFilter.blur')));
  });
}
