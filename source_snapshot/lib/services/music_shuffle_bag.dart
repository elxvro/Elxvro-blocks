import 'dart:math';

class MusicShuffleBag {
  MusicShuffleBag(
    Iterable<String> tracks, {
    Random? random,
  })  : _tracks = List<String>.unmodifiable(tracks),
        _random = random ?? Random();

  final List<String> _tracks;
  final Random _random;
  final List<String> _bag = <String>[];
  String? _lastReturned;

  String? takeNext() {
    if (_tracks.isEmpty) return null;
    if (_bag.isEmpty) _refill();
    if (_bag.isEmpty) return null;

    final next = _bag.removeAt(0);
    _lastReturned = next;
    return next;
  }

  void skipForCurrentBag(String track) {
    _bag.removeWhere((candidate) => candidate == track);
  }

  String? peekNextForTest() {
    if (_tracks.isEmpty) return null;
    if (_bag.isEmpty) _refill();
    return _bag.isEmpty ? null : _bag.first;
  }

  void _refill() {
    _bag
      ..clear()
      ..addAll(_tracks);

    if (_bag.length > 1) {
      _bag.shuffle(_random);
      if (_lastReturned != null && _bag.first == _lastReturned) {
        final swapIndex = 1 + _random.nextInt(_bag.length - 1);
        final first = _bag.first;
        _bag[0] = _bag[swapIndex];
        _bag[swapIndex] = first;
      }
    }
  }
}
