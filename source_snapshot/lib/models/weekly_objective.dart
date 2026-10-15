/// Weekly objectives derived from the existing persisted weekly counters.
/// Does not change game scoring, saves or the one-time supporter purchase.
class WeeklyObjective {
  const WeeklyObjective({
    required this.id,
    required this.title,
    required this.progress,
    required this.target,
    required this.reward,
  });

  final String id;
  final String title;
  final int progress;
  final int target;
  final int reward;

  bool get completed => progress >= target;
  double get fraction => (progress / target).clamp(0.0, 1.0).toDouble();
}

List<WeeklyObjective> weeklyObjectives({
  required int games,
  required int totalScore,
  required int bestScore,
}) => <WeeklyObjective>[
  WeeklyObjective(
    id: 'weekly_games_10',
    title: '10 oyun tamamla',
    progress: games,
    target: 10,
    reward: 100,
  ),
  WeeklyObjective(
    id: 'weekly_score_15000',
    title: '15.000 haftalık puan topla',
    progress: totalScore,
    target: 15000,
    reward: 150,
  ),
  WeeklyObjective(
    id: 'weekly_best_5000',
    title: 'Tek oyunda 5.000 puana ulaş',
    progress: bestScore,
    target: 5000,
    reward: 200,
  ),
];
