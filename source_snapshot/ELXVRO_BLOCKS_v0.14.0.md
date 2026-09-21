# ELXVRO Blocks v0.14.0 — Material Fidelity

This release continues the v0.13.0 material-response build without changing navigation, game modes, score rules, save state or core board logic.

## Changes
- Material-weighted contact shadows: stone and marble sit heavier on the board; glass/crystal remain sharp; leaf stays soft.
- Secondary specular pass on every block face for more physical lighting.
- Glass/crystal receive restrained prism reflections and sharper flash response.
- Marble receives a polished highlight; wood, stone and leaf keep material-appropriate matte/soft behavior.
- Clear/placement flash now uses material-specific color and intensity rather than one generic white flash.
- Board material overlays receive a matching ambient-light pass so blocks and board read as one scene.
- Existing v0.13.0 fracture engine, material audio, haptics and placement-settle animation are preserved.

## Stability scope
Menus, profile, missions, store, settings, modes and game-state logic remain intact.
