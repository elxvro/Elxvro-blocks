double calculateEffectiveMusicVolume({
  required double userVolume,
  required double duckFactor,
  required double transitionGain,
}) {
  final user = userVolume.clamp(0.0, 1.0).toDouble();
  final duck = duckFactor.clamp(0.0, 1.0).toDouble();
  final transition = transitionGain.clamp(0.0, 1.0).toDouble();
  return (user * duck * transition).clamp(0.0, 1.0).toDouble();
}
