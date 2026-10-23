#!/usr/bin/env python3
"""Make v0.38.21 ranking enhancements against formatted v0.38.20 CI source."""
from pathlib import Path
import sys
root=Path(sys.argv[1] if len(sys.argv)>1 else '.')
def change(source, old, new, count=1):
    if source.count(old)!=count:
        raise AssertionError(f'Expected {count} occurrences, found {source.count(old)}: {old[:90]}')
    return source.replace(old,new,count)
rank=root/'lib/widgets/three_game_rankings.dart'
s=rank.read_text()
s=change(s,'  Timer? _retryTimer;','  Timer? _retryTimer;\n  bool _rankRefreshQueued = false;')
s=change(s,'''    _retryTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) _load(refreshProfile: true);
''','''    _service.leaderboardRevision.addListener(_onScorePublished);
    _retryTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted && _rankVisible) _load(refreshProfile: true);
''')
s=change(s,'    _retryTimer?.cancel();\n','    _retryTimer?.cancel();\n    _service.leaderboardRevision.removeListener(_onScorePublished);\n')
s=change(s,'''  int _rankingRequestSerial = 0;
''','''  int _rankingRequestSerial = 0;

  bool get _rankVisible => ModalRoute.of(context)?.isCurrent ?? true;

  void _onScorePublished() {
    if (!mounted || _rankRefreshQueued) return;
    _rankRefreshQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _rankRefreshQueued = false;
      if (mounted) _load(refreshProfile: true);
    });
  }
''')
rank.write_text(s)
p=root/'lib/services/play_games_service.dart';s=p.read_text()
s=change(s,'''  final PlayGamesIds ids;
''','''  final ValueNotifier<int> leaderboardRevision = ValueNotifier<int>(0);

  final PlayGamesIds ids;
''')
# Keep v0.38.20's current account generation and diagnostic reporting.
s=change(s,'''              await _adapter.submitScore(leaderboardId: id, score: score);
''','''              await _adapter.submitScore(leaderboardId: id, score: score);
              leaderboardRevision.value++;
              _cachedSummaryAt = null;
''')
s=change(s,'''        await _pendingScores.flush(
          (id, score) => _adapter.submitScore(leaderboardId: id, score: score),
        );
''','''        await _pendingScores.flush((id, score) async {
          await _adapter.submitScore(leaderboardId: id, score: score);
          leaderboardRevision.value++;
          _cachedSummaryAt = null;
        });
''')
start=s.index('class PlayGamesService implements SocialService')
first=s[:start]; second=s[start:]
second=change(second,'''    if (!await _ensureConnected()) return;
    try {
      await _adapter.unlockAchievement(id);
''','''    if (!await _ensureConnected() ||
        (_identityAdapter != null && _accountKey == null)) return;
    try {
      await _adapter.unlockAchievement(id);
''')
anchor='  @override\n  Future<void> showLeaderboards() async {'
method='''  /// Replay unlocked local achievements for this verified Games account.
  Future<void> syncUnlockedAchievements(
      bool Function(String id) isUnlocked) async {
    if (!await signIn(force: true) ||
        (_identityAdapter != null && _accountKey == null)) return;
    for (final entry in ids.achievementIds.entries) {
      final id = entry.value.trim();
      if (id.isEmpty || !isUnlocked(entry.key)) continue;
      if (_identityAdapter != null && _accountKey == null) return;
      await unlockAchievement(achievementId: id);
    }
  }

'''
second=change(second,anchor,method+anchor)
p.write_text(first+second)
print('v0.38.21 Play Games ranking compatibility OK')
