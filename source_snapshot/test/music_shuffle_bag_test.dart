import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:elxvro_blocks/services/music_shuffle_bag.dart';

void main() {
  const tracks = <String>['a', 'b', 'c', 'd', 'e', 'f'];

  test('plays every track once before repeating', () {
    final bag = MusicShuffleBag(tracks, random: Random(7));
    final firstBag = List<String>.generate(6, (_) => bag.takeNext()!);

    expect(firstBag.toSet(), tracks.toSet());
    expect(firstBag.length, 6);
  });

  test('new bag first track differs from previous last track', () {
    final bag = MusicShuffleBag(tracks, random: Random(11));
    final first = List<String>.generate(6, (_) => bag.takeNext()!);
    final firstOfSecondBag = bag.takeNext();

    expect(firstOfSecondBag, isNot(first.last));
  });

  test('skipped track is not returned again in current bag', () {
    final bag = MusicShuffleBag(tracks, random: Random(19));
    final first = bag.takeNext()!;
    final nextCandidate = bag.peekNextForTest();
    expect(nextCandidate, isNotNull);

    bag.skipForCurrentBag(nextCandidate!);
    final rest = <String>[];
    for (var i = 0; i < 4; i++) {
      rest.add(bag.takeNext()!);
    }

    expect(rest, isNot(contains(nextCandidate)));
    expect(first, isNotEmpty);
  });

  test('empty playlist returns null', () {
    final bag = MusicShuffleBag(const <String>[]);
    expect(bag.takeNext(), isNull);
  });

  test('single-track playlist remains usable', () {
    final bag = MusicShuffleBag(const <String>['solo'], random: Random(2));
    expect(bag.takeNext(), 'solo');
    expect(bag.takeNext(), 'solo');
  });
}
