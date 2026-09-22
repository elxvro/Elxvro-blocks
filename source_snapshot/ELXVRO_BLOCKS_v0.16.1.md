# ELXVRO Blocks v0.16.1 — Line Clear Fix

Gameplay fix:
- Normal gameplay no longer injects Bomb, Row Clear or Column Clear pieces automatically.
- Refresh generates only normal pieces.
- A row/column is cleared only when it is completely filled during normal play.
- Special pieces remain available only through the explicit ÖZEL inventory action.
- Classic session keys were rotated so old auto-special trays are not restored after updating.
- Regression tests verify that incomplete rows stay intact and a completed row does not clear unrelated rows.

Version name: 0.16.1
Version code: 34
