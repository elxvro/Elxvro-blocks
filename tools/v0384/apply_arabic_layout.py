from pathlib import Path
import sys

root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(".")
main = root / "lib/main.dart"
src = main.read_text()
old = """          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations: widget.appState.performanceMode || MediaQuery.of(context).disableAnimations,
            ),
            child: child ?? const SizedBox.shrink(),
          ),"""
new = """          // Arabic localizes words, not the layout of a block-puzzle board.
          // WidgetsApp normally mirrors the full navigator for Locale('ar').
          // Keep buttons, board cells, rows and navigation in their original
          // positions; Arabic Unicode text is still rendered as Arabic.
          builder: (context, child) => Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                disableAnimations: widget.appState.performanceMode ||
                    MediaQuery.of(context).disableAnimations,
              ),
              child: child ?? const SizedBox.shrink(),
            ),
          ),"""
assert src.count(old) == 1, "Unexpected app shell, cannot safely patch"
main.write_text(src.replace(old, new))

manifest = root / "pubspec.yaml"
data = manifest.read_text()
assert data.count("version: 0.38.3+111") == 1
manifest.write_text(data.replace("version: 0.38.3+111", "version: 0.38.4+112"))

count = 0
for test_file in (root / "test").glob("*.dart"):
    content = test_file.read_text()
    if "version: 0.38.3+111" in content:
        count += content.count("version: 0.38.3+111")
        test_file.write_text(content.replace("version: 0.38.3+111",
                                              "version: 0.38.4+112"))
assert count == 7, f"Unexpected number of historic version checks: {count}"
(root / "V0384_RELEASE_NOTES.md").write_text(
    "# ELXVRO Blocks v0.38.4 (Build 112)\n\n"
    "- Arabic language text remains localized without mirroring the game board, menus or navigation.\n"
    "- Added real widget tests of Arabic home/game/settings, layout order and language switching.\n"
    "- Preserved Google Play Billing 8.0.0, Coin Plus monthly prepaid, and Play Games.\n"
    "- Two separate complete Flutter analyze/test rounds run before signed APK and AAB output.\n"
    "- Real-device manual testing is still required before a public rollout.\n"
)
print("Applied v0.38.4 Arabic LTR game-shell fix; 7 version checks updated")
