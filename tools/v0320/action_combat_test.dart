import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:elxvro_blocks/app_state.dart';
import 'package:elxvro_blocks/game/adventure_combat.dart';
import 'package:elxvro_blocks/screens/adventure_screen.dart';
import 'package:elxvro_blocks/screens/adventure_combat_screen.dart';

void main(){
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(()=>SharedPreferences.setMockInitialValues(<String,Object>{}));
  test('all 60 levels provide six increasingly difficult monster fights',(){
    final a=List.generate(60,(i)=>AdventureCombat(i+1));
    expect(a.map((x)=>x.world).toSet(),{0,1,2,3,4,5});
    expect(a.first.bossMaxHp,lessThan(a.last.bossMaxHp));
    expect(a.every((x)=>x.playerHp==1000),true);
  });
  test('attack and powers use genuine energy and cooldowns',(){
    final b=AdventureCombat(1);
    expect(b.use(CombatMove.sword),true);
    expect(b.use(CombatMove.sword),false);
    expect(b.damageDone,greaterThan(0));
    for(var i=0;i<5;i++)b.tick(100);
    expect(b.use(CombatMove.power),true);
    expect(b.energy,lessThan(35));
  });
  test('boss attacks are telegraphed; dodge and shield avoid damage',(){
    final b=AdventureCombat(10);
    while(b.dangerLane<0)b.tick(100);
    b.lane=(b.dangerLane+1)%3;
    while(b.warningMs>0)b.tick(100);
    expect(b.playerHp,1000);
    final shield=AdventureCombat(1);
    while(shield.dangerLane<0)shield.tick(100);
    shield.lane=shield.dangerLane;
    expect(shield.use(CombatMove.shield),true);
    while(shield.warningMs>0)shield.tick(100);
    expect(shield.playerHp,1000);
  });
  test('victory only happens after combat, defeat earns no stars',(){
    final b=AdventureCombat(1);
    expect(b.stars,0);
    for(var i=0;i<65&&!b.finished;i++){
      b.use(CombatMove.sword);
      for(var j=0;j<6;j++)b.tick(100);
    }
    expect(b.won,true);
    expect(b.stars,greaterThanOrEqualTo(1));
  });
  test('only Adventure uses new monster battle routes and assets',(){
    final map=File('lib/screens/adventure_screen.dart').readAsStringSync();
    expect(map,contains('AdventureCombatScreen('));
    expect(map,isNot(contains('FallingBlocksScreen(')));
    final game=File('lib/screens/game_screen.dart').readAsStringSync();
    expect(game,isNot(contains('AdventureCombatScreen(')));
    for(var i=0;i<6;i++){
      expect(File('assets/images/adventure_battles/world_'+i.toString()+'.webp').lengthSync(),
        greaterThan(60000));
    }
  });
  testWidgets('combat UI has usable actions at 360px width',(tester)async{
    await tester.binding.setSurfaceSize(const Size(360,780));
    addTearDown(()=>tester.binding.setSurfaceSize(null));
    final app=AppState();await app.load();
    await tester.pumpWidget(MaterialApp(theme:ThemeData.dark(),
      home:AdventureScreen(appState:app)));
    await tester.pump();
    expect(find.text('MACERA'),findsOneWidget);
    expect(tester.takeException(),isNull);
    await tester.pumpWidget(MaterialApp(theme:ThemeData.dark(),
      home:AdventureCombatScreen(appState:app,level:1)));
    await tester.pump();
    expect(find.text('SİBER MUHAFIZ'),findsOneWidget);
    expect(find.text('SALDIR'),findsOneWidget);
    expect(tester.takeException(),isNull);
    await tester.pumpWidget(const SizedBox());
  });
}