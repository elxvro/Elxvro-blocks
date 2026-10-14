# ELXVRO Blocks v0.28.5 — AdMob integration requirements

## Safety and user experience
- Use Google Mobile Ads Flutter SDK (google_mobile_ads) and official Android manifest App ID.
- Build in test-ad mode by default. Do not use production ad-unit IDs until supplied and verified.
- Rewarded ads: optional, grant a bounded local gameplay reward only after the SDK's onUserEarnedReward callback; prevent double rewards per impression.
- Interstitials: only between completed rounds, never mid-game or at startup, and no more than once per 3 completed rounds with a time-based cooldown.
- Never show ads during billing checkout, consent dialogs, or while offline.
- Implement EEA/UK consent and privacy options with Google's UMP SDK before ad requests; respect age/family policy declarations.
- Ads must not replace the paid supporter badge or interfere with existing saves, in-game earned coins, and progression.
- Separate release build configuration for test and production AdMob IDs.
- Do not ship live ad IDs or make live-ad claims without device and Play Console verification.

## Release gates
1. Compile and static analysis.
2. Flutter tests for reward callback exactly once and interstitial cooldown.
3. Android signed APK and Play AAB via existing GitHub Actions.
4. Device test, consent test and AdMob app verification before production ads.
