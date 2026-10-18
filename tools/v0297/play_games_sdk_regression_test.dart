import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:elxvro_blocks/services/play_games_service.dart';
import 'package:elxvro_blocks/services/play_games_ids.dart';

void main() {
  test('Play Games SDK and Android native SDK version are pinned', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    expect(pubspec, contains('games_services: 5.3.0'));
    expect(pubspec, contains('games_services_platform_interface: 5.3.0'));
    expect(pubspec, contains('version: 0.29.7+71'));
    expect(gradle, contains('play-services-games-v2:22.1.0'));
  });

  test('Play Games sign in, leaderboards, and achievements API is preserved', () {
    final source=File('lib/services/play_games_service.dart').readAsStringSync();
    expect(source, contains('GamesServices.signIn()'));
    expect(source, contains('GamesServices.submitScore('));
    expect(source, contains('GamesServices.unlock('));
    expect(source, contains('GamesServices.showLeaderboards('));
    expect(source, contains('GamesServices.showAchievements()'));
    // Changes to provider IDs / credentials and saved progress are outside this release.
    final state=File('lib/app_state.dart').readAsStringSync();
    expect(state, contains('adventureUnlockedLevel'));
  });
}
