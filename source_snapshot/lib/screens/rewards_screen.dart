import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/game_theme.dart';
import '../services/audio_service.dart';
import '../widgets/coin_badge.dart';
import '../widgets/premium_background.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key, required this.appState});

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
        const rewards = <int>[50, 75, 100, 125, 150, 200, 300];
        final activeDay = appState.dailyRewardDay;

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
                    padding: const EdgeInsets.fromLTRB(8, 8, 18, 10),
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
                                'GÜNLÜK ÖDÜL',
                                style: TextStyle(
                                  color: Color(0xFFFFD99A),
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Her gün gel, seriyi büyüt',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        CoinBadge(coins: appState.coins, compact: true),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            color: Colors.white.withValues(alpha: 0.045),
                            border: Border.all(
                              color: selectedTheme.blockAccent
                                  .withValues(alpha: 0.20),
                            ),
                          ),
                          child: Column(
                            children: <Widget>[
                              const Icon(
                                Icons.local_fire_department_rounded,
                                color: Color(0xFFFFC86E),
                                size: 42,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '${appState.loginStreak} GÜNLÜK SERİ',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                appState.dailyRewardAvailable
                                    ? 'Bugünün ödülü hazır.'
                                    : 'Bugünün ödülünü aldın. Yarın tekrar gel.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1.35,
                          ),
                          itemCount: rewards.length,
                          itemBuilder: (context, index) {
                            final day = index + 1;
                            final claimed = !appState.dailyRewardAvailable &&
                                day <= appState.loginStreak;
                            final isCurrent = appState.dailyRewardAvailable
                                ? day == activeDay
                                : day == appState.loginStreak;
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                color: isCurrent
                                    ? const Color(0xFFFFC86E)
                                        .withValues(alpha: 0.12)
                                    : Colors.white.withValues(alpha: 0.035),
                                border: Border.all(
                                  color: isCurrent
                                      ? const Color(0xFFFFC86E)
                                          .withValues(alpha: 0.55)
                                      : Colors.white.withValues(alpha: 0.07),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    '$day. GÜN',
                                    style: TextStyle(
                                      color: isCurrent
                                          ? const Color(0xFFFFD98B)
                                          : Colors.white54,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  Icon(
                                    claimed
                                        ? Icons.check_circle_rounded
                                        : Icons.monetization_on_rounded,
                                    color: claimed
                                        ? const Color(0xFF79D993)
                                        : const Color(0xFFFFC86E),
                                    size: 26,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '+${rewards[index]}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: FilledButton.icon(
                            onPressed: appState.dailyRewardAvailable
                                ? () async {
                                    final amount = appState.dailyRewardAmount;
                                    final claimed =
                                        await appState.claimDailyReward();
                                    if (!context.mounted || !claimed) return;
                                    unawaited(AudioService.instance.playReward());
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '+$amount coin hesabına eklendi.',
                                        ),
                                      ),
                                    );
                                  }
                                : null,
                            icon: const Icon(Icons.card_giftcard_rounded),
                            label: Text(
                              appState.dailyRewardAvailable
                                  ? '+${appState.dailyRewardAmount} COIN AL'
                                  : 'BUGÜN ALINDI',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFC98B42),
                              disabledBackgroundColor:
                                  Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                        ),
                      ],
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
