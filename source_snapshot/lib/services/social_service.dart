class SocialConnectionInfo {
  const SocialConnectionInfo({
    required this.connected,
    required this.provider,
    required this.message,
  });

  final bool connected;
  final String provider;
  final String message;
}

abstract interface class SocialService {
  Future<SocialConnectionInfo> connectionInfo();

  Future<bool> signIn();

  Future<void> submitScore({
    required String leaderboardId,
    required int score,
  });

  Future<void> unlockAchievement({required String achievementId});

  Future<void> showLeaderboards();

  Future<void> showAchievements();
}

/// Offline implementation used when Play Games is unavailable or not yet
/// configured. Every remote action is intentionally a safe no-op so gameplay
/// and local progress never depend on a network/account connection.
class LocalSocialService implements SocialService {
  const LocalSocialService();

  @override
  Future<SocialConnectionInfo> connectionInfo() async {
    return const SocialConnectionInfo(
      connected: false,
      provider: 'Google Play Games',
      message: 'Play Games bağlı değil. Yerel kayıtlar kullanılmaya devam eder.',
    );
  }

  @override
  Future<bool> signIn() async => false;

  @override
  Future<void> submitScore({
    required String leaderboardId,
    required int score,
  }) async {}

  @override
  Future<void> unlockAchievement({required String achievementId}) async {}

  @override
  Future<void> showLeaderboards() async {}

  @override
  Future<void> showAchievements() async {}
}
