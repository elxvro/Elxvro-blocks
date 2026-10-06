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

  String get objective {
    final timer = durationSeconds;
    if (timer == null) {
      return '$targetScore puana ulaş';
    }
    return '$timer sn içinde $targetScore puana ulaş';
  }
}

const int adventureLevelCount = 60;

AdventureLevel adventureLevelFor(int number) {
  final safe = number.clamp(1, adventureLevelCount).toInt();
  final hard = safe % 5 == 0;
  final timed = safe % 3 == 0;
  final chapter = ((safe - 1) ~/ 10) + 1;
  final target = 900 + safe * 260 + chapter * 180;
  final duration = timed
      ? (190 - chapter * 8 - (hard ? 10 : 0)).clamp(125, 190).toInt()
      : null;
  return AdventureLevel(
    number: safe,
    targetScore: target,
    reward: 35 + safe * 5 + (hard ? 40 : 0),
    startingBlocks: (6 + chapter * 2 + (hard ? 5 : 0)).clamp(6, 24).toInt(),
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
