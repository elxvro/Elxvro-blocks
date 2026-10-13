from pathlib import Path
import sys
root=Path(sys.argv[1])
def patch(f,old,new):
    p=root/f;s=p.read_text(encoding='utf-8')
    if s.count(old)!=1: raise RuntimeError(f'UI anchor {f}: {s.count(old)} {old[:40]!r}')
    p.write_text(s.replace(old,new,1),encoding='utf-8')

newachievements=[
 ('combo_5','Zincir Ustası','Chain Expert','5 combo gerçekleştir','Reach a 5x combo',375,'bolt_rounded'),
 ('combo_8','Seri Efsanesi','Chain Legend','8 combo gerçekleştir','Reach an 8x combo',750,'electric_bolt_rounded'),
 ('lines_100','Kristal Kesici','Crystal Cutter','Toplam 100 hat temizle','Clear 100 lines',420,'auto_awesome_rounded'),
 ('lines_500','Efsane Temizleyici','Legendary Cleaner','Toplam 500 hat temizle','Clear 500 lines',850,'cleaning_services_rounded'),
 ('blocks_1000','Blok Mimarı','Block Architect','Toplam 1000 parça yerleştir','Place 1000 pieces',550,'grid_view_rounded'),
 ('games_100','Demir İrade','Iron Will','100 oyun tamamla','Complete 100 games',900,'military_tech_rounded'),
 ('score_25000','Rekor Avcısı','Record Hunter','Tek oyunda 25.000 puana ulaş','Reach 25000 in one game',1100,'emoji_events_rounded'),
 ('perfect_15','Kusursuzluk Kralı','Perfect Champion','Toplam 15 Perfect Clear yap','Complete 15 Perfect Clears',950,'diamond_rounded'),
 ('level_30','Yüce Usta','Grand Master','Seviye 30 ol','Reach player level 30',1250,'workspace_premium_rounded'),
 ('adventure_10','Macera Fatihi','Adventure Conqueror','10 macera bölümü tamamla','Complete 10 adventure chapters',675,'map_rounded'),
]
rows=[]
for ident,tr,en,dtr,den,reward,icon in newachievements:
    rows.append("    _AchievementData(id: '%s', title: AppStrings.current.f('%s','%s'), subtitle: AppStrings.current.f('%s','%s'), reward: %d, icon: Icons.%s)," % (ident,tr,en,dtr,den,reward,icon))
patch('lib/screens/achievements_screen.dart',
"""    _AchievementData(id: 'level_15', title: AppStrings.current.f('ELXVRO Ustası','ELXVRO Master'), subtitle: AppStrings.current.f('Seviye 15 ol','Reach level 15'), reward: 650, icon: Icons.military_tech_rounded),""",
"""    _AchievementData(id: 'level_15', title: AppStrings.current.f('ELXVRO Ustası','ELXVRO Master'), subtitle: AppStrings.current.f('Seviye 15 ol','Reach level 15'), reward: 650, icon: Icons.military_tech_rounded),
"""+"\n".join(rows))
patch('lib/screens/achievements_screen.dart',
"""                                style: const TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                            ],""",
"""                                style: const TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                              const SizedBox(height: 3),
                              Text('LİG: ${appState.achievementLeague}  •  ${appState.achievementRating} RP',
                                style: const TextStyle(color: Color(0xFFFFC977), fontSize: 11, fontWeight: FontWeight.bold)),
                            ],""")

