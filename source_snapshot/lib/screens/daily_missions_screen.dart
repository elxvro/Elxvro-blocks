import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/game_theme.dart';
import '../services/audio_service.dart';
import '../widgets/coin_badge.dart';
import '../widgets/premium_background.dart';

class DailyMissionsScreen extends StatelessWidget {
  const DailyMissionsScreen({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final selectedTheme = gameThemes.firstWhere(
          (theme) => theme.id == appState.themeId,
          orElse: () => gameThemes.first,
        );

        final missions = <_MissionData>[
          _MissionData(
            id: 'daily_game',
            title: 'Bugünün Oyunu',
            subtitle: '1 oyun tamamla',
            current: appState.dailyGames,
            target: 1,
            reward: 50,
            icon: Icons.sports_esports_rounded,
          ),
          _MissionData(
            id: 'daily_lines',
            title: 'Temizlik Serisi',
            subtitle: '8 satır veya sütun temizle',
            current: appState.dailyLines,
            target: 8,
            reward: 100,
            icon: Icons.auto_awesome_rounded,
          ),
          _MissionData(
            id: 'daily_score',
            title: 'Skor Avcısı',
            subtitle: 'Tek oyunda 2.500 puan yap',
            current: appState.dailyBestScore,
            target: 2500,
            reward: 150,
            icon: Icons.emoji_events_rounded,
          ),
        ];

        return Scaffold(
          body: PremiumBackground(
            top: selectedTheme.backgroundTop,
            bottom: selectedTheme.backgroundBottom,
            material: selectedTheme.material,
            accent: selectedTheme.blockAccent,
            child: SafeArea(
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 18, 12),
                    child: Row(
                      children: <Widget>[
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const SizedBox(width: 4),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'GÜNLÜK GÖREVLER',
                                style: TextStyle(
                                  color: Color(0xFFFFD99A),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.8,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Tamamla, coin ödülünü al',
                                style: TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        CoinBadge(coins: appState.coins, compact: true),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                      itemCount: missions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => _MissionCard(
                        data: missions[index],
                        accent: selectedTheme.blockAccent,
                        claimed: appState.isDailyMissionClaimed(missions[index].id),
                        onClaim: () async {
                          final mission = missions[index];
                          final success = await appState.claimDailyMission(
                            id: mission.id,
                            reward: mission.reward,
                            completed: mission.current >= mission.target,
                          );
                          if (!context.mounted || !success) return;
                          unawaited(AudioService.instance.playReward());
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('+${mission.reward} coin kazandın.')),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({
    required this.data,
    required this.accent,
    required this.claimed,
    required this.onClaim,
  });

  final _MissionData data;
  final Color accent;
  final bool claimed;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final completed = data.current >= data.target;
    final progress = (data.current / data.target).clamp(0.0, 1.0).toDouble();
    final shownCurrent = data.current > data.target ? data.target : data.current;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withValues(alpha: 0.045),
        border: Border.all(
          color: completed
              ? const Color(0xFF79D993).withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.12),
                ),
                child: Icon(data.icon, color: accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      data.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.subtitle,
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                children: <Widget>[
                  const Icon(
                    Icons.monetization_on_rounded,
                    color: Color(0xFFFFC86E),
                    size: 18,
                  ),
                  Text(
                    '+${data.reward}',
                    style: const TextStyle(
                      color: Color(0xFFFFD98B),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.07),
              valueColor: AlwaysStoppedAnimation<Color>(
                completed ? const Color(0xFF79D993) : accent,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Text(
                '$shownCurrent / ${data.target}',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
              const Spacer(),
              SizedBox(
                height: 38,
                child: FilledButton(
                  onPressed: completed && !claimed ? onClaim : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFC98B42),
                    disabledBackgroundColor: Colors.white.withValues(alpha: 0.07),
                  ),
                  child: Text(
                    claimed ? 'ALINDI' : completed ? 'AL' : 'DEVAM',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MissionData {
  const _MissionData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.current,
    required this.target,
    required this.reward,
    required this.icon,
  });

  final String id;
  final String title;
  final String subtitle;
  final int current;
  final int target;
  final int reward;
  final IconData icon;
}
