import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/game_theme.dart';
import '../services/audio_service.dart';
import '../widgets/coin_badge.dart';
import '../widgets/premium_background.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key, required this.appState});

  final AppState appState;

  static const List<_AchievementData> _items = <_AchievementData>[
    _AchievementData(id: 'first_game', title: 'İlk Adım', subtitle: 'İlk oyununu tamamla', reward: 100, icon: Icons.flag_rounded),
    _AchievementData(id: 'score_1000', title: 'Isınma Turu', subtitle: 'Tek oyunda 1.000 puana ulaş', reward: 125, icon: Icons.local_fire_department_rounded),
    _AchievementData(id: 'combo_3', title: 'Combo Ustası', subtitle: 'x3 combo yap', reward: 150, icon: Icons.bolt_rounded),
    _AchievementData(id: 'lines_25', title: 'Tahta Temizleyici', subtitle: 'Toplam 25 satır veya sütun temizle', reward: 200, icon: Icons.auto_awesome_rounded),
    _AchievementData(id: 'games_10', title: 'Deneyimli', subtitle: '10 oyun tamamla', reward: 250, icon: Icons.sports_esports_rounded),
    _AchievementData(id: 'blocks_250', title: 'Blok Koleksiyoncusu', subtitle: '250 parça yerleştir', reward: 300, icon: Icons.grid_view_rounded),
    _AchievementData(id: 'score_10000', title: 'Efsane', subtitle: 'Tek oyunda 10.000 puana ulaş', reward: 500, icon: Icons.workspace_premium_rounded),
    _AchievementData(id: 'level_5', title: 'Yükseliş', subtitle: 'Seviye 5 ol', reward: 250, icon: Icons.trending_up_rounded),
    _AchievementData(id: 'perfect_3', title: 'Kusursuz', subtitle: 'Toplam 3 Perfect Clear yap', reward: 350, icon: Icons.diamond_outlined),
    _AchievementData(id: 'level_15', title: 'ELXVRO Ustası', subtitle: 'Seviye 15 ol', reward: 650, icon: Icons.military_tech_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
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
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 18, 14),
                    child: Row(
                      children: <Widget>[
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text(
                                'BAŞARIMLAR',
                                style: TextStyle(
                                  color: Color(0xFFFFD99A),
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${appState.unlockedAchievements}/${_items.length} açıldı',
                                style: const TextStyle(color: Colors.white54, fontSize: 12),
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
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        final unlocked = appState.achievementUnlocked(item.id);
                        final claimed = appState.isAchievementClaimed(item.id);
                        return _AchievementCard(
                          item: item,
                          unlocked: unlocked,
                          claimed: claimed,
                          accent: selectedTheme.blockAccent,
                          onClaim: () async {
                            final success = await appState.claimAchievement(
                              id: item.id,
                              reward: item.reward,
                            );
                            if (!context.mounted || !success) return;
                            unawaited(AudioService.instance.playReward());
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('+${item.reward} coin kazandın.')),
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
      },
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({
    required this.item,
    required this.unlocked,
    required this.claimed,
    required this.accent,
    required this.onClaim,
  });

  final _AchievementData item;
  final bool unlocked;
  final bool claimed;
  final Color accent;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: unlocked ? 0.055 : 0.028),
        border: Border.all(
          color: unlocked
              ? accent.withValues(alpha: 0.45)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: unlocked
                  ? accent.withValues(alpha: 0.16)
                  : Colors.white.withValues(alpha: 0.04),
            ),
            child: Icon(
              unlocked ? item.icon : Icons.lock_outline_rounded,
              color: unlocked ? accent : Colors.white24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.title,
                  style: TextStyle(
                    color: unlocked ? Colors.white : Colors.white38,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  style: TextStyle(
                    color: unlocked ? Colors.white54 : Colors.white24,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 38,
            child: FilledButton(
              onPressed: unlocked && !claimed ? onClaim : null,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC98B42),
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.07),
                padding: const EdgeInsets.symmetric(horizontal: 11),
              ),
              child: claimed
                  ? const Icon(Icons.check_rounded, size: 18)
                  : unlocked
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Icon(Icons.monetization_on_rounded, size: 15),
                            const SizedBox(width: 4),
                            Text('+${item.reward}'),
                          ],
                        )
                      : const Icon(Icons.lock_rounded, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementData {
  const _AchievementData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.reward,
    required this.icon,
  });

  final String id;
  final String title;
  final String subtitle;
  final int reward;
  final IconData icon;
}
