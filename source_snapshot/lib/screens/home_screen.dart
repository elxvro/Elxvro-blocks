import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/game_theme.dart';
import '../services/audio_service.dart';
import '../widgets/coin_badge.dart';
import '../widgets/crystal_mark.dart';
import '../widgets/premium_background.dart';
import '../widgets/premium_button.dart';
import 'achievements_screen.dart';
import 'daily_missions_screen.dart';
import 'game_screen.dart';
import 'modes_screen.dart';
import 'profile_screen.dart';
import 'rewards_screen.dart';
import 'settings_screen.dart';
import 'social_hub_screen.dart';
import 'stats_screen.dart';
import 'store_screen.dart';
import 'themes_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final selectedTheme = gameThemes.firstWhere(
      (theme) => theme.id == appState.themeId,
      orElse: () => gameThemes.first,
    );

    return Scaffold(
      body: PremiumBackground(
        top: selectedTheme.backgroundTop,
        bottom: selectedTheme.backgroundBottom,
        material: selectedTheme.material,
        accent: selectedTheme.blockAccent,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 38,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            const Spacer(),
                            CoinBadge(coins: appState.coins, compact: true),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'ELXVRO',
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 10,
                            color: Color(0xFFFFD99A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'B L O C K S',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 7,
                            color: Colors.white.withValues(alpha: 0.78),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'SIMPLE MOVES  •  BIG MOMENTS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 2.2,
                            color: Colors.white.withValues(alpha: 0.42),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const CrystalMark(size: 112),
                        const SizedBox(height: 16),
                        _LevelStrip(appState: appState),
                        const SizedBox(height: 14),
                        if (appState.bestScore > 0)
                          Text(
                            'EN YÜKSEK  ${appState.bestScore}',
                            style: const TextStyle(
                              color: Color(0xFFFFD98B),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.8,
                            ),
                          ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: PremiumButton(
                            label: 'OYNA',
                            icon: Icons.play_arrow_rounded,
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => GameScreen(appState: appState),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: _HomeTile(
                            icon: Icons.sports_esports_rounded,
                            label: 'MODLAR',
                            badge: 'YENİ',
                            emphasized: true,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => ModesScreen(appState: appState),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _HomeTile(
                                icon: Icons.card_giftcard_rounded,
                                label: 'GÜNLÜK ÖDÜL',
                                badge: appState.dailyRewardAvailable ? 'HAZIR' : '${appState.loginStreak}. GÜN',
                                emphasized: appState.dailyRewardAvailable,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => RewardsScreen(appState: appState),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _HomeTile(
                                icon: Icons.storefront_rounded,
                                label: 'MAĞAZA',
                                badge: '${appState.coins} C',
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => StoreScreen(appState: appState),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _HomeTile(
                                icon: Icons.palette_outlined,
                                label: 'TEMALAR',
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => ThemesScreen(appState: appState),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _HomeTile(
                                icon: Icons.task_alt_rounded,
                                label: 'GÖREVLER',
                                badge: '${appState.completedDailyMissions}/3',
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => DailyMissionsScreen(appState: appState),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _HomeTile(
                                icon: Icons.emoji_events_outlined,
                                label: 'BAŞARIMLAR',
                                badge: '${appState.unlockedAchievements}/10',
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => AchievementsScreen(appState: appState),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _HomeTile(
                                icon: Icons.bar_chart_rounded,
                                label: 'İSTATİSTİK',
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => StatsScreen(appState: appState),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: _HomeTile(
                            icon: Icons.leaderboard_rounded,
                            label: 'LİDERLİK MERKEZİ',
                            badge: appState.weeklyRewardAvailable ? 'ÖDÜL HAZIR' : 'HAFTALIK',
                            emphasized: appState.weeklyRewardAvailable,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => SocialHubScreen(appState: appState),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: _HomeTile(
                            icon: Icons.person_outline_rounded,
                            label: 'PROFİL & SEVİYE',
                            badge: 'LV ${appState.playerLevel}',
                            emphasized: true,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => ProfileScreen(appState: appState),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: _HomeTile(
                            icon: Icons.tune_rounded,
                            label: 'AYARLAR',
                            badge: 'v0.10.1',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => SettingsScreen(appState: appState),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'ELXVRO  •  PLAY BEAUTIFULLY',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.30),
                            fontSize: 9,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LevelStrip extends StatelessWidget {
  const _LevelStrip({required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFFC86E).withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFC86E).withValues(alpha: 0.12),
            ),
            alignment: Alignment.center,
            child: Text(
              '${appState.playerLevel}',
              style: const TextStyle(
                color: Color(0xFFFFD98B),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      'SEVİYE ${appState.playerLevel}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${appState.currentLevelXp}/${appState.currentLevelXpTarget} XP',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: appState.levelProgress,
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFFFC86E),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeTile extends StatelessWidget {
  const _HomeTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? badge;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: emphasized
          ? const Color(0xFFFFC86E).withValues(alpha: 0.08)
          : Colors.white.withValues(alpha: 0.045),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () {
          unawaited(AudioService.instance.playClick());
          onTap();
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: emphasized
                ? Border.all(
                    color: const Color(0xFFFFC86E).withValues(alpha: 0.26),
                  )
                : null,
          ),
          child: Row(
            children: <Widget>[
              Icon(icon, color: const Color(0xFFFFCF7A), size: 22),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      color: Color(0xFFFFD98B),
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
