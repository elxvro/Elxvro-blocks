import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n/app_strings.dart';

/// Personal weekly league progression. No simulated online opponents.
class WeeklyLeagueCard extends StatelessWidget {
  const WeeklyLeagueCard({super.key, required this.appState});

  final AppState appState;

  static const thresholds = <int>[0, 5000, 15000, 30000, 60000];
  static const labelsTr = <String>['BRONZ', 'GÜMÜŞ', 'ALTIN', 'PLATİN', 'ELMAS'];
  static const labelsEn = <String>['BRONZE', 'SILVER', 'GOLD', 'PLATINUM', 'DIAMOND'];

  @override
  Widget build(BuildContext context) {
    final score = appState.weeklyScore;
    var tier = 0;
    for (var i = 1; i < thresholds.length; i++) {
      if (score >= thresholds[i]) tier = i;
    }
    final next = tier + 1;
    final maxed = next >= thresholds.length;
    final start = thresholds[tier];
    final end = maxed ? start : thresholds[next];
    final progress = maxed ? 1.0 : ((score - start) / (end - start)).clamp(0.0, 1.0).toDouble();
    final english = AppStrings.current.isEnglish;
    final label = english ? labelsEn[tier] : labelsTr[tier];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withValues(alpha: 0.045),
        border: Border.all(color: const Color(0xFFFFCF7A).withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(children: <Widget>[
            const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFCF7A)),
            const SizedBox(width: 10),
            Expanded(child: Text(
              AppStrings.current.f('HAFTALIK LİG', 'WEEKLY LEAGUE'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
            )),
            Text(label, style: const TextStyle(color: Color(0xFFFFCF7A), fontWeight: FontWeight.w900)),
          ]),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            color: const Color(0xFFFFCF7A),
            backgroundColor: Colors.white12,
          ),
          const SizedBox(height: 10),
          Text(
            maxed
                ? AppStrings.current.f('En yüksek lige ulaştın!', 'Highest league reached!')
                : AppStrings.current.f(
                    'Sonraki lig: ${english ? labelsEn[next] : labelsTr[next]} • ${end - score} puan kaldı',
                    'Next league: ${labelsEn[next]} • ${end - score} points remaining',
                  ),
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.current.f(
              'Kişisel ilerleme • Her hafta sıfırlanır • Çevrimiçi sıralama değildir',
              'Personal progress • Resets weekly • Not an online leaderboard',
            ),
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
