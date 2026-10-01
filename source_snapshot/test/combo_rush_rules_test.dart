import 'package:flutter_test/flutter_test.dart';
import 'package:elxvro_blocks/game/combo_rush_rules.dart';

void main() {
  test('combo multiplier uses bounded tiers', () {
    expect(comboRushMultiplier(0), 1.0);
    expect(comboRushMultiplier(1), 1.0);
    expect(comboRushMultiplier(2), 1.15);
    expect(comboRushMultiplier(3), 1.30);
    expect(comboRushMultiplier(4), 1.50);
    expect(comboRushMultiplier(5), 1.75);
    expect(comboRushMultiplier(50), 1.75);
  });

  test('scoring clear increments combo and empty clear resets it', () {
    expect(nextComboRushCombo(currentCombo: 0, clearedAnyLine: true), 1);
    expect(nextComboRushCombo(currentCombo: 4, clearedAnyLine: true), 5);
    expect(nextComboRushCombo(currentCombo: 7, clearedAnyLine: false), 0);
  });

  test('score multiplier rounds to nearest integer and never goes negative', () {
    expect(applyComboRushMultiplier(baseScore: 1000, combo: 2), 1150);
    expect(applyComboRushMultiplier(baseScore: 1000, combo: 5), 1750);
    expect(applyComboRushMultiplier(baseScore: -50, combo: 5), 0);
  });
}
