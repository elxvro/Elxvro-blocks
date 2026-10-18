import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_state.dart';
import '../game/adventure_combat.dart';
import '../models/adventure_level.dart';
import '../models/game_theme.dart';
import '../widgets/adventure_world_backdrop.dart';

/// Adventure-only playable real-time battle (no falling-block board).
class AdventureCombatScreen extends StatefulWidget {
  const AdventureCombatScreen({super.key,required this.appState,required this.level});
  final AppState appState;
  final int level;
  @override State<AdventureCombatScreen> createState()=>_CombatScreenState();
}
class _CombatScreenState extends State<AdventureCombatScreen> with WidgetsBindingObserver {
  late AdventureCombat battle;
  Timer? ticker;
  bool paused=false, ending=false;
  String flash='';
  int flashFrames=0;
  static const worldsTr=['NEON ŞEHİR','BUZ VADİSİ','ZEHİRLİ ORMAN','LAV DAĞI','UZAY ÜSSÜ','KARANLIK BOYUT'];
  static const worldsEn=['NEON CITY','ICE VALLEY','TOXIC FOREST','LAVA MOUNTAIN','SPACE STATION','DARK DIMENSION'];
  static const bossesTr=['SİBER MUHAFIZ','BUZ CANAVARI','ORMAN KRALİÇESİ','ALEV EJDERİ','UZAY HÜKÜMDARI','GÖLGE HÜKÜMDARI'];
  static const bossesEn=['CYBER GUARDIAN','ICE BEAST','FOREST QUEEN','FIRE DRAGON','SPACE OVERLORD','SHADOW KING'];
  static const colors=[Color(0xFFD16EFF),Color(0xFF55D6FF),Color(0xFF5CFF9A),Color(0xFFFF894E),Color(0xFF5DC8FF),Color(0xFFBD78FF)];
  bool get tr=>widget.appState.languageCode=='tr';
  String loc(String a,String b)=>tr?a:b;
  Color get color=>colors[battle.world];
  @override void initState(){
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    battle=AdventureCombat(widget.level);
    ticker=Timer.periodic(const Duration(milliseconds:100),(_){
      if(!mounted||paused||ending)return;
      setState((){
        battle.tick(100);
        if(flashFrames>0)flashFrames--;
      });
      if(battle.finished) _finish();
    });
  }
  @override void didChangeAppLifecycleState(AppLifecycleState state){
    if(state!=AppLifecycleState.resumed&&mounted&&!paused)setState(()=>paused=true);
  }
  @override void dispose(){ticker?.cancel();WidgetsBinding.instance.removeObserver(this);super.dispose();}
  void _move(int direction){
    if(paused||ending)return;
    setState(()=>battle.move(direction));
    HapticFeedback.selectionClick();
  }
  void _use(CombatMove kind){
    if(paused||ending||!battle.canUse(kind))return;
    setState((){
      battle.use(kind);flashFrames=4;
      flash=switch(kind){
        CombatMove.sword=>'KILIÇ',CombatMove.power=>'BÜYÜ',
        CombatMove.ultimate=>'FIRTINA',CombatMove.shield=>'KALKAN'
      };
    });
    HapticFeedback.lightImpact();
    if(battle.finished)_finish();
  }
  void _restart(int number)=>Navigator.of(context).pushReplacement(
    MaterialPageRoute<void>(builder:(_)=>AdventureCombatScreen(
      appState:widget.appState,level:number)));
  Future<void> _finish()async{
    if(ending||!mounted)return;
    ending=true;ticker?.cancel();
    final won=battle.won,stars=battle.stars,n=widget.level;
    int reward=0;
    try{
      reward=await widget.appState.completeAdventureLevel(
        level:n,reward:won?adventureLevelFor(n).reward:0,
        score:battle.score,completed:won,stars:won?stars:null);
    }catch(error){debugPrint('Adventure save failure: '+error.toString());}
    if(!mounted)return;
    await showDialog<void>(context:context,barrierDismissible:false,
      builder:(dialogContext)=>Dialog(
        backgroundColor:const Color(0xF5061329),
        shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(20),
          side:BorderSide(color:won?color:Colors.redAccent)),
        child:Padding(padding:const EdgeInsets.all(20),child:Column(
          mainAxisSize:MainAxisSize.min,children:[
          Icon(won?Icons.emoji_events_rounded:Icons.heart_broken_rounded,
            size:50,color:won?const Color(0xFFFFD36C):Colors.redAccent),
          const SizedBox(height:9),
          Text(won?loc('ZAFER!','VICTORY!'):loc('YENİLGİ','DEFEAT'),
            style:const TextStyle(fontSize:24,fontWeight:FontWeight.w900)),
          Text(loc('BÖLÜM ','LEVEL ')+n.toString()),
          if(won)Row(mainAxisAlignment:MainAxisAlignment.center,
            children:List<Widget>.generate(3,(i)=>Icon(
              i<stars?Icons.star_rounded:Icons.star_border_rounded,
              color:const Color(0xFFFFD36C),size:33))),
          const SizedBox(height:13),
          Text(loc('Toplam hasar: ','Damage: ')+battle.score.toString()),
          Text(loc('Kalan can: ','Health: ')+battle.playerHp.toString()+'/1000'),
          if(won)Text('+ '+reward.toString()+' '+loc('ALTIN','COINS'),
            style:const TextStyle(color:Color(0xFFFFD36C),fontWeight:FontWeight.w900)),
          const SizedBox(height:17),
          FilledButton(onPressed:(){
            Navigator.of(dialogContext).pop();
            _restart(won&&n<60?n+1:n);
          },child:Text(won&&n<60?loc('SONRAKİ BÖLÜM','NEXT LEVEL'):loc('TEKRAR DENE','RETRY'))),
          TextButton(onPressed:(){
            Navigator.of(dialogContext).pop();Navigator.of(context).pop();
          },child:Text(loc('DÜNYA HARİTASI','WORLD MAP'))),
        ]))),
    );
  }
  BoxDecoration _glass()=>BoxDecoration(
    color:const Color(0xCD06142C),borderRadius:BorderRadius.circular(16),
    border:Border.all(color:color.withValues(alpha:.65),width:1.2),
    boxShadow:const [BoxShadow(color:Color(0x56000000),blurRadius:12)]);
  Widget _tag(IconData icon,String value,{VoidCallback? tap})=>InkWell(
    onTap:tap,borderRadius:BorderRadius.circular(12),child:Container(
      padding:const EdgeInsets.symmetric(horizontal:9,vertical:7),
      decoration:_glass(),child:Row(mainAxisSize:MainAxisSize.min,children:[
        Icon(icon,color:color,size:22),const SizedBox(width:4),
        Text(value,style:const TextStyle(color:Colors.white,
          fontSize:11,fontWeight:FontWeight.w900))])));
  Widget _ability(CombatMove kind,IconData icon,String name,bool narrow){
    final ready=battle.canUse(kind);
    final cost=switch(kind){CombatMove.sword=>0,CombatMove.power=>25,
      CombatMove.ultimate=>60,CombatMove.shield=>18};
    return Expanded(child:Padding(padding:const EdgeInsets.symmetric(horizontal:3),
      child:Semantics(label:name,button:true,child:InkWell(
        borderRadius:BorderRadius.circular(12),
        onTap:ready&&!paused?()=>_use(kind):null,
        child:Container(height:narrow?76:82,decoration:BoxDecoration(
          color:const Color(0xE0091832),
          borderRadius:BorderRadius.circular(12),
          border:Border.all(color:ready?color:Colors.white24)),
          child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
            Icon(icon,size:narrow?26:32,color:ready?color:Colors.white38),
            const SizedBox(height:4),
            Text(name,maxLines:1,overflow:TextOverflow.ellipsis,
              style:TextStyle(fontSize:narrow?9:10,
                fontWeight:FontWeight.w900,color:ready?Colors.white:Colors.white54)),
            Text(battle.cooldown(kind)>0
                ?(battle.cooldown(kind)/1000).ceil().toString()+'s'
                :cost==0?'⚡ +10':'⚡ '+cost.toString(),
                style:const TextStyle(fontSize:10,color:Colors.white70))
          ]))))));
  }
  @override Widget build(BuildContext context){
    final narrow=MediaQuery.of(context).size.width<380;
    final theme=gameThemes.firstWhere((t)=>t.id==widget.appState.themeId,
      orElse:()=>gameThemes.first);
    return Scaffold(backgroundColor:theme.backgroundBottom,body:SafeArea(
      child:Stack(fit:StackFit.expand,children:[
        Image.asset('assets/images/adventure_battles/world_'+battle.world.toString()+'.webp',
          fit:BoxFit.cover,filterQuality:FilterQuality.medium,
          errorBuilder:(_,__,___)=>Image.asset(
            AdventureWorldBackdrop.assetFor(battle.world),fit:BoxFit.cover)),
        const DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(
          begin:Alignment.topCenter,end:Alignment.bottomCenter,
          colors:[Color(0xB0061127),Color(0x06061127),Color(0x08040A19),Color(0xF0050C1F)],
          stops:[0,.24,.65,1]))),
        Column(children:[
          Row(children:[
            IconButton(onPressed:()=>Navigator.of(context).pop(),
              icon:const Icon(Icons.arrow_back_ios_new_rounded,color:Colors.white)),
            Expanded(child:Column(children:[
              Text(tr?worldsTr[battle.world]:worldsEn[battle.world],
                maxLines:1,overflow:TextOverflow.ellipsis,
                style:TextStyle(color:color,fontSize:narrow?15:17,
                  letterSpacing:1,fontWeight:FontWeight.w900)),
              Text(loc('BÖLÜM ','LEVEL ')+widget.level.toString()+
                ' • '+loc('SKOR ','SCORE ')+battle.score.toString(),
                style:const TextStyle(fontSize:11,color:Colors.white70)),
            ])),
            IconButton(onPressed:()=>setState(()=>paused=!paused),
              icon:const Icon(Icons.pause_rounded,color:Colors.white,size:27)),
          ]),
          Container(margin:const EdgeInsets.symmetric(horizontal:11),
            padding:const EdgeInsets.all(10),decoration:_glass(),child:Column(children:[
              Row(children:[
                Icon(Icons.warning_amber_rounded,color:color,size:19),
                const SizedBox(width:7),
                Expanded(child:Text(tr?bossesTr[battle.world]:bossesEn[battle.world],
                  style:const TextStyle(fontSize:14,fontWeight:FontWeight.w900))),
                Text(battle.bossHp.toString()+'/'+battle.bossMaxHp.toString(),
                  style:const TextStyle(fontSize:10,color:Colors.white70)),
              ]),
              const SizedBox(height:6),
              ClipRRect(borderRadius:BorderRadius.circular(8),
                child:LinearProgressIndicator(value:battle.bossFraction,minHeight:10,
                  backgroundColor:Colors.white12,
                  valueColor:const AlwaysStoppedAnimation<Color>(Color(0xFFFF4A5C)))),
            ])),
          Expanded(child:LayoutBuilder(builder:(ctx,c)=>GestureDetector(
            behavior:HitTestBehavior.translucent,
            onHorizontalDragEnd:(details){
              final v=details.primaryVelocity??0.0;
              if(v.abs()>100)_move(v>0?1:-1);
            },child:Stack(children:[
              Positioned(top:8,left:9,child:_tag(Icons.bolt_rounded,
                battle.energy.toString()+'/100')),
              if(battle.dangerLane>=0)Positioned(
                left:c.maxWidth*battle.dangerLane/3,
                bottom:13,width:c.maxWidth/3,height:61,
                child:Container(margin:const EdgeInsets.all(4),
                  decoration:BoxDecoration(
                    color:const Color(0x66FF2640),borderRadius:BorderRadius.circular(13),
                    border:Border.all(color:Colors.redAccent,width:2)),
                  child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
                    const Icon(Icons.warning_rounded,color:Colors.white),
                    Text(loc('KAÇ!','DODGE!'),
                      style:const TextStyle(color:Colors.white,fontSize:10,
                        fontWeight:FontWeight.w900))]))),
              if(flashFrames>0)Center(child:IgnorePointer(child:Container(
                padding:const EdgeInsets.all(12),decoration:_glass(),
                child:Text(flash,style:const TextStyle(
                  color:Colors.white,fontSize:19,fontWeight:FontWeight.w900))))),
              Positioned(bottom:6,left:c.maxWidth*(battle.lane+.5)/3-18,
                child:Container(width:36,height:8,decoration:BoxDecoration(
                  color:color,shape:BoxShape.circle,
                  boxShadow:[BoxShadow(color:color,blurRadius:20)]))),
              Positioned(bottom:74,left:7,child:_tag(
                Icons.chevron_left_rounded,loc('SOL','LEFT'),tap:()=>_move(-1))),
              Positioned(bottom:74,right:7,child:_tag(
                Icons.chevron_right_rounded,loc('SAĞ','RIGHT'),tap:()=>_move(1))),
            ])))),
          Container(margin:const EdgeInsets.fromLTRB(11,0,11,7),padding:const EdgeInsets.all(9),
            decoration:_glass(),child:Row(children:[
              const Icon(Icons.favorite_rounded,color:Colors.redAccent),
              const SizedBox(width:7),
              Expanded(child:ClipRRect(borderRadius:BorderRadius.circular(8),
                child:LinearProgressIndicator(value:battle.heroFraction,minHeight:12,
                  backgroundColor:Colors.white12,
                  valueColor:const AlwaysStoppedAnimation<Color>(Color(0xFFFF4058))))),
              const SizedBox(width:7),
              Text(battle.playerHp.toString()+'/1000',
                style:const TextStyle(fontSize:11,fontWeight:FontWeight.w900)),
            ])),
          Container(margin:const EdgeInsets.fromLTRB(8,0,8,8),
            padding:const EdgeInsets.fromLTRB(5,8,5,8),decoration:_glass(),
            child:Column(mainAxisSize:MainAxisSize.min,children:[
              Row(children:[
                _ability(CombatMove.sword,Icons.gavel_rounded,loc('SALDIR','ATTACK'),narrow),
                _ability(CombatMove.power,Icons.auto_awesome_rounded,loc('BÜYÜ','MAGIC'),narrow),
                _ability(CombatMove.ultimate,Icons.blur_circular_rounded,loc('FIRTINA','BURST'),narrow),
                _ability(CombatMove.shield,Icons.shield_rounded,loc('KALKAN','SHIELD'),narrow),
              ]),
              const SizedBox(height:6),
              Text(loc('Saldır • Enerji biriktir • Kırmızı bölgeden kaç',
                'Attack • Charge power • Dodge red zones'),
                style:const TextStyle(fontSize:10,color:Colors.white70),
                overflow:TextOverflow.ellipsis,maxLines:1)
            ])),
        ]),
        if(paused)Positioned.fill(child:ColoredBox(
          color:const Color(0xD8050D20),child:Center(child:Column(
            mainAxisSize:MainAxisSize.min,children:[
            const Icon(Icons.pause_circle_filled_rounded,size:66,color:Colors.white),
            Text(loc('DURAKLATILDI','PAUSED'),
              style:const TextStyle(fontSize:24,fontWeight:FontWeight.w900)),
            const SizedBox(height:12),
            FilledButton(onPressed:()=>setState(()=>paused=false),
              child:Text(loc('DEVAM ET','RESUME'))),
            TextButton(onPressed:()=>Navigator.of(context).pop(),
              child:Text(loc('DÜNYA HARİTASI','WORLD MAP'))),
          ])))),
      ])));
  }
}