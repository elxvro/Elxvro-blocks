from pathlib import Path
p = Path('build_source/test/v0389_game_over_stalled_save_test.dart')
s = p.read_text()
old = "      await tester.pumpWidget(const SizedBox.shrink());\n      state.dispose();"
new = """      await tester.pumpWidget(const SizedBox.shrink());
      // v0.38.20 bounds Play Games authentication to 9/22 seconds.
      // Exhaust both pending mock SDK timers to verify a late response
      // cannot corrupt game-over state after the route has disposed.
      await tester.pump(const Duration(seconds: 25));
      expect(tester.takeException(), isNull);
      state.dispose();"""
assert s.count(old) == 1, "unexpected legacy game-over test shape"
p.write_text(s.replace(old,new))
print('v0389 stalled-save test now observes bounded Play Games timers')
