import 'package:flutter/material.dart';

enum ThemeMaterial {
  glass,
  wood,
  stone,
  leaf,
  crystal,
  marble,
}

class GameThemeData {
  const GameThemeData({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.material,
    required this.audioProfile,
    required this.backgroundTop,
    required this.backgroundBottom,
    required this.board,
    required this.cell,
    required this.block,
    required this.blockAccent,
  });

  final String id;
  final String name;
  final String subtitle;
  final ThemeMaterial material;
  final String audioProfile;
  final Color backgroundTop;
  final Color backgroundBottom;
  final Color board;
  final Color cell;
  final Color block;
  final Color blockAccent;
}

// Kimlikler önceki sürümlerle uyumluluk için korunur. Böylece daha önce
// açılan temalar v0.9.7'da kaybolmaz; yalnızca görsel ve ses kimlikleri yenilenir.
const List<GameThemeData> gameThemes = <GameThemeData>[
  GameThemeData(
    id: 'classic',
    name: 'Cam',
    subtitle: 'Parlak buzlu cam • kristal tını',
    material: ThemeMaterial.glass,
    audioProfile: 'glass',
    backgroundTop: Color(0xFF13516B),
    backgroundBottom: Color(0xFF061923),
    board: Color(0xE51A3949),
    cell: Color(0xFF24576C),
    block: Color(0xFF63DDF7),
    blockAccent: Color(0xFFE8FCFF),
  ),
  GameThemeData(
    id: 'night',
    name: 'Dal',
    subtitle: 'Sıcak ahşap • doğal dal dokusu',
    material: ThemeMaterial.wood,
    audioProfile: 'wood',
    backgroundTop: Color(0xFF5A361B),
    backgroundBottom: Color(0xFF160C06),
    board: Color(0xFF3C2513),
    cell: Color(0xFF5A381E),
    block: Color(0xFFE8A356),
    blockAccent: Color(0xFFFFE0A1),
  ),
  GameThemeData(
    id: 'marble',
    name: 'Taş',
    subtitle: 'Oyulmuş kaya • tok ve güçlü',
    material: ThemeMaterial.stone,
    audioProfile: 'stone',
    backgroundTop: Color(0xFF435365),
    backgroundBottom: Color(0xFF121922),
    board: Color(0xFF35414C),
    cell: Color(0xFF4B5966),
    block: Color(0xFFA7B7C5),
    blockAccent: Color(0xFFEAF4FF),
  ),
  GameThemeData(
    id: 'fire',
    name: 'Yaprak',
    subtitle: 'Canlı yeşil • yumuşak doğa hissi',
    material: ThemeMaterial.leaf,
    audioProfile: 'leaf',
    backgroundTop: Color(0xFF1D6838),
    backgroundBottom: Color(0xFF081E10),
    board: Color(0xFF18452A),
    cell: Color(0xFF27643A),
    block: Color(0xFF62D17E),
    blockAccent: Color(0xFFD7FFB6),
  ),
  GameThemeData(
    id: 'nature',
    name: 'Kristal',
    subtitle: 'Mor-mavi kırınım • parlak yüzey',
    material: ThemeMaterial.crystal,
    audioProfile: 'crystal',
    backgroundTop: Color(0xFF3D2A83),
    backgroundBottom: Color(0xFF0E0927),
    board: Color(0xFF302660),
    cell: Color(0xFF463A86),
    block: Color(0xFF9B8CFF),
    blockAccent: Color(0xFF92F6FF),
  ),
  GameThemeData(
    id: 'aurora',
    name: 'Mermer Altın',
    subtitle: 'Siyah mermer • sıcak altın damar',
    material: ThemeMaterial.marble,
    audioProfile: 'marble',
    backgroundTop: Color(0xFF4B3B27),
    backgroundBottom: Color(0xFF130E09),
    board: Color(0xFF352E28),
    cell: Color(0xFF4B433B),
    block: Color(0xFFE8C77A),
    blockAccent: Color(0xFFFFF0BE),
  ),
];
