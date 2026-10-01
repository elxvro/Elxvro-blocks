import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:elxvro_blocks/effects/fracture_effect.dart';
import 'package:elxvro_blocks/game/board_engine.dart';
import 'package:elxvro_blocks/models/game_theme.dart';

void main() {
  final cells = List<BoardCell>.generate(
    20,
    (index) => BoardCell(index ~/ 10, index % 10),
  );

  test('MAX IMPACT crystal burst stays bold inside the smooth budget', () {
    final burst = buildFractureBurst(
      clearedCells: cells,
      material: ThemeMaterial.crystal,
      lineCount: 4,
      performanceMode: false,
      seed: 1701,
    );

    final avgSpeed = burst.particles
            .map((p) => sqrt(p.vx * p.vx + p.vy * p.vy))
            .reduce((a, b) => a + b) /
        burst.particles.length;
    final avgSize = burst.particles.map((p) => p.size).reduce((a, b) => a + b) /
        burst.particles.length;

    expect(burst.particles.length, greaterThanOrEqualTo(160));
    expect(burst.particles.length, lessThanOrEqualTo(220));
    expect(avgSpeed, greaterThan(2.0));
    expect(avgSize, greaterThan(0.85));
    expect(burst.shakeAmplitude, greaterThan(1.0));
  });

  test('performance mode tightly limits MAX IMPACT load', () {
    final burst = buildFractureBurst(
      clearedCells: cells,
      material: ThemeMaterial.crystal,
      lineCount: 4,
      performanceMode: true,
      seed: 1701,
    );
    expect(burst.particles.length, lessThanOrEqualTo(72));
    expect(burst.particles, isNotEmpty);
  });

  test('MAX IMPACT block painter keeps stronger surface light without halo blur', () {
    final source = File('lib/widgets/themed_block_tile.dart').readAsStringSync();
    expect(source, contains('_paintOuterGlow(canvas, size);'));
    expect(source, contains('Colors.white.withValues(alpha: 0.46)'));
    expect(source, contains('ThemeMaterial.glass => 0.68'));
    expect(source, contains('ThemeMaterial.crystal => 0.74'));

    final start = source.indexOf('void _paintOuterGlow');
    final end = source.indexOf('void _paintContactShadow', start);
    expect(source.substring(start, end), isNot(contains('MaskFilter.blur')));
  });
}
