import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState extends ChangeNotifier {
  static const String _bestScoreKey = 'best_score';
  static const String _themeKey = 'theme_id';
  static const String _gamesPlayedKey = 'games_played';
  static const String _maxComboKey = 'max_combo';
  static const String _totalScoreKey = 'total_score';
  static const String _totalLinesKey = 'total_lines';
  static const String _totalBlocksKey = 'total_blocks';
  static const String _dailyDateKey = 'daily_date';
  static const String _dailyGamesKey = 'daily_games';
  static const String _dailyLinesKey = 'daily_lines';
  static const String _dailyBestScoreKey = 'daily_best_score';
  static const String _soundEnabledKey = 'sound_enabled';
  static const String _musicEnabledKey = 'music_enabled';
  static const String _sfxVolumeKey = 'sfx_volume';
  static const String _musicVolumeKey = 'music_volume';
  static const String _uiSoundEnabledKey = 'ui_sound_enabled';
  static const String _uiVolumeKey = 'ui_volume';
  static const String _hapticsEnabledKey = 'haptics_enabled';
  static const String _performanceModeKey = 'performance_mode';

  static const String _coinsKey = 'coins';
  static const String _rewardClaimDateKey = 'reward_claim_date';
  static const String _loginStreakKey = 'login_streak';
  static const String _dailyClaimsDateKey = 'daily_claims_date';
  static const String _dailyClaimsKey = 'daily_claims';
  static const String _achievementClaimsKey = 'achievement_claims';
  static const String _unlockedThemesKey = 'unlocked_themes';
  static const String _undoInventoryKey = 'undo_inventory';
  static const String _refreshInventoryKey = 'refresh_inventory';
  static const String _specialInventoryKey = 'special_inventory';
  static const String _timedBestScoreKey = 'timed_best_score';
  static const String _targetBestScoreKey = 'target_best_score';
  static const String _zenBestScoreKey = 'zen_best_score';
  static const String _hardBestScoreKey = 'hard_best_score';
  static const String _dailyChallengeDateKey = 'daily_challenge_date';
  static const String _dailyChallengeBestScoreKey = 'daily_challenge_best_score';
  static const String _dailyChallengeRewardDateKey = 'daily_challenge_reward_date';
  static const String _xpKey = 'xp';
  static const String _perfectClearsKey = 'perfect_clears';
  static const String _tutorialCompletedKey = 'tutorial_completed';
  static const String _playerNameKey = 'player_name';
  static const String _weeklyKeyKey = 'weekly_key';
  static const String _weeklyGamesKey = 'weekly_games';
  static const String _weeklyScoreKey = 'weekly_score';
  static const String _weeklyBestScoreKey = 'weekly_best_score';
  static const String _weeklyRewardClaimKey = 'weekly_reward_claim';

  int bestScore = 0;
  int gamesPlayed = 0;
  int maxCombo = 0;
  int totalScore = 0;
  int totalLines = 0;
  int totalBlocks = 0;

  int dailyGames = 0;
  int dailyLines = 0;
  int dailyBestScore = 0;

  int coins = 0;
  int loginStreak = 0;
  int undoInventory = 0;
  int refreshInventory = 0;
  int specialInventory = 0;
  int timedBestScore = 0;
  int targetBestScore = 0;
  int zenBestScore = 0;
  int hardBestScore = 0;
  int dailyChallengeBestScore = 0;
  int xp = 0;
  int perfectClears = 0;
  bool tutorialCompleted = false;
  int weeklyGames = 0;
  int weeklyScore = 0;
  int weeklyBestScore = 0;
  String playerName = 'ELXVRO PLAYER';
  String _weeklyKey = '';
  String _weeklyRewardClaim = '';
  String _dailyChallengeDate = '';
  String _dailyChallengeRewardDate = '';

  String themeId = 'classic';
  String _lastRewardClaimDate = '';
  final Set<String> _dailyClaims = <String>{};
  final Set<String> _achievementClaims = <String>{};
  final Set<String> _unlockedThemes = <String>{'classic'};

  bool soundEnabled = true;
  bool musicEnabled = true;
  double sfxVolume = 0.74;
  double musicVolume = 0.20;
  bool uiSoundEnabled = true;
  double uiVolume = 0.66;
  Timer? _sfxVolumeSaveTimer;
  Timer? _musicVolumeSaveTimer;
  Timer? _uiVolumeSaveTimer;
  bool hapticsEnabled = true;
  bool performanceMode = false;
  bool isLoaded = false;

  static const int weeklyGoal = 25000;
  static const int weeklyRewardAmount = 250;

  double get weeklyProgress =>
      (weeklyScore / weeklyGoal).clamp(0.0, 1.0).toDouble();

  bool get weeklyRewardAvailable =>
      weeklyScore >= weeklyGoal && _weeklyRewardClaim != _weeklyKey;

  bool get weeklyRewardClaimed => _weeklyRewardClaim == _weeklyKey;

  int get playerLevel {
    var level = 1;
    while (level < 100 && xp >= xpForLevel(level + 1)) {
      level += 1;
    }
    return level;
  }

  int get currentLevelXp => xp - xpForLevel(playerLevel);

  int get currentLevelXpTarget =>
      xpForLevel(playerLevel + 1) - xpForLevel(playerLevel);

  double get levelProgress {
    final target = currentLevelXpTarget;
    if (target <= 0) return 1;
    return (currentLevelXp / target).clamp(0.0, 1.0).toDouble();
  }

  static int xpForLevel(int level) {
    if (level <= 1) return 0;
    var total = 0;
    for (var current = 1; current < level; current++) {
      total += 200 + (current - 1) * 75;
    }
    return total;
  }

  int get completedDailyMissions {
    var completed = 0;
    if (dailyGames >= 1) completed += 1;
    if (dailyLines >= 8) completed += 1;
    if (dailyBestScore >= 2500) completed += 1;
    return completed;
  }

  int get unlockedAchievements {
    var unlocked = 0;
    if (gamesPlayed >= 1) unlocked += 1;
    if (bestScore >= 1000) unlocked += 1;
    if (maxCombo >= 3) unlocked += 1;
    if (totalLines >= 25) unlocked += 1;
    if (gamesPlayed >= 10) unlocked += 1;
    if (totalBlocks >= 250) unlocked += 1;
    if (bestScore >= 10000) unlocked += 1;
    if (playerLevel >= 5) unlocked += 1;
    if (perfectClears >= 3) unlocked += 1;
    if (playerLevel >= 15) unlocked += 1;
    return unlocked;
  }

  bool achievementUnlocked(String id) {
    switch (id) {
      case 'first_game':
        return gamesPlayed >= 1;
      case 'score_1000':
        return bestScore >= 1000;
      case 'combo_3':
        return maxCombo >= 3;
      case 'lines_25':
        return totalLines >= 25;
      case 'games_10':
        return gamesPlayed >= 10;
      case 'blocks_250':
        return totalBlocks >= 250;
      case 'score_10000':
        return bestScore >= 10000;
      case 'level_5':
        return playerLevel >= 5;
      case 'perfect_3':
        return perfectClears >= 3;
      case 'level_15':
        return playerLevel >= 15;
      default:
        return false;
    }
  }

  bool isDailyMissionClaimed(String id) => _dailyClaims.contains(id);

  bool isAchievementClaimed(String id) => _achievementClaims.contains(id);

  bool isThemeUnlocked(String id) => _unlockedThemes.contains(id);

  bool get dailyRewardAvailable =>
      _lastRewardClaimDate != _dayKey(DateTime.now());

  bool get dailyChallengeRewardAvailable =>
      _dailyChallengeRewardDate != _dayKey(DateTime.now());

  int get dailyRewardDay {
    if (!dailyRewardAvailable) {
      return loginStreak <= 0 ? 1 : loginStreak;
    }
    final yesterday = _dayKey(DateTime.now().subtract(const Duration(days: 1)));
    if (_lastRewardClaimDate == yesterday) {
      final next = loginStreak + 1;
      return next > 7 ? 7 : next;
    }
    return 1;
  }

  int get dailyRewardAmount {
    const rewards = <int>[50, 75, 100, 125, 150, 200, 300];
    final day = dailyRewardDay.clamp(1, 7).toInt();
    return rewards[day - 1];
  }

  int themePrice(String id) {
    switch (id) {
      case 'classic':
        return 0;
      case 'night':
        return 300;
      case 'marble':
        return 500;
      case 'fire':
        return 700;
      case 'nature':
        return 700;
      case 'aurora':
        return 1000;
      default:
        return 500;
    }
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      bestScore = prefs.getInt(_bestScoreKey) ?? 0;
      gamesPlayed = prefs.getInt(_gamesPlayedKey) ?? 0;
      maxCombo = prefs.getInt(_maxComboKey) ?? 0;
      totalScore = prefs.getInt(_totalScoreKey) ?? 0;
      totalLines = prefs.getInt(_totalLinesKey) ?? 0;
      totalBlocks = prefs.getInt(_totalBlocksKey) ?? 0;
      themeId = prefs.getString(_themeKey) ?? 'classic';
      soundEnabled = prefs.getBool(_soundEnabledKey) ?? true;
      musicEnabled = prefs.getBool(_musicEnabledKey) ?? true;
      final savedSfxVolume = prefs.getDouble(_sfxVolumeKey);
      final savedMusicVolume = prefs.getDouble(_musicVolumeKey);
      final savedUiVolume = prefs.getDouble(_uiVolumeKey);
      uiSoundEnabled = prefs.getBool(_uiSoundEnabledKey) ?? true;
      sfxVolume = (savedSfxVolume == null ||
                  (savedSfxVolume - 0.95).abs() < 0.0001 ||
                  (savedSfxVolume - 1.0).abs() < 0.0001
              ? 0.74
              : savedSfxVolume)
          .clamp(0.0, 1.0)
          .toDouble();
      musicVolume = (savedMusicVolume == null ||
                  (savedMusicVolume - 0.18).abs() < 0.0001 ||
                  (savedMusicVolume - 0.26).abs() < 0.0001 ||
                  (savedMusicVolume - 0.42).abs() < 0.0001 ||
                  (savedMusicVolume - 0.34).abs() < 0.0001
              ? 0.20
              : savedMusicVolume)
          .clamp(0.0, 1.0)
          .toDouble();
      uiVolume = (savedUiVolume == null || (savedUiVolume - 0.72).abs() < 0.0001 ? 0.66 : savedUiVolume).clamp(0.0, 1.0).toDouble();
      hapticsEnabled = prefs.getBool(_hapticsEnabledKey) ?? true;
      performanceMode = prefs.getBool(_performanceModeKey) ?? false;
      xp = prefs.getInt(_xpKey) ?? 0;
      perfectClears = prefs.getInt(_perfectClearsKey) ?? 0;
      tutorialCompleted = prefs.getBool(_tutorialCompletedKey) ?? false;
      playerName = prefs.getString(_playerNameKey) ?? 'ELXVRO PLAYER';
      _weeklyRewardClaim = prefs.getString(_weeklyRewardClaimKey) ?? '';

      coins = prefs.getInt(_coinsKey) ?? 0;
      _lastRewardClaimDate = prefs.getString(_rewardClaimDateKey) ?? '';
      loginStreak = prefs.getInt(_loginStreakKey) ?? 0;
      undoInventory = prefs.getInt(_undoInventoryKey) ?? 0;
      refreshInventory = prefs.getInt(_refreshInventoryKey) ?? 0;
      specialInventory = prefs.getInt(_specialInventoryKey) ?? 0;
      timedBestScore = prefs.getInt(_timedBestScoreKey) ?? 0;
      targetBestScore = prefs.getInt(_targetBestScoreKey) ?? 0;
      zenBestScore = prefs.getInt(_zenBestScoreKey) ?? 0;
      hardBestScore = prefs.getInt(_hardBestScoreKey) ?? 0;
      _dailyChallengeDate = prefs.getString(_dailyChallengeDateKey) ?? '';
      _dailyChallengeRewardDate =
          prefs.getString(_dailyChallengeRewardDateKey) ?? '';
      final challengeDay = _dayKey(DateTime.now());
      if (_dailyChallengeDate == challengeDay) {
        dailyChallengeBestScore =
            prefs.getInt(_dailyChallengeBestScoreKey) ?? 0;
      } else {
        _dailyChallengeDate = challengeDay;
        dailyChallengeBestScore = 0;
        await prefs.setString(_dailyChallengeDateKey, challengeDay);
        await prefs.setInt(_dailyChallengeBestScoreKey, 0);
      }

      final currentWeek = weekKeyFor(DateTime.now());
      final savedWeek = prefs.getString(_weeklyKeyKey) ?? '';
      if (savedWeek == currentWeek) {
        _weeklyKey = currentWeek;
        weeklyGames = prefs.getInt(_weeklyGamesKey) ?? 0;
        weeklyScore = prefs.getInt(_weeklyScoreKey) ?? 0;
        weeklyBestScore = prefs.getInt(_weeklyBestScoreKey) ?? 0;
      } else {
        _weeklyKey = currentWeek;
        weeklyGames = 0;
        weeklyScore = 0;
        weeklyBestScore = 0;
        await _saveWeekly(prefs);
      }

      _achievementClaims
        ..clear()
        ..addAll(prefs.getStringList(_achievementClaimsKey) ?? const <String>[]);

      _unlockedThemes
        ..clear()
        ..addAll(prefs.getStringList(_unlockedThemesKey) ?? const <String>[]);
      _unlockedThemes.add('classic');
      // Existing players keep whichever theme they had selected before the
      // economy system was introduced.
      _unlockedThemes.add(themeId);

      final today = _dayKey(DateTime.now());
      final savedDay = prefs.getString(_dailyDateKey);
      if (savedDay == today) {
        dailyGames = prefs.getInt(_dailyGamesKey) ?? 0;
        dailyLines = prefs.getInt(_dailyLinesKey) ?? 0;
        dailyBestScore = prefs.getInt(_dailyBestScoreKey) ?? 0;
      } else {
        dailyGames = 0;
        dailyLines = 0;
        dailyBestScore = 0;
        await _saveDaily(prefs, today);
      }

      final claimsDay = prefs.getString(_dailyClaimsDateKey);
      _dailyClaims.clear();
      if (claimsDay == today) {
        _dailyClaims.addAll(
          prefs.getStringList(_dailyClaimsKey) ?? const <String>[],
        );
      } else {
        await prefs.setString(_dailyClaimsDateKey, today);
        await prefs.setStringList(_dailyClaimsKey, const <String>[]);
      }

      await prefs.setStringList(
        _unlockedThemesKey,
        _unlockedThemes.toList()..sort(),
      );
    } catch (error, stackTrace) {
      debugPrint('ELXVRO storage load failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> refreshTemporalState() async {
    if (!isLoaded) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final today = _dayKey(now);
      final currentWeek = weekKeyFor(now);
      var changed = false;

      if (prefs.getString(_dailyDateKey) != today) {
        dailyGames = 0;
        dailyLines = 0;
        dailyBestScore = 0;
        await _saveDaily(prefs, today);
        changed = true;
      }

      if (prefs.getString(_dailyClaimsDateKey) != today) {
        _dailyClaims.clear();
        await prefs.setString(_dailyClaimsDateKey, today);
        await prefs.setStringList(_dailyClaimsKey, const <String>[]);
        changed = true;
      }

      if (_dailyChallengeDate != today) {
        _dailyChallengeDate = today;
        dailyChallengeBestScore = 0;
        await prefs.setString(_dailyChallengeDateKey, today);
        await prefs.setInt(_dailyChallengeBestScoreKey, 0);
        changed = true;
      }

      if (_weeklyKey != currentWeek) {
        _weeklyKey = currentWeek;
        weeklyGames = 0;
        weeklyScore = 0;
        weeklyBestScore = 0;
        await _saveWeekly(prefs);
        changed = true;
      }

      if (changed) {
        notifyListeners();
      }
    } catch (error, stackTrace) {
      debugPrint('ELXVRO temporal refresh failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> setPlayerName(String value) async {
    final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) return;
    playerName = normalized.length > 18
        ? normalized.substring(0, 18)
        : normalized;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_playerNameKey, playerName);
    } catch (error) {
      debugPrint('ELXVRO player name save failed: $error');
    }
  }

  Future<bool> claimWeeklyReward() async {
    if (!weeklyRewardAvailable) return false;
    _weeklyRewardClaim = _weeklyKey;
    coins += weeklyRewardAmount;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_weeklyRewardClaimKey, _weeklyRewardClaim);
      await prefs.setInt(_coinsKey, coins);
    } catch (error) {
      debugPrint('ELXVRO weekly reward save failed: $error');
    }
    return true;
  }

  Future<void> completeTutorial() async {
    tutorialCompleted = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_tutorialCompletedKey, true);
    } catch (error) {
      debugPrint('ELXVRO tutorial save failed: $error');
    }
  }

  Future<void> resetTutorial() async {
    tutorialCompleted = false;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_tutorialCompletedKey, false);
    } catch (error) {
      debugPrint('ELXVRO tutorial reset failed: $error');
    }
  }

  Future<void> setTheme(String id) async {
    if (!isThemeUnlocked(id)) {
      return;
    }
    themeId = id;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, id);
    } catch (error) {
      debugPrint('ELXVRO theme save failed: $error');
    }
  }

  Future<bool> unlockTheme(String id) async {
    if (isThemeUnlocked(id)) {
      await setTheme(id);
      return true;
    }
    final price = themePrice(id);
    if (coins < price) {
      return false;
    }
    coins -= price;
    _unlockedThemes.add(id);
    themeId = id;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_coinsKey, coins);
      await prefs.setString(_themeKey, id);
      await prefs.setStringList(
        _unlockedThemesKey,
        _unlockedThemes.toList()..sort(),
      );
    } catch (error) {
      debugPrint('ELXVRO theme unlock save failed: $error');
    }
    return true;
  }

  Future<void> setSoundEnabled(bool value) async {
    soundEnabled = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_soundEnabledKey, value);
    } catch (error) {
      debugPrint('ELXVRO sound setting save failed: $error');
    }
  }

  Future<void> setMusicEnabled(bool value) async {
    musicEnabled = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_musicEnabledKey, value);
    } catch (error) {
      debugPrint('ELXVRO music setting save failed: $error');
    }
  }

  Future<void> setUiSoundEnabled(bool value) async {
    uiSoundEnabled = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_uiSoundEnabledKey, value);
    } catch (error) {
      debugPrint('ELXVRO ui sound setting save failed: $error');
    }
  }

  Future<void> setSfxVolume(double value) async {
    sfxVolume = value.clamp(0.0, 1.0).toDouble();
    notifyListeners();
    _sfxVolumeSaveTimer?.cancel();
    _sfxVolumeSaveTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble(_sfxVolumeKey, sfxVolume);
      } catch (error) {
        debugPrint('ELXVRO sfx volume save failed: $error');
      }
    });
  }

  Future<void> setMusicVolume(double value) async {
    musicVolume = value.clamp(0.0, 1.0).toDouble();
    notifyListeners();
    _musicVolumeSaveTimer?.cancel();
    _musicVolumeSaveTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble(_musicVolumeKey, musicVolume);
      } catch (error) {
        debugPrint('ELXVRO music volume save failed: $error');
      }
    });
  }

  Future<void> setUiVolume(double value) async {
    uiVolume = value.clamp(0.0, 1.0).toDouble();
    notifyListeners();
    _uiVolumeSaveTimer?.cancel();
    _uiVolumeSaveTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble(_uiVolumeKey, uiVolume);
      } catch (error) {
        debugPrint('ELXVRO ui volume save failed: $error');
      }
    });
  }

  Future<void> setHapticsEnabled(bool value) async {
    hapticsEnabled = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hapticsEnabledKey, value);
    } catch (error) {
      debugPrint('ELXVRO haptics setting save failed: $error');
    }
  }

  Future<void> setPerformanceMode(bool value) async {
    performanceMode = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_performanceModeKey, value);
    } catch (error) {
      debugPrint('ELXVRO performance setting save failed: $error');
    }
  }

  Future<bool> claimDailyReward() async {
    if (!dailyRewardAvailable) {
      return false;
    }
    final now = DateTime.now();
    final today = _dayKey(now);
    final yesterday = _dayKey(now.subtract(const Duration(days: 1)));
    if (_lastRewardClaimDate == yesterday) {
      loginStreak += 1;
      if (loginStreak > 7) loginStreak = 7;
    } else {
      loginStreak = 1;
    }
    const rewards = <int>[50, 75, 100, 125, 150, 200, 300];
    coins += rewards[loginStreak - 1];
    _lastRewardClaimDate = today;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_coinsKey, coins);
      await prefs.setInt(_loginStreakKey, loginStreak);
      await prefs.setString(_rewardClaimDateKey, today);
    } catch (error) {
      debugPrint('ELXVRO daily reward save failed: $error');
    }
    return true;
  }

  Future<bool> claimDailyMission({
    required String id,
    required int reward,
    required bool completed,
  }) async {
    if (!completed || _dailyClaims.contains(id)) {
      return false;
    }
    _dailyClaims.add(id);
    coins += reward;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_coinsKey, coins);
      await prefs.setString(_dailyClaimsDateKey, _dayKey(DateTime.now()));
      await prefs.setStringList(_dailyClaimsKey, _dailyClaims.toList()..sort());
    } catch (error) {
      debugPrint('ELXVRO mission reward save failed: $error');
    }
    return true;
  }

  Future<bool> claimAchievement({
    required String id,
    required int reward,
  }) async {
    if (!achievementUnlocked(id) || _achievementClaims.contains(id)) {
      return false;
    }
    _achievementClaims.add(id);
    coins += reward;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_coinsKey, coins);
      await prefs.setStringList(
        _achievementClaimsKey,
        _achievementClaims.toList()..sort(),
      );
    } catch (error) {
      debugPrint('ELXVRO achievement reward save failed: $error');
    }
    return true;
  }

  Future<bool> buyUndoPack() => _purchase(
        price: 120,
        undo: 3,
      );

  Future<bool> buyRefreshPack() => _purchase(
        price: 120,
        refresh: 3,
      );

  Future<bool> buySpecialPack() => _purchase(
        price: 180,
        special: 3,
      );

  Future<bool> buyPowerBundle() => _purchase(
        price: 300,
        undo: 5,
        refresh: 5,
        special: 2,
      );

  Future<bool> _purchase({
    required int price,
    int undo = 0,
    int refresh = 0,
    int special = 0,
  }) async {
    if (coins < price) {
      return false;
    }
    coins -= price;
    undoInventory += undo;
    refreshInventory += refresh;
    specialInventory += special;
    notifyListeners();
    await _saveEconomy();
    return true;
  }

  Future<bool> consumeUndo() async {
    if (undoInventory <= 0) return false;
    undoInventory -= 1;
    notifyListeners();
    await _saveEconomy();
    return true;
  }

  Future<bool> consumeRefresh() async {
    if (refreshInventory <= 0) return false;
    refreshInventory -= 1;
    notifyListeners();
    await _saveEconomy();
    return true;
  }

  Future<bool> consumeSpecial() async {
    if (specialInventory <= 0) return false;
    specialInventory -= 1;
    notifyListeners();
    await _saveEconomy();
    return true;
  }

  Future<void> _saveEconomy() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_coinsKey, coins);
      await prefs.setInt(_undoInventoryKey, undoInventory);
      await prefs.setInt(_refreshInventoryKey, refreshInventory);
      await prefs.setInt(_specialInventoryKey, specialInventory);
    } catch (error) {
      debugPrint('ELXVRO economy save failed: $error');
    }
  }


  Future<int> recordModeResult({
    required String modeId,
    required int score,
    required bool success,
  }) async {
    var reward = 0;
    final today = _dayKey(DateTime.now());

    switch (modeId) {
      case 'timed':
        if (score > timedBestScore) {
          timedBestScore = score;
        }
        if (success) {
          reward = 25;
        }
        break;
      case 'target':
        if (score > targetBestScore) {
          targetBestScore = score;
        }
        if (success) {
          reward = 60;
        }
        break;
      case 'zen':
        if (score > zenBestScore) {
          zenBestScore = score;
        }
        break;
      case 'hard':
        if (score > hardBestScore) {
          hardBestScore = score;
        }
        break;
      case 'daily':
        if (_dailyChallengeDate != today) {
          _dailyChallengeDate = today;
          dailyChallengeBestScore = 0;
        }
        if (score > dailyChallengeBestScore) {
          dailyChallengeBestScore = score;
        }
        if (success && _dailyChallengeRewardDate != today) {
          reward = 150;
          _dailyChallengeRewardDate = today;
        }
        break;
      case 'classic':
        break;
      default:
        break;
    }

    if (reward > 0) {
      coins += reward;
    }
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_timedBestScoreKey, timedBestScore);
      await prefs.setInt(_targetBestScoreKey, targetBestScore);
      await prefs.setInt(_zenBestScoreKey, zenBestScore);
      await prefs.setInt(_hardBestScoreKey, hardBestScore);
      await prefs.setString(_dailyChallengeDateKey, _dailyChallengeDate);
      await prefs.setInt(
        _dailyChallengeBestScoreKey,
        dailyChallengeBestScore,
      );
      await prefs.setString(
        _dailyChallengeRewardDateKey,
        _dailyChallengeRewardDate,
      );
      if (reward > 0) {
        await prefs.setInt(_coinsKey, coins);
      }
    } catch (error) {
      debugPrint('ELXVRO mode result save failed: $error');
    }

    return reward;
  }

  Future<ProgressionResult> recordGame({
    required int score,
    required int combo,
    required int clearedLines,
    required int placedBlocks,
    int perfectClearsThisGame = 0,
  }) async {
    final levelBefore = playerLevel;
    final xpEarned = maxProgressionXp(
      score: score,
      combo: combo,
      clearedLines: clearedLines,
      placedBlocks: placedBlocks,
      perfectClears: perfectClearsThisGame,
    );
    final comboCoinBonus = combo > 2 ? (combo - 2) * 3 : 0;
    final perfectClearCoinBonus = perfectClearsThisGame * 30;

    gamesPlayed += 1;
    totalScore += score;
    totalLines += clearedLines;
    totalBlocks += placedBlocks;
    perfectClears += perfectClearsThisGame;
    xp += xpEarned;
    coins += comboCoinBonus + perfectClearCoinBonus;

    if (score > bestScore) {
      bestScore = score;
    }
    if (combo > maxCombo) {
      maxCombo = combo;
    }

    final today = _dayKey(DateTime.now());
    dailyGames += 1;
    dailyLines += clearedLines;
    if (score > dailyBestScore) {
      dailyBestScore = score;
    }

    final currentWeek = weekKeyFor(DateTime.now());
    if (_weeklyKey != currentWeek) {
      _weeklyKey = currentWeek;
      weeklyGames = 0;
      weeklyScore = 0;
      weeklyBestScore = 0;
    }
    weeklyGames += 1;
    weeklyScore += score;
    if (score > weeklyBestScore) {
      weeklyBestScore = score;
    }

    final levelAfter = playerLevel;
    var milestoneCoins = 0;
    var milestoneSpecials = 0;
    final unlockedByLevel = <String>[];
    if (levelAfter > levelBefore) {
      for (var level = levelBefore + 1; level <= levelAfter; level++) {
        if (level % 5 == 0) {
          milestoneCoins += 200 + level * 10;
          milestoneSpecials += 2;
          final theme = _themeForMilestone(level);
          if (theme != null && !_unlockedThemes.contains(theme)) {
            _unlockedThemes.add(theme);
            unlockedByLevel.add(theme);
          }
        }
      }
    }
    coins += milestoneCoins;
    specialInventory += milestoneSpecials;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_bestScoreKey, bestScore);
      await prefs.setInt(_gamesPlayedKey, gamesPlayed);
      await prefs.setInt(_maxComboKey, maxCombo);
      await prefs.setInt(_totalScoreKey, totalScore);
      await prefs.setInt(_totalLinesKey, totalLines);
      await prefs.setInt(_totalBlocksKey, totalBlocks);
      await prefs.setInt(_perfectClearsKey, perfectClears);
      await prefs.setInt(_xpKey, xp);
      await prefs.setInt(_coinsKey, coins);
      await prefs.setInt(_specialInventoryKey, specialInventory);
      await prefs.setStringList(
        _unlockedThemesKey,
        _unlockedThemes.toList()..sort(),
      );
      await _saveDaily(prefs, today);
      await _saveWeekly(prefs);
    } catch (error) {
      debugPrint('ELXVRO stats save failed: $error');
    }

    return ProgressionResult(
      xpEarned: xpEarned,
      levelBefore: levelBefore,
      levelAfter: levelAfter,
      coinBonus: comboCoinBonus + perfectClearCoinBonus + milestoneCoins,
      milestoneSpecials: milestoneSpecials,
      unlockedThemes: unlockedByLevel,
    );
  }

  static int maxProgressionXp({
    required int score,
    required int combo,
    required int clearedLines,
    required int placedBlocks,
    required int perfectClears,
  }) {
    final earned = 25 +
        score ~/ 120 +
        clearedLines * 14 +
        placedBlocks * 2 +
        combo * 8 +
        perfectClears * 100;
    return earned.clamp(25, 1200).toInt();
  }

  String? _themeForMilestone(int level) {
    switch (level) {
      case 5:
        return 'night';
      case 10:
        return 'marble';
      case 15:
        return 'fire';
      case 20:
        return 'nature';
      case 25:
        return 'aurora';
      default:
        return null;
    }
  }

  Future<void> _saveWeekly(SharedPreferences prefs) async {
    await prefs.setString(_weeklyKeyKey, _weeklyKey);
    await prefs.setInt(_weeklyGamesKey, weeklyGames);
    await prefs.setInt(_weeklyScoreKey, weeklyScore);
    await prefs.setInt(_weeklyBestScoreKey, weeklyBestScore);
  }

  static String weekKeyFor(DateTime date) {
    final localDate = DateTime(date.year, date.month, date.day);
    final monday = localDate.subtract(Duration(days: localDate.weekday - 1));
    final year = monday.year.toString().padLeft(4, '0');
    final month = monday.month.toString().padLeft(2, '0');
    final day = monday.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<void> _saveDaily(SharedPreferences prefs, String day) async {
    await prefs.setString(_dailyDateKey, day);
    await prefs.setInt(_dailyGamesKey, dailyGames);
    await prefs.setInt(_dailyLinesKey, dailyLines);
    await prefs.setInt(_dailyBestScoreKey, dailyBestScore);
  }

  String _dayKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  @override
  void dispose() {
    _sfxVolumeSaveTimer?.cancel();
    _musicVolumeSaveTimer?.cancel();
    _uiVolumeSaveTimer?.cancel();
    super.dispose();
  }
}

class ProgressionResult {
  const ProgressionResult({
    required this.xpEarned,
    required this.levelBefore,
    required this.levelAfter,
    required this.coinBonus,
    required this.milestoneSpecials,
    required this.unlockedThemes,
  });

  final int xpEarned;
  final int levelBefore;
  final int levelAfter;
  final int coinBonus;
  final int milestoneSpecials;
  final List<String> unlockedThemes;

  bool get leveledUp => levelAfter > levelBefore;
}
