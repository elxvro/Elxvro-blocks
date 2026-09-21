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
}

/// Offline implementation used until Google Play Console credentials,
/// leaderboards and achievements are configured for the release package.
class LocalSocialService implements SocialService {
  const LocalSocialService();

  @override
  Future<SocialConnectionInfo> connectionInfo() async {
    return const SocialConnectionInfo(
      connected: false,
      provider: 'Google Play Games',
      message: 'Play Console bağlantısı bekleniyor. Oyun çevrimdışı çalışmaya devam eder.',
    );
  }

  @override
  Future<bool> signIn() async => false;

  @override
  Future<void> submitScore({
    required String leaderboardId,
    required int score,
  }) async {
    // Intentionally no-op in the offline adapter. The same interface can be
    // replaced by the Play Games implementation without touching gameplay.
  }
}
