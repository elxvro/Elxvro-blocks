from pathlib import Path
import sys
root = Path(sys.argv[1])
file = root / 'lib/widgets/three_game_rankings.dart'
s = file.read_text()
assert s.count('_result = _requestRanking();') == 3
assert 'int _rankingRequestSerial = 0;' not in s
assert 'FutureBuilder<OnlineRankingResult>(\n              future: _result,' in s
s = s.replace('  Future<PlayGamesPlayerSummary?>? _playerSummary;\n',
              '  Future<PlayGamesPlayerSummary?>? _playerSummary;\n  int _rankingRequestSerial = 0;\n')
s = s.replace('  Future<OnlineRankingResult> _requestRanking() async {',
              '  Future<OnlineRankingResult> _requestRanking(int serial) async {')
s = s.replace('    if (mounted && game == _game && period == _period) {',
              '    if (mounted && serial == _rankingRequestSerial &&\n'
              '        game == _game && period == _period) {')
s = s.replace('_result = _requestRanking();',
              '_result = _requestRanking(++_rankingRequestSerial);')
s = s.replace('FutureBuilder<OnlineRankingResult>(\n              future: _result,',
              'FutureBuilder<OnlineRankingResult>(\n'
              '              // Never reuse a previous leaderboard snapshot during tab changes.\n'
              '              key: ValueKey<String>(\n'
              "                'ranking_result_' + game.name + '_' + _period.name + '_' + _rankingRequestSerial.toString(),\n"
              '              ),\n'
              '              future: _result,')
assert s.count('ranking_result_') == 1
assert s.count('_requestRanking(++_rankingRequestSerial)') == 3
file.write_text(s)
pub = root / 'pubspec.yaml'
p = pub.read_text()
assert 'version: 0.38.18+126' in p
pub.write_text(p.replace('version: 0.38.18+126', 'version: 0.38.19+127'))

settings = root / 'lib/screens/settings_screen.dart'
label = settings.read_text()
assert 'v0.38.18  •' in label
settings.write_text(label.replace('v0.38.18  •', 'v0.38.19  •'))

# Historical release assertions should follow the current published version.
assertion_count = 0
for test_file in (root / 'test').glob('*.dart'):
    text = test_file.read_text()
    if 'version: 0.38.18+126' in text:
        assertion_count += text.count('version: 0.38.18+126')
        test_file.write_text(text.replace('version: 0.38.18+126',
                                          'version: 0.38.19+127'))
assert assertion_count >= 7, assertion_count
