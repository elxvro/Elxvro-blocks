#!/usr/bin/env python3
"""Apply v0.28.4 supporter-only product policy to assembled v0.28.3 Flutter source."""
from pathlib import Path
import re

root = Path(__file__).resolve().parents[2]
billing = root / "lib/services/play_billing_service.dart"
source = billing.read_text()
start = source.index("  static const packs = <PlayProduct>[")
end = source.index("  ];", start) + len("  ];")
source = source[:start] + """  static const packs = <PlayProduct>[
    PlayProduct('elxvro_supporter_badge', 0, true),
  ];""" + source[end:]
assert "PlayProduct('elxvro_coins_" not in source
billing.write_text(source)

panel = root / "lib/widgets/coin_purchase_panel.dart"
source = panel.read_text()
# Delete the entire paid-coin storefront, leaving supporter badge checkout.
first = source.find("        _heading(Icons.toll_rounded")
last = source.find("        _heading(Icons.favorite_rounded", first)
if first < 0 or last <= first:
    raise SystemExit("Supporter panel layout changed; refusing unsafe rewrite")
source = source[:first] + source[last:]
# Remove obsolete explanatory text about the paid wallet.
source = re.sub(r"        Text\(isTr \? 'Oyun coinleri önce kullanılır\..*?fontSize: 11\)\),\n", "", source)
# Remove purchased-coin wallet preview section if present without altering game economy.
source = re.sub(r"          Text\(\s*account\.walletVerified\s*\?.*?style: const TextStyle\(color: Color\(0xFFFFD98B\), fontSize: 12\)\),\n", "", source, flags=re.S)
assert "COIN SATIN AL" not in source and "BUY COINS" not in source
panel.write_text(source)

# Version bump plus source-only tests with a hard-coded old expected version.
pubspec = root / "pubspec.yaml"
old = pubspec.read_text()
assert "version: 0.28.3+57" in old
pubspec.write_text(old.replace("version: 0.28.3+57", "version: 0.28.4+58"))
for test in (root / "test").glob("*.dart"):
    text = test.read_text()
    if "version: 0.28.3+57" in text:
        test.write_text(text.replace("version: 0.28.3+57", "version: 0.28.4+58"))
print('v0.28.4 source migration preflight complete')
