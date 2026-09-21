enum GameMode {
  classic,
  timed,
  target,
  daily,
  zen,
  hard,
}

class GameModeData {
  const GameModeData({
    required this.mode,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    this.durationSeconds,
    this.targetScore,
    this.completionReward = 0,
    this.scoreMultiplier = 1.0,
    this.specialChance = 0.13,
    this.zenRecovery = false,
    this.hardPieces = false,
  });

  final GameMode mode;
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final int? durationSeconds;
  final int? targetScore;
  final int completionReward;
  final double scoreMultiplier;
  final double specialChance;
  final bool zenRecovery;
  final bool hardPieces;

  bool get hasTimer => durationSeconds != null;
  bool get hasTarget => targetScore != null;
}

const Map<GameMode, GameModeData> gameModeData = <GameMode, GameModeData>{
  GameMode.classic: GameModeData(
    mode: GameMode.classic,
    id: 'classic',
    title: 'KLASİK',
    subtitle: 'Sınırsız oyun',
    description: 'Hamle kalmayana kadar oyna ve kendi rekorunu geliştir.',
  ),
  GameMode.timed: GameModeData(
    mode: GameMode.timed,
    id: 'timed',
    title: '2 DAKİKA',
    subtitle: 'Hız modu',
    description: '120 saniye içinde mümkün olan en yüksek skoru yap.',
    durationSeconds: 120,
    completionReward: 25,
  ),
  GameMode.target: GameModeData(
    mode: GameMode.target,
    id: 'target',
    title: 'HEDEF 5000',
    subtitle: 'Skor meydan okuması',
    description: 'Hamlelerin bitmeden 5.000 puana ulaş.',
    targetScore: 5000,
    completionReward: 60,
  ),
  GameMode.daily: GameModeData(
    mode: GameMode.daily,
    id: 'daily',
    title: 'GÜNLÜK CHALLENGE',
    subtitle: 'Her gün yeni tahta',
    description: '3 dakika içinde 3.500 puana ulaş. Günlük ödül bir kez alınır.',
    durationSeconds: 180,
    targetScore: 3500,
    completionReward: 150,
  ),
  GameMode.zen: GameModeData(
    mode: GameMode.zen,
    id: 'zen',
    title: 'ZEN',
    subtitle: 'Rahat ve kesintisiz',
    description: 'Süre yok. Hamle tıkanırsa tahta nefes alır ve oyun devam eder.',
    scoreMultiplier: 0.85,
    specialChance: 0.18,
    zenRecovery: true,
  ),
  GameMode.hard: GameModeData(
    mode: GameMode.hard,
    id: 'hard',
    title: 'ZOR MOD',
    subtitle: 'Büyük parçalar • az güç',
    description: 'Dolu bir tahtada daha büyük şekillerle mümkün olduğunca uzun dayan.',
    scoreMultiplier: 1.35,
    specialChance: 0.05,
    hardPieces: true,
  ),
};
