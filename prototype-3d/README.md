# ELXVRO Blocks 3D Prototype v0.11.0

This branch is an isolated Godot 4.3 prototype. It does not replace the current Flutter release build.

Prototype features:
- Perspective 3D board and physical block depth
- Drag-and-drop mobile controls
- 8x8 puzzle grid with row/column clears
- Score and combo system
- Six runtime themes: Glass, Stone, Wood, Leaf, Crystal, Marble
- Theme-specific PBR-style roughness, metallic, transparency and emission values
- Placement lift, snap animation, line-clear break animation, camera impulse
- Valid/invalid placement ghost
- Three-piece tray and automatic refill
- Basic game-over detection and restart UI

The APK is intentionally a debug-signed prototype for device testing. Production Play signing remains on the existing release workflow.

Build trigger: GitHub Actions prototype APK.
