double comboRushMultiplier(int combo) {
  if (combo >= 5) return 1.75;
  if (combo == 4) return 1.50;
  if (combo == 3) return 1.30;
  if (combo == 2) return 1.15;
  return 1.0;
}

int nextComboRushCombo({
  required int currentCombo,
  required bool clearedAnyLine,
}) {
  if (!clearedAnyLine) return 0;
  return currentCombo < 0 ? 1 : currentCombo + 1;
}

int applyComboRushMultiplier({
  required int baseScore,
  required int combo,
}) {
  final safeBase = baseScore < 0 ? 0 : baseScore;
  return (safeBase * comboRushMultiplier(combo)).round();
}
