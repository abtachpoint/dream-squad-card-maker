# Dream Squad Card Maker — Clean Final Source

Package: `com.soikot.dreamsquad`
Version: `1.0.0+10`
Android: `compileSdk 36`, `targetSdk 36`, `minSdk 24`

## Final build workflow
Use the single Codemagic workflow:

`Dream Squad Clean Final Build`

The same build run creates:
- `app-release.apk` — signed release APK with Google AdMob test rewarded ads for phone testing.
- `app-release.aab` — signed release AAB with the real rewarded AdMob unit for Play Console.

The Android platform is regenerated cleanly from the current Flutter stable template during the build, then explicitly configured for API 36. This avoids carrying old generated Android files between builds.

## Connected services already configured in source
- Firebase project: Dream Squad Card Maker
- Android package: `com.soikot.dreamsquad`
- Google + Email/Password Firebase Authentication
- Updated `google-services.json` with the release SHA-1 OAuth client
- Firestore account/coin data
- AdMob App ID and rewarded unit
- Google Play Billing / consumable coin product IDs

IAP product IDs already used by the app:
- `coins_100`
- `coins_250`
- `coins_550`
- `coins_1200`
- `coins_2500`

Create those exact IDs in Play Console after the AAB is accepted. No code change is needed just to create the products.

## Card system
14 separate templates are included:

Free Pack:
- Base Card
- POTW
- POTM

Premium Pack:
- Epic Type 1
- Show Time
- Epic Type 2A
- Legendary
- Epic Type 2B

Big Time Pack:
- Big Time Type 1
- Big Time Type 2
- Big Time Type 3
- Big Time Type 4
- Big Time Type 5
- Old Big Time

Final booster rules are applied per template: 0 = hidden, 1 = one active badge, 2 = two active badges.

## Background removal
Player photos use on-device ML Kit selfie segmentation. Club logo and flag removal uses a local edge-connected background remover suitable for simple/solid backgrounds. Crop/adjust is available before and after uploads. No paid background-removal API is used.

## Coin rules
- Starter balance: 40 coins
- Daily reward: 10 coins
- Rewarded ad: 5 coins
- Rewarded ad daily limit: 2
- Free Pack: free
- Premium Pack: 15 coins per new card
- Big Time Pack: 25 coins per new card
- Editing an already saved card does not charge again

## Important GitHub upload note
Upload the contents of this project folder to the repository root. Do not upload the ZIP itself as the project.

The repo root should contain at least:
- `lib/`
- `assets/`
- `tool/`
- `pubspec.yaml`
- `codemagic.yaml`
- `analysis_options.yaml`

There is intentionally no committed `android/` folder. `tool/prepare_android.sh` creates a fresh Android platform during every Codemagic build, pins API 36, installs the Firebase/AdMob config, and applies the Codemagic signing key.
