import 'package:flutter_test/flutter_test.dart';
import 'package:elxvro_blocks/effects/fracture_effect.dart';
import 'package:elxvro_blocks/game/board_engine.dart';
import 'package:elxvro_blocks/models/game_theme.dart';

void main() {
  const cells = <BoardCell>[
    BoardCell(2, 1),
    BoardCell(2, 2),
    BoardCell(2, 3),
    BoardCell(2, 4),
  ];

  test('empty clear list creates no fracture burst', () {
    final burst = buildFractureBurst(
      clearedCells: const <BoardCell>[],
      material: ThemeMaterial.glass,
      lineCount: 1,
      performanceMode: false,
      seed: 7,
    );
    expect(burst.particles, isEmpty);
    expect(burst.shakeAmplitude, 0);
    expect(burst.flashStrength, 0);
  });

  test('particles reference only resolved clear cells', () {
    final burst = buildFractureBurst(
      clearedCells: cells,
      material: ThemeMaterial.crystal,
      lineCount: 2,
      performanceMode: false,
      seed: 11,
    );
    expect(burst.particles, isNotEmpty);
    expect(burst.particles.every((p) => cells.contains(p.cell)), isTrue);
  });

  test('glass shards are smaller than stone chips', () {
    final glass = buildFractureBurst(
      clearedCells: cells,
      material: ThemeMaterial.glass,
      lineCount: 1,
      performanceMode: false,
      seed: 19,
    );
    final stone = buildFractureBurst(
      clearedCells: cells,
      material: ThemeMaterial.stone,
      lineCount: 1,
      performanceMode: false,
      seed: 19,
    );
    final glassAvg = glass.particles.map((p) => p.size).reduce((a, b) => a + b) /
        glass.particles.length;
    final stoneAvg = stone.particles.map((p) => p.size).reduce((a, b) => a + b) /
        stone.particles.length;
    expect(glassAvg, lessThan(stoneAvg));
    expect(glass.particles.every((p) => p.shape == FractureShape.shard), isTrue);
    expect(stone.particles.every((p) => p.shape == FractureShape.chip), isTrue);
  });

  test('leaf particles drift longer with lower gravity than stone', () {
    final leaf = buildFractureBurst(
      clearedCells: cells,
      material: ThemeMaterial.leaf,
      lineCount: 1,
      performanceMode: false,
      seed: 23,
    );
    final stone = buildFractureBurst(
      clearedCells: cells,
      material: ThemeMaterial.stone,
      lineCount: 1,
      performanceMode: false,
      seed: 23,
    );
    expect(leaf.particles.first.gravity, lessThan(stone.particles.first.gravity));
    expect(leaf.particles.first.lifetimeMs, greaterThan(stone.particles.first.lifetimeMs));
    expect(leaf.particles.every((p) => p.shape == FractureShape.flake), isTrue);
  });

  test('performance mode reduces particle count and shake', () {
    final full = buildFractureBurst(
      clearedCells: cells,
      material: ThemeMaterial.marble,
      lineCount: 3,
      performanceMode: false,
      seed: 31,
    );
    final reduced = buildFractureBurst(
      clearedCells: cells,
      material: ThemeMaterial.marble,
      lineCount: 3,
      performanceMode: true,
      seed: 31,
    );
    expect(reduced.particles.length, lessThan(full.particles.length));
    expect(reduced.particles, isNotEmpty);
    expect(reduced.shakeAmplitude, lessThan(full.shakeAmplitude));
    expect(full.particles.length, lessThanOrEqualTo(220));
    expect(reduced.particles.length, lessThanOrEqualTo(72));
  });
}
