# Dream Squad Card Maker — FINAL 1.0.0

Android package: `com.soikot.dreamsquad`

This is the final Flutter source project prepared for GitHub + Codemagic.

## Included in this final source

- App name: **Dream Squad Card Maker**
- Real Firebase Authentication: Google + Email/Password
- Forgot password, logout and account deletion
- Firestore-backed coin balance and reward counters
- Daily reward: **+10 coins** once per day
- AdMob rewarded ads: **+5 coins**, maximum **2 per day**
- Test APK workflow uses Google's rewarded test ad
- Production AAB workflow uses the configured live rewarded ad unit
- Google Play Billing integration for consumable coin products:
  - `coins_100`
  - `coins_250`
  - `coins_550`
  - `coins_1200`
  - `coins_2500`
- eFootball section active; EA/FC and DLS shown as Coming Soon
- User-provided eFootball cover image
- **14 separate card designs** in 3 packs
  - Free Pack: Base, POTW, POTM
  - Premium Pack: Epic Type 1, Show Time, Epic Type 2A, Legendary, Epic Type 2B
  - Big Time Pack: Big Time Type 1–5 + Old Big Time
- Updated custom card renderer with distinct neon / green / purple / gold / blue / mechanical styles
- Large main rating editable; no extra upper rating or top-right season mark
- User-upload player photos, club logo and flag with visible empty placeholders
- Player cards support **1 / 2 / 4** photo slots depending on design
- On-device background removal using `native_cutout` (Android ML Kit subject segmentation)
- Crop / adjust controls for player photos, logo and flag
- POTW/POTM custom background upload; other defined backgrounds stay fixed
- Final booster rule: 0 / 1 / 2 according to template; every shown booster uses active styling
- Card cost: Free 0, Premium 15, Big Time 25; coin is charged only when creating a new card
- Saved cards can be edited later without another card charge
- My Cards: edit, duplicate, export, delete
- Squad Builder with 5 formations, player swapping by drag, captain mark, team name, club logo, manager info, custom background, save and export
- My Squads: duplicate, export, delete
- Smooth slide / fade / scale notices for warnings and rewards
- App icon + splash screen
- Profile footer: **Developer: ABIR AHOMOD**

## Firebase already prepared

The project contains the Firebase Android configuration for package `com.soikot.dreamsquad` in `tool/google-services.json`. The Codemagic bootstrap copies it to `android/app/google-services.json` during build.

Authentication providers expected in Firebase:
- Google
- Email/Password

Firestore is used for account coin/reward data. Card and squad image projects are stored locally on the user's device.

## Codemagic signing

Both workflows use the existing Codemagic Android signing reference:

`agecalculator_upload`

The upload-key SHA fingerprints already used in Firebase are the ones from that signing identity.

## Build options

### 1. Final Test APK
Run workflow:

**Dream Squad Final Test APK**

Artifact:

`build/app/outputs/flutter-apk/app-release.apk`

This is the same final app source, but it is compiled with Google's official rewarded-ad test unit so you can safely test ads.

### 2. Production AAB
Run workflow:

**Dream Squad Production AAB**

Artifact:

`build/app/outputs/bundle/release/app-release.aab`

This uses the configured live AdMob rewarded unit and is the file to upload to Google Play.

## After the first AAB is uploaded to Play Console

1. Open **Play Console → Setup / App integrity → App signing**.
2. Copy the **Play App Signing SHA-1 and SHA-256** fingerprints.
3. Add those fingerprints to the same Android app in Firebase (`com.soikot.dreamsquad`).
4. This normally does **not** require changing this Flutter source or rebuilding just to add the Play signing certificate.
5. Create/activate the five One-time Product IDs in Play Console using the exact IDs listed above.
6. Install the app from an eligible Play testing track to test real Google Play purchases.

Do not test your own live AdMob ads by repeatedly viewing/clicking them. Use the **Final Test APK** workflow for ad testing.
