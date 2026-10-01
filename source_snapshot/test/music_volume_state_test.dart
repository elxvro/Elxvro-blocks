import 'package:flutter_test/flutter_test.dart';
import 'package:elxvro_blocks/services/music_volume_state.dart';

void main() {
  test('effective music volume multiplies user duck and transition gains', () {
    expect(
      calculateEffectiveMusicVolume(
        userVolume: 0.8,
        duckFactor: 0.5,
        transitionGain: 0.25,
      ),
      closeTo(0.1, 0.0001),
    );
  });

  test('effective music volume clamps each input to safe range', () {
    expect(
      calculateEffectiveMusicVolume(
        userVolume: 2,
        duckFactor: -1,
        transitionGain: 4,
      ),
      0,
    );
  });

  test('full transition gain preserves normal ducked volume', () {
    expect(
      calculateEffectiveMusicVolume(
        userVolume: 0.2,
        duckFactor: 1,
        transitionGain: 1,
      ),
      closeTo(0.2, 0.0001),
    );
  });
}
