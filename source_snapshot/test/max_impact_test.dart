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

  test('MAX IMPACT crystal burst is much larger and faster', () {
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

    expect(burst.particles.length, greaterThanOrEqualTo(280));
    expect(burst.particles.length, lessThanOrEqualTo(360));
    expect(avgSpeed, greaterThan(2.2));
    expect(avgSize, greaterThan(0.9));
    expect(burst.shakeAmplitude, greaterThan(1.2));
  });

  test('performance mode still limits MAX IMPACT load', () {
    final burst = buildFractureBurst(
      clearedCells: cells,
      material: ThemeMaterial.crystal,
      lineCount: 4,
      performanceMode: true,
      seed: 1701,
    );
    expect(burst.particles.length, lessThanOrEqualTo(100));
    expect(burst.particles, isNotEmpty);
  });

  test('MAX IMPACT block painter has stronger surface light and outer glow', () {
    final source = File('lib/widgets/themed_block_tile.dart').readAsStringSync();
    expect(source, contains('_paintOuterGlow(canvas, size);'));
    expect(source, contains('Colors.white.withValues(alpha: 0.46)'));
    expect(source, contains('ThemeMaterial.glass => 0.68'));
    expect(source, contains('ThemeMaterial.crystal => 0.74'));
    expect(source, contains('blurRadius'));
  });
}
