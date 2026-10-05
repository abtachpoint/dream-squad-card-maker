# Dream Squad Card Maker — Trial 0.1.0

Android package: `com.soikot.dreamsquad`

This is a trial/prototype Flutter project made for GitHub + Codemagic APK testing.

## Included in this trial

- Local trial login UI: Google button + Email/Password
- Main home with eFootball active; EA/FC and DLS marked Coming Soon
- User-provided eFootball cover image
- 14 separate card templates grouped into:
  - Free Pack: 3
  - Premium Pack: 5
  - Big Time Pack: 6
- Editable main rating, player name and position
- 1 / 2 / 4 player-photo slot behavior depending on template
- User-uploaded club logo and flag placeholders
- POTW/POTM custom-background upload
- Fixed/locked background behavior on locked templates
- Booster-slot display based on template
- Coin balance
- Daily reward: +10
- Demo rewarded ad: +5, max 2/day
- Premium card cost: 15 coins
- Big Time card cost: 25 coins
- Saved card project copy in app storage during the current app install
- Android image export bridge to `Pictures/Dream Squad Card Maker`
- Squad builder with 5 formations and 3 field styles
- Profile footer: `Developer: ABIR AHOMOD`

## Intentionally NOT live in this first trial

These need production credentials/config and are left as trial placeholders so the first APK can be tested without investment:

- Firebase Google sign-in and real Email/Password authentication
- Cloud sync / Firestore
- Real AdMob rewarded ads
- Real Google Play Billing / IAP products
- Automatic ML background removal
- Manual crop/erase/restore editor
- EA/FC and DLS card systems

## Build with Codemagic

1. Upload this project folder to a GitHub repository.
2. Connect the repository in Codemagic.
3. Codemagic will detect `codemagic.yaml`.
4. Run workflow **Dream Squad Trial APK**.
5. Download artifact: `app-release.apk`.

The workflow generates the Android platform files with Flutter, patches the application ID to `com.soikot.dreamsquad`, then builds the release APK.

## Local build

With Flutter installed:

```bash
./tool/bootstrap_android.sh
flutter pub get
flutter run
```

For a release APK:

```bash
flutter build apk --release
```

## Important note before Play Store production

The eFootball cover image in `assets/images/efootball_cover.webp` is the user-supplied trial artwork. Review image/brand rights before a public Play Store release. The generated card templates themselves use original Flutter-drawn layouts and do not include the top-right eFootball mark or the small extra rating.
