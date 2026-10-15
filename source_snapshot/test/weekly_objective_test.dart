import 'package:flutter_test/flutter_test.dart';
import 'package:elxvro_blocks/models/weekly_objective.dart';

void main() {
  test('weekly missions are incomplete with no games', () {
    final missions = weeklyObjectives(games: 0, totalScore: 0, bestScore: 0);
    expect(missions.length, 3);
    expect(missions.every((mission) => !mission.completed), isTrue);
    expect(missions.every((mission) => mission.fraction == 0), isTrue);
  });

  test('weekly missions complete at thresholds', () {
    final missions = weeklyObjectives(games: 10, totalScore: 15000, bestScore: 5000);
    expect(missions.every((mission) => mission.completed), isTrue);
    expect(missions.every((mission) => mission.fraction == 1), isTrue);
  });

  test('progress is capped at one', () {
    final missions = weeklyObjectives(games: 100, totalScore: 99999, bestScore: 20000);
    expect(missions.every((mission) => mission.fraction == 1), isTrue);
  });
}
