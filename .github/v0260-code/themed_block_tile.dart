import 'package:flutter/material.dart';
import '../models/game_theme.dart';

/// Pre-rendered bitmap artwork; the gameplay board no longer draws block faces.
class ThemedBlockTile extends StatelessWidget {
  const ThemedBlockTile({super.key,required this.material,required this.base,required this.accent,this.flash=0});
  final ThemeMaterial material;
  final Color base;
  final Color accent;
  final double flash;
  static String artworkPath(ThemeMaterial material) => 'assets/images/material_tiles/${material.name}.webp';
  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: Stack(fit:StackFit.expand,clipBehavior:Clip.none,children:<Widget>[
      Image.asset(artworkPath(material),fit:BoxFit.fill,filterQuality:FilterQuality.medium,gaplessPlayback:true,
        errorBuilder:(context,error,stack)=>DecoratedBox(decoration:BoxDecoration(
          color:base,border:Border.all(color:accent.withValues(alpha:.5)),borderRadius:BorderRadius.circular(4)))),
      if(flash>0) DecoratedBox(decoration:BoxDecoration(
        color:Colors.white.withValues(alpha:(flash*.36).clamp(0.0,.65)),
        borderRadius:BorderRadius.circular(4),
        border:Border.all(color:accent.withValues(alpha:(flash*.8).clamp(0.0,1.0)),width:1.3)))
    ]),
  );
}
