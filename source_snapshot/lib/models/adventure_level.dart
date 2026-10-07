class AdventureLevel {
  const AdventureLevel({
    required this.number,
    required this.targetScore,
    required this.reward,
    required this.startingBlocks,
    required this.scoreMultiplier,
    required this.hardPieces,
    this.durationSeconds,
  });

  final int number;
  final int targetScore;
  final int reward;
  final int startingBlocks;
  final double scoreMultiplier;
  final bool hardPieces;
  final int? durationSeconds;

  int get chapter => ((number - 1) ~/ 10) + 1;

  String get title => 'BÖLÜM $number';

  String get difficultyLabel {
    if (hardPieces) return 'ZOR';
    if (durationSeconds != null) return 'HIZ';
    return 'KLASİK';
  }

  int get fallingTargetScore => targetScore;

  int get fallingTargetLines =>
      (5 + ((number - 1) ~/ 5)).clamp(5, 18).toInt();

  int get fallingIntervalMs {
    final step = number - 1;
    final chapterPenalty = (chapter - 1) * 12;
    return (710 - step * 9 - chapterPenalty).clamp(135, 710).toInt();
  }

  int get colorCycle => (number - 1) % 7;

  String get objective =>
      '$fallingTargetScore puana ulaş • hız ve renk her bölüm değişir';
}

const int adventureLevelCount = 60;

AdventureLevel adventureLevelFor(int number) {
  final safe = number.clamp(1, adventureLevelCount).toInt();
  final hard = safe % 5 == 0;
  final timed = safe % 3 == 0;
  final chapter = ((safe - 1) ~/ 10) + 1;
  final step = safe - 1;
  final target = 1000 + step * 650 + step * step * 6 + (chapter - 1) * 500;
  final duration = timed
      ? (190 - chapter * 8 - (hard ? 10 : 0)).clamp(125, 190).toInt()
      : null;
  return AdventureLevel(
    number: safe,
    targetScore: target,
    reward: 35 + safe * 5 + (hard ? 40 : 0),
    startingBlocks:
        (4 + chapter * 2 + (safe ~/ 4) + (hard ? 4 : 0)).clamp(4, 32).toInt(),
    scoreMultiplier: hard ? 1.22 : (timed ? 1.08 : 1.0),
    hardPieces: hard,
    durationSeconds: duration,
  );
}

final List<AdventureLevel> adventureLevels = List<AdventureLevel>.unmodifiable(
  List<AdventureLevel>.generate(
    adventureLevelCount,
    (index) => adventureLevelFor(index + 1),
  ),
);
