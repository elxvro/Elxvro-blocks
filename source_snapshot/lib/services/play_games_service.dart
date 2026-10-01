import 'package:flutter/foundation.dart';
import 'package:games_services/games_services.dart';

import 'play_games_ids.dart';
import 'social_service.dart';

abstract interface class GamesPlatformAdapter {
  Future<bool> signIn();

  Future<void> submitScore({
    required String leaderboardId,
    required int score,
  });

  Future<void> unlockAchievement(String achievementId);

  Future<void> showLeaderboards();

  Future<void> showAchievements();
}

class GamesServicesPlatformAdapter implements GamesPlatformAdapter {
  const GamesServicesPlatformAdapter();

  @override
  Future<bool> signIn() async {
    await GamesServices.signIn();
    return GamesServices.isSignedIn;
  }

  @override
  Future<void> submitScore({
    required String leaderboardId,
    required int score,
  }) async {
    await GamesServices.submitScore(
      score: Score(
        androidID: leaderboardId,
        value: score,
      ),
    );
  }

  @override
  Future<void> unlockAchievement(String achievementId) async {
    await GamesServices.unlock(
      achievement: Achievement(
        androidID: achievementId,
        percentComplete: 100,
      ),
    );
  }

  @override
  Future<void> showLeaderboards() async {
    await GamesServices.showLeaderboards();
  }

  @override
  Future<void> showAchievements() async {
    await GamesServices.showAchievements();
  }
}

class PlayGamesService implements SocialService {
  PlayGamesService({
    required this.ids,
    GamesPlatformAdapter? adapter,
  }) : _adapter = adapter ?? const GamesServicesPlatformAdapter();

  factory PlayGamesService.production() => PlayGamesService(
        ids: const PlayGamesIds.fromEnvironment(),
      );

  final PlayGamesIds ids;
  final GamesPlatformAdapter _adapter;

  bool _connected = false;
  bool _signInAttempted = false;
  String? _lastError;

  @override
  Future<SocialConnectionInfo> connectionInfo() async {
    if (_connected) {
      return const SocialConnectionInfo(
        connected: true,
        provider: 'Google Play Games',
        message: 'Google Play Games bağlı. Skor ve başarımlar senkronize edilebilir.',
      );
    }

    return SocialConnectionInfo(
      connected: false,
      provider: 'Google Play Games',
      message: _lastError == null
          ? ids.hasAnyRemoteConfiguration
              ? 'Play Games bağlantısı hazır. Yerel kayıtlar çevrimdışı da korunur.'
              : 'Play Games kimlikleri henüz yapılandırılmadı. Yerel kayıtlar kullanılmaya devam eder.'
          : 'Play Games bağlantısı kurulamadı. Oyun çevrimdışı çalışmaya devam eder.',
    );
  }

  @override
  Future<bool> signIn() async {
    _signInAttempted = true;
    try {
      _connected = await _adapter.signIn();
      _lastError = _connected ? null : 'not_connected';
      return _connected;
    } catch (error, stackTrace) {
      _connected = false;
      _lastError = error.toString();
      debugPrint('ELXVRO Play Games sign-in failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> _ensureConnected() async {
    if (_connected) return true;
    if (_signInAttempted && _lastError != null) {
      // Explicit UI actions may call signIn() again; background synchronization
      // should not repeatedly interrupt the player after a failed attempt.
      return false;
    }
    return signIn();
  }

  @override
  Future<void> submitScore({
    required String leaderboardId,
    required int score,
  }) async {
    final id = leaderboardId.trim();
    if (id.isEmpty) return;
    if (!await _ensureConnected()) return;
    try {
      await _adapter.submitScore(
        leaderboardId: id,
        score: score < 0 ? 0 : score,
      );
    } catch (error, stackTrace) {
      _lastError = error.toString();
      debugPrint('ELXVRO Play Games score sync failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Future<void> unlockAchievement({required String achievementId}) async {
    final id = achievementId.trim();
    if (id.isEmpty) return;
    if (!await _ensureConnected()) return;
    try {
      await _adapter.unlockAchievement(id);
    } catch (error, stackTrace) {
      _lastError = error.toString();
      debugPrint('ELXVRO Play Games achievement sync failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Future<void> showLeaderboards() async {
    try {
      if (!await _ensureConnected()) return;
      await _adapter.showLeaderboards();
    } catch (error, stackTrace) {
      _lastError = error.toString();
      debugPrint('ELXVRO Play Games leaderboard UI failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Future<void> showAchievements() async {
    try {
      if (!await _ensureConnected()) return;
      await _adapter.showAchievements();
    } catch (error, stackTrace) {
      _lastError = error.toString();
      debugPrint('ELXVRO Play Games achievements UI failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
