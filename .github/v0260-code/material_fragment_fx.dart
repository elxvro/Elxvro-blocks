import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/game_theme.dart';

/// Fragment images animate only during drag feedback or placement. No per-frame
/// canvas face drawing; uses shared asset decoding and a single local ticker.
class MaterialFragmentFx extends StatefulWidget {
  const MaterialFragmentFx({super.key,required this.material,this.trailing=true});
  final ThemeMaterial material;
  final bool trailing;
  @override
  State<MaterialFragmentFx> createState()=>_MaterialFragmentFxState();
}
class _MaterialFragmentFxState extends State<MaterialFragmentFx> with SingleTickerProviderStateMixin{
  late final AnimationController _controller=AnimationController(vsync:this,duration:Duration(milliseconds:widget.trailing?1150:560));
  @override
  void initState(){super.initState();if(widget.trailing){_controller.repeat();}else{_controller.forward();}}
  @override
  void didUpdateWidget(MaterialFragmentFx old){super.didUpdateWidget(old);if(old.trailing!=widget.trailing){
    _controller.duration=Duration(milliseconds:widget.trailing?1150:560);
    if(widget.trailing){_controller.repeat();}else{_controller.forward(from:0);}
  }}
  @override
  void dispose(){_controller.dispose();super.dispose();}
  @override
  Widget build(BuildContext context)=>IgnorePointer(child:LayoutBuilder(builder:(context,constraints){
    final w=constraints.maxWidth,h=constraints.maxHeight;
    if(!w.isFinite||!h.isFinite||w<=0||h<=0)return const SizedBox.shrink();
    return AnimatedBuilder(animation:_controller,builder:(context,_)=>Stack(clipBehavior:Clip.none,children:<Widget>[
      for(var i=0;i<8;i++) _fragment(w,h,i),
    ]));
  }));
  Widget _fragment(double w,double h,int i){
    final lifetime=widget.trailing?(_controller.value+i/8)%1.0:(_controller.value-i*.053).clamp(0.0,1.0).toDouble();
    final opacity=widget.trailing?(math.sin(lifetime*math.pi)*.87).clamp(0.0,1.0):((1-lifetime)*.94).clamp(0.0,1.0);
    final angle=i*math.pi*.7;
    final dx=widget.trailing?w*(.08+((i*13)%60)/100)-lifetime*w*.55:w*.5+math.cos(angle)*lifetime*(w*.54+14);
    final dy=widget.trailing?h*(.35+((i*11)%45)/100)+lifetime*lifetime*(h*.45+17):h*.5+math.sin(angle)*lifetime*(h*.48+17);
    final side=math.max(5.0,math.min(15.0,math.min(w,h)*(widget.trailing?.21:.28)*(.8+(i%3)*.2)));
    return Positioned(left:dx-side/2,top:dy-side/2,width:side,height:side,
      child:Opacity(opacity:opacity.toDouble(),child:Transform.rotate(
        angle:(i%2==0?1:-1)*lifetime*(1.5+i*.2),
        child:Image.asset('assets/images/material_shards/${widget.material.name}_${i%5}.webp',
          fit:BoxFit.contain,filterQuality:FilterQuality.low,gaplessPlayback:true)
      )));
  }
}
