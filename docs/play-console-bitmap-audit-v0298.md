# ELXVRO Blocks v0.29.8 (72) — Play Console native bitmap audit

## Scope
Inherited v0.29.6 edge-to-edge and v0.29.5 Adventure regression fixes;
updated from v0.29.7 to **games_services 5.3.0** with
**play-services-games-v2 22.1.0**, **play-services-base 18.11.0** and
**play-services-basement 18.12.0**.

The GitHub workflow resolves dependency versions using Gradle's release
runtime dependency graph, runs Flutter analyze/tests, verifies the
compiled MainActivity deprecated color APIs are absent, and signs an
APK and AAB.

## DEX comparison of signed release APKs
Native `BitmapFactory` method IDs were parsed from `classes.dex`.

| Build | Google image loader | Bitmap decode call without Options |
|-------|---------------------|------------------------------------|
| 0.29.6 (70) | present | `decodeFileDescriptor(FileDescriptor)` |
| 0.29.7 (71) | present | `decodeFileDescriptor(FileDescriptor)` |
| 0.29.8 (72) | present | `decodeStream(InputStream)` |

`decodeByteArray(byte[],int,int,Options)` is also referenced by another
part of the SDK, but it does not remove the unparameterized decode in
the Google image loader.

The Google Play services `LoadBitmapFromDiskRunnable` marker and
`com/google/android/gms/common/images` remain in 0.29.8. These belong to a
third-party Google library, not to the Flutter game artwork decoder.
**Do not claim the Play Console under-sampling warning is fixed.**
The new APK no longer references `decodeFileDescriptor`, but it still
references `decodeStream(InputStream)` without sampling Options.

## Validation
- GitHub Actions: successful analysis, tests, signed APK, signed AAB.
- APK/AAB SHA-256 digests verified after artifact download.
- Player saves, purchases, score submission APIs, visuals and gameplay
  were not intentionally changed during this SDK update.
- Live Google Play Games sign-in and device layout need physical
  device validation.
- Upload **build 72** to an appropriate Play testing track and check
  its own Play Console recommendations; previous build 68 findings
  remain visible in history.
- If under-sampling advisory persists, treat it as an upstream Google
  Play services limitation; avoid bytecode editing or excluding SDK
  image classes because these could break Play Games overlays/profile
  artwork. Monitor SDK release notes.
