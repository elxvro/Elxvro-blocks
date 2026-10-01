import 'dart:math';

import '../game/board_engine.dart';
import '../models/game_theme.dart';

enum FractureShape { shard, chip, splinter, flake }

class FractureParticle {
  const FractureParticle({
    required this.cell,
    required this.vx,
    required this.vy,
    required this.size,
    required this.spin,
    required this.gravity,
    required this.lifetimeMs,
    required this.shape,
    required this.sparkle,
  });

  final BoardCell cell;
  final double vx;
  final double vy;
  final double size;
  final double spin;
  final double gravity;
  final int lifetimeMs;
  final FractureShape shape;
  final bool sparkle;
}

class FractureBurst {
  const FractureBurst({
    required this.particles,
    required this.flashStrength,
    required this.shakeAmplitude,
    required this.dustStrength,
  });

  final List<FractureParticle> particles;
  final double flashStrength;
  final double shakeAmplitude;
  final double dustStrength;

  static const FractureBurst empty = FractureBurst(
    particles: <FractureParticle>[],
    flashStrength: 0,
    shakeAmplitude: 0,
    dustStrength: 0,
  );
}

FractureBurst buildFractureBurst({
  required List<BoardCell> clearedCells,
  required ThemeMaterial material,
  required int lineCount,
  required bool performanceMode,
  int? seed,
}) {
  if (clearedCells.isEmpty) return FractureBurst.empty;

  final random = Random(seed);
  final profile = _profileFor(material);
  final safeLines = lineCount.clamp(1, 4);
  final lineFactor = switch (safeLines) {
    1 => 1.0,
    2 => 1.35,
    _ => 1.65,
  };
  final performanceFactor = performanceMode ? 0.42 : 1.0;
  final maxParticles = performanceMode ? 72 : 180;
  final requestedPerCell = max(
    1,
    (profile.particlesPerCell * lineFactor * performanceFactor).round(),
  );
  final particles = <FractureParticle>[];

  for (final cell in clearedCells) {
    for (var i = 0; i < requestedPerCell; i++) {
      if (particles.length >= maxParticles) break;
      final speed = profile.speed * (0.72 + random.nextDouble() * 0.58);
      final angle = -pi * (0.12 + random.nextDouble() * 0.76);
      particles.add(
        FractureParticle(
          cell: cell,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed - profile.lift * random.nextDouble(),
          size: profile.size * (0.72 + random.nextDouble() * 0.52),
          spin: (random.nextDouble() * 2 - 1) * profile.spin,
          gravity: profile.gravity,
          lifetimeMs: (profile.lifetimeMs * (0.86 + random.nextDouble() * 0.28)).round(),
          shape: profile.shape,
          sparkle: profile.sparkle && random.nextDouble() < profile.sparkleChance,
        ),
      );
    }
    if (particles.length >= maxParticles) break;
  }

  final lineImpact = switch (safeLines) {
    1 => 0.34,
    2 => 0.58,
    _ => 0.90,
  };
  final shakeScale = performanceMode ? 0.45 : 1.0;
  final flash = (lineImpact * profile.flashScale).clamp(0.0, 1.0).toDouble();
  final shake = lineImpact * profile.shakeScale * shakeScale;
  final dust = (profile.dustStrength * lineFactor * (performanceMode ? 0.55 : 1.0))
      .clamp(0.0, 1.0)
      .toDouble();

  return FractureBurst(
    particles: List<FractureParticle>.unmodifiable(particles),
    flashStrength: flash,
    shakeAmplitude: shake,
    dustStrength: dust,
  );
}

class _FractureProfile {
  const _FractureProfile({
    required this.particlesPerCell,
    required this.size,
    required this.speed,
    required this.lift,
    required this.spin,
    required this.gravity,
    required this.lifetimeMs,
    required this.shape,
    required this.sparkle,
    required this.sparkleChance,
    required this.flashScale,
    required this.shakeScale,
    required this.dustStrength,
  });

  final int particlesPerCell;
  final double size;
  final double speed;
  final double lift;
  final double spin;
  final double gravity;
  final int lifetimeMs;
  final FractureShape shape;
  final bool sparkle;
  final double sparkleChance;
  final double flashScale;
  final double shakeScale;
  final double dustStrength;
}

_FractureProfile _profileFor(ThemeMaterial material) {
  switch (material) {
    case ThemeMaterial.glass:
      return const _FractureProfile(
        particlesPerCell: 4,
        size: 0.64,
        speed: 1.55,
        lift: 0.70,
        spin: 2.4,
        gravity: 1.05,
        lifetimeMs: 620,
        shape: FractureShape.shard,
        sparkle: true,
        sparkleChance: 0.36,
        flashScale: 1.18,
        shakeScale: 0.82,
        dustStrength: 0.08,
      );
    case ThemeMaterial.crystal:
      return const _FractureProfile(
        particlesPerCell: 5,
        size: 0.72,
        speed: 1.68,
        lift: 0.76,
        spin: 2.7,
        gravity: 1.00,
        lifetimeMs: 760,
        shape: FractureShape.shard,
        sparkle: true,
        sparkleChance: 0.62,
        flashScale: 1.28,
        shakeScale: 0.90,
        dustStrength: 0.05,
      );
    case ThemeMaterial.stone:
      return const _FractureProfile(
        particlesPerCell: 3,
        size: 1.30,
        speed: 0.82,
        lift: 0.44,
        spin: 1.1,
        gravity: 2.00,
        lifetimeMs: 520,
        shape: FractureShape.chip,
        sparkle: false,
        sparkleChance: 0,
        flashScale: 0.82,
        shakeScale: 1.30,
        dustStrength: 0.74,
      );
    case ThemeMaterial.marble:
      return const _FractureProfile(
        particlesPerCell: 4,
        size: 1.12,
        speed: 0.92,
        lift: 0.48,
        spin: 1.3,
        gravity: 1.70,
        lifetimeMs: 580,
        shape: FractureShape.chip,
        sparkle: true,
        sparkleChance: 0.12,
        flashScale: 0.92,
        shakeScale: 1.22,
        dustStrength: 0.66,
      );
    case ThemeMaterial.wood:
      return const _FractureProfile(
        particlesPerCell: 4,
        size: 0.94,
        speed: 1.08,
        lift: 0.60,
        spin: 1.9,
        gravity: 1.25,
        lifetimeMs: 650,
        shape: FractureShape.splinter,
        sparkle: false,
        sparkleChance: 0,
        flashScale: 0.88,
        shakeScale: 0.92,
        dustStrength: 0.30,
      );
    case ThemeMaterial.leaf:
      return const _FractureProfile(
        particlesPerCell: 4,
        size: 0.84,
        speed: 1.12,
        lift: 0.82,
        spin: 1.6,
        gravity: 0.45,
        lifetimeMs: 900,
        shape: FractureShape.flake,
        sparkle: false,
        sparkleChance: 0,
        flashScale: 0.72,
        shakeScale: 0.54,
        dustStrength: 0.10,
      );
  }
}
