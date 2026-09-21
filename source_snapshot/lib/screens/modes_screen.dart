import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/game_mode.dart';
import '../models/game_theme.dart';
import '../widgets/coin_badge.dart';
import '../widgets/premium_background.dart';
import 'game_screen.dart';

class ModesScreen extends StatelessWidget {
  const ModesScreen({super.key, required this.appState});

  final AppState appState;

  int _bestFor(GameMode mode) {
    switch (mode) {
      case GameMode.classic:
        return appState.bestScore;
      case GameMode.timed:
        return appState.timedBestScore;
      case GameMode.target:
        return appState.targetBestScore;
      case GameMode.daily:
        return appState.dailyChallengeBestScore;
      case GameMode.zen:
        return appState.zenBestScore;
      case GameMode.hard:
        return appState.hardBestScore;
    }
  }

  IconData _iconFor(GameMode mode) {
    switch (mode) {
      case GameMode.classic:
        return Icons.grid_view_rounded;
      case GameMode.timed:
        return Icons.timer_outlined;
      case GameMode.target:
        return Icons.flag_rounded;
      case GameMode.daily:
        return Icons.local_fire_department_rounded;
      case GameMode.zen:
        return Icons.spa_rounded;
      case GameMode.hard:
        return Icons.whatshot_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedTheme = gameThemes.firstWhere(
      (theme) => theme.id == appState.themeId,
      orElse: () => gameThemes.first,
    );
    final accent = selectedTheme.blockAccent;

    return Scaffold(
      body: PremiumBackground(
        top: selectedTheme.backgroundTop,
        bottom: selectedTheme.backgroundBottom,
        material: selectedTheme.material,
        accent: accent,
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 16, 4),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    Expanded(
                      child: Text(
                        'OYUN MODLARI',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: accent,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                    CoinBadge(coins: appState.coins, compact: true),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 14),
                child: Text(
                  'Klasik, challenge, Zen ve Zor mod ile aynı çekirdek mekaniği farklı ritimlerde oyna.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.52),
                    fontSize: 11,
                    height: 1.45,
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: GameMode.values.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final mode = GameMode.values[index];
                    final data = gameModeData[mode]!;
                    final best = _bestFor(mode);
                    final dailyRewardReady = mode == GameMode.daily &&
                        appState.dailyChallengeRewardAvailable;
                    return _ModeCard(
                      icon: _iconFor(mode),
                      title: data.title,
                      subtitle: data.subtitle,
                      description: data.description,
                      best: best,
                      reward: data.completionReward,
                      rewardReady: dailyRewardReady,
                      accent: accent,
                      surface: selectedTheme.board,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => GameScreen(
                              appState: appState,
                              mode: mode,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.best,
    required this.reward,
    required this.rewardReady,
    required this.accent,
    required this.surface,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final int best;
  final int reward;
  final bool rewardReady;
  final Color accent;
  final Color surface;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Color.lerp(surface, Colors.black, 0.14)!.withValues(alpha: 0.84),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: accent.withValues(alpha: rewardReady ? 0.48 : 0.18),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: accent.withValues(alpha: 0.07),
                blurRadius: 20,
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(17),
                  color: accent.withValues(alpha: 0.11),
                  border: Border.all(color: accent.withValues(alpha: 0.18)),
                ),
                child: Icon(icon, color: accent, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        if (rewardReady)
                          _Badge(label: 'ÖDÜL HAZIR', accent: accent),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.52),
                        fontSize: 10,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: <Widget>[
                        _Badge(label: 'REKOR $best', accent: accent),
                        if (reward > 0)
                          _Badge(label: '+$reward COIN', accent: accent),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: accent.withValues(alpha: 0.68),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: accent.withValues(alpha: 0.08),
        border: Border.all(color: accent.withValues(alpha: 0.12)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: accent,
          fontSize: 8,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
