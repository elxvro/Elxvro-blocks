# Google Play Console Android 15 / Bitmap audit — v0.29.6

## Provenance
Google Play Console screenshot is for published 0.29.4 (68), not this build.

Inspected the signed v0.29.5 APK DEX. The minified
`com.elxvro.elxvro_blocks.MainActivity.onCreate` invokes
`android.view.Window.setStatusBarColor` and
`android.view.Window.setNavigationBarColor` due to release compiler
inlining AndroidX Core's `WindowCompat.enableEdgeToEdge` implementation.
This was verified from the DEX method references, not inferred from
Kotlin source.

## Fixed in v0.29.6
- Keep Flutter SystemUiMode.edgeToEdge and existing widget SafeArea.
- Remove explicit Flutter SystemUiOverlayStyle bar colors.
- Replace native helper with WindowCompat.setDecorFitsSystemWindows(window,false).
- Set system icon appearance via WindowInsetsControllerCompat.
- Add Flutter tests for Kotlin and Dart source regression.
- CI checks the signed APK's compiled MainActivity.onCreate invokes
  neither deprecated color setter.
- No modification to persisted save keys, game rules, design assets,
  Play Games configuration, or signing credentials.

## Remaining third-party advisory
The BitmapFactory warning method `q00.run` in the v0.29.5 release
DEX invokes `BitmapFactory.decodeFileDescriptor` without an Options
argument. This bytecode also references
`com.google.android.gms.common.images` and the
`LoadBitmapFromDiskRunnable` log string: Google Play Services' image
loader, not app-owned Flutter asset decoding.

We cannot safely substitute `inSampleSize` inside a closed-source
Google Play Services Android dependency from this repository.
The existing Flutter splash already has constrained cacheWidth/cacheHeight,
but that cannot fix a native Google SDK decoder.
Do NOT claim this warning is resolved merely by changing Flutter artwork.
Track upstream Play Services versions and compare the new Play Console
DEX warning report against the new uploaded bundle.

## Validation after publishing
Test Android 15 and 16 on gesture/three-button navigation:
status bar, camera cutout, modal dialogs, keyboard, bottom controls, and
app resume. Re-open Play Console > Android vitals > SDK/edge-to-edge
recommendations for build code 70. Previously published version 68
warnings will remain attached to that version.