missions=[
('daily_games_6','Maraton','Marathon','Bugün 6 oyun tamamla','Complete 6 games today','dailyGames',6,260,'sports_esports_rounded'),
('daily_lines_45','Sarsılmaz','Unstoppable','Bugün 45 hat temizle','Clear 45 lines today','dailyLines',45,440,'auto_awesome_rounded'),
('daily_score_12000','Skor Dehası','Score Genius','Tek oyunda 12.000 puan yap','Score 12,000 in one game','dailyBestScore',12000,520,'emoji_events_rounded'),
('daily_combo_7','Zincir Canavarı','Chain Monster','Tek oyunda x7 combo yap','Reach a x7 combo today','dailyMaxCombo',7,560,'bolt_rounded'),
('daily_blocks_200','Blok Maratonu','Block Marathon','Bugün 200 parça yerleştir','Place 200 pieces today','dailyPlacedBlocks',200,420,'grid_view_rounded'),
('daily_perfect_2','Çifte Kusursuz','Double Perfect','Bugün 2 Perfect Clear yap','Achieve 2 Perfect Clears today','dailyPerfectClears',2,680,'diamond_outlined'),
('daily_total_40000','Efsanevi Gün','Legendary Day','Bugün toplam 40.000 puan kazan','Accumulate 40,000 points today','dailyTotalScore',40000,720,'military_tech_rounded')
]
missionlines=[]
for ident,tr,en,subtr,suben,field,goal,reward,icon in missions:
    missionlines.append("""          _MissionData(
            id: '%s',
            title: AppStrings.current.f('%s','%s'),
            subtitle: AppStrings.current.f('%s','%s'),
            current: appState.%s,
            target: %d,
            reward: %d,
            icon: Icons.%s,
          ),"""%(ident,tr,en,subtr,suben,field,goal,reward,icon))
patch('lib/screens/daily_missions_screen.dart',
"""            target: 20,
            reward: 180,
            icon: Icons.grid_view_rounded,
          ),
        ];""",
"""            target: 20,
            reward: 180,
            icon: Icons.grid_view_rounded,
          ),
"""+"\n".join(missionlines)+"\n        ];")

patch('lib/screens/social_hub_screen.dart',
"""                        _PlayerCard(appState: appState),
                        const SizedBox(height: 14),""",
"""                        _PlayerCard(appState: appState),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: const LinearGradient(colors: <Color>[
                              Color(0xFF342B24), Color(0xFF151D22),
                            ]),
                            border: Border.all(color: const Color(0xFFFFC977).withValues(alpha: .35)),
                          ),
                          child: Row(children: <Widget>[
                            const Icon(Icons.military_tech_rounded,
                              color: Color(0xFFFFCF7B), size: 30),
                            const SizedBox(width: 13),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(AppStrings.current.f('BAŞARI LİGİ', 'ACHIEVEMENT LEAGUE'),
                                  style: const TextStyle(color: Colors.white60,
                                    fontSize: 10, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 3),
                                Text(appState.achievementLeague,
                                  style: const TextStyle(color: Color(0xFFFFD98B),
                                    fontSize: 17, fontWeight: FontWeight.w900)),
                                Text('${appState.achievementRating} RP • ${appState.unlockedAchievements} / ${AppState.rankedAchievementIds.length} başarım',
                                  style: const TextStyle(color: Colors.white70, fontSize: 11)),
                              ],
                            )),
                          ]),
                        ),
                        const SizedBox(height: 18),""")
(root/'test/v0280_merit_missions_test.dart').write_text("""import 'package:flutter_test/flutter_test.dart';
import 'package:elxvro_blocks/app_state.dart';

void main() {
  test('new achievements provide persistent merit-based local ranking', () {
    final app = AppState();
    expect(AppState.rankedAchievementIds.length, 20);
    expect(app.achievementRating, greaterThanOrEqualTo(10));
    expect(app.achievementLeague, isNotEmpty);
    expect(app.achievementUnlocked('combo_8'), isFalse);
    expect(app.achievementUnlocked('score_25000'), isFalse);
  });
  test('hard daily missions are tracked separately', () {
    final app = AppState();
    expect(app.dailyMaxCombo, 0);
    expect(app.dailyPerfectClears, 0);
    expect(app.dailyPlacedBlocks, 0);
    expect(app.dailyTotalScore, 0);
  });
}
""",encoding='utf-8')
print('Seven difficult daily missions, ten achievements and personal league UI added')
