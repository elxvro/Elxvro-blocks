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
    backgroundTop: Color(0xFF0B2835),
    backgroundBottom: Color(0xFF02080D),
    board: Color(0xD9122530),
    cell: Color(0xFF183847),
    block: Color(0xFF4CC7E8),
    blockAccent: Color(0xFFE8FCFF),
  ),
  GameThemeData(
    id: 'night',
    name: 'Dal',
    subtitle: 'Sıcak ahşap • doğal dal dokusu',
    material: ThemeMaterial.wood,
    audioProfile: 'wood',
    backgroundTop: Color(0xFF2B1C10),
    backgroundBottom: Color(0xFF080503),
    board: Color(0xFF28180D),
    cell: Color(0xFF3B2515),
    block: Color(0xFFD28A3F),
    blockAccent: Color(0xFFFFE0A1),
  ),
  GameThemeData(
    id: 'marble',
    name: 'Taş',
    subtitle: 'Oyulmuş kaya • tok ve güçlü',
    material: ThemeMaterial.stone,
    audioProfile: 'stone',
    backgroundTop: Color(0xFF26303B),
    backgroundBottom: Color(0xFF070A0E),
    board: Color(0xFF222A32),
    cell: Color(0xFF343E48),
    block: Color(0xFF8796A4),
    blockAccent: Color(0xFFEAF4FF),
  ),
  GameThemeData(
    id: 'fire',
    name: 'Yaprak',
    subtitle: 'Canlı yeşil • yumuşak doğa hissi',
    material: ThemeMaterial.leaf,
    audioProfile: 'leaf',
    backgroundTop: Color(0xFF123B24),
    backgroundBottom: Color(0xFF031008),
    board: Color(0xFF10301D),
    cell: Color(0xFF1A4B2B),
    block: Color(0xFF45B765),
    blockAccent: Color(0xFFD7FFB6),
  ),
  GameThemeData(
    id: 'nature',
    name: 'Kristal',
    subtitle: 'Mor-mavi kırınım • parlak yüzey',
    material: ThemeMaterial.crystal,
    audioProfile: 'crystal',
    backgroundTop: Color(0xFF21164A),
    backgroundBottom: Color(0xFF05030D),
    board: Color(0xFF211B48),
    cell: Color(0xFF322A66),
    block: Color(0xFF806CFF),
    blockAccent: Color(0xFF92F6FF),
  ),
  GameThemeData(
    id: 'aurora',
    name: 'Mermer Altın',
    subtitle: 'Siyah mermer • sıcak altın damar',
    material: ThemeMaterial.marble,
    audioProfile: 'marble',
    backgroundTop: Color(0xFF241D16),
    backgroundBottom: Color(0xFF050403),
    board: Color(0xFF211D1A),
    cell: Color(0xFF332E2A),
    block: Color(0xFFD5B064),
    blockAccent: Color(0xFFFFF0BE),
  ),
];
