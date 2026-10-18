/// Converts drag pixels into bounded board steps without discarding remainder.
class DragSteps {
  const DragSteps(this.horizontal, this.downward);
  final int horizontal;
  final int downward;
}

class DragStepAccumulator {
  static const double horizontalThreshold = 23;
  static const double downwardThreshold = 28;
  static const int maxStepsPerEvent = 6;
  double _horizontal = 0;
  double _vertical = 0;

  DragSteps update(double dx, double dy) {
    if (!dx.isFinite || !dy.isFinite) {
      reset();
      return const DragSteps(0, 0);
    }
    _horizontal = (_horizontal + dx).clamp(
      -horizontalThreshold * (maxStepsPerEvent + 1),
      horizontalThreshold * (maxStepsPerEvent + 1),
    ).toDouble();
    _vertical = (_vertical + dy).clamp(
      -downwardThreshold * (maxStepsPerEvent + 1),
      downwardThreshold * (maxStepsPerEvent + 1),
    ).toDouble();
    final horizontal = (_horizontal / horizontalThreshold)
        .truncate().clamp(-maxStepsPerEvent, maxStepsPerEvent).toInt();
    _horizontal -= horizontal * horizontalThreshold;
    final downward = (_vertical / downwardThreshold)
        .truncate().clamp(0, maxStepsPerEvent).toInt();
    if (downward > 0) _vertical -= downward * downwardThreshold;
    if (_vertical <= -40) _vertical = 0;
    return DragSteps(horizontal, downward);
  }

  void reset() {
    _horizontal = 0;
    _vertical = 0;
  }
}
