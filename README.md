# Dream Squad Card Maker — Update 1.1.0

Package: `com.soikot.dreamsquad`  
Version: `1.1.0+12`  
Android: `compileSdk 36`, `targetSdk 36`, `minSdk 24`

## Build workflow
Use the Codemagic workflow `Dream Squad Clean Final Build`.

One run creates:
- `app-release.apk` — signed release APK with Google rewarded test ads for phone testing.
- `app-release.aab` — signed release AAB with the live rewarded AdMob unit for Play Console.

The Android platform is regenerated during the build. `tool/prepare_android.sh` then applies API 36, Firebase/AdMob configuration, release signing, the exact package name, and a verified `MainActivity` path before compilation.

## Approved 14-card set
The in-app renderer targets the approved 14-card preview set instead of the previous flat/simple renderer. The canonical reference is kept in `design_reference/approved_14_card_reference.png`.


Free Pack:
1. Base Card
2. POTW
3. POTM

Premium Pack:
4. Epic Type 1
5. Epic Type 2A
6. Epic Type 2B
7. Show Time
8. Legendary

Big Time Pack:
9. Big Time Type 1
10. Big Time Type 2
11. Big Time Type 3
12. Big Time Type 4
13. Old Big Time
14. Special

## Card editor updates
- Drag player photos with one finger.
- Pinch player photos to zoom in/out.
- Drag and pinch player name.
- Drag and pinch rating/position block.
- Undo / Redo.
- Snap near center.
- Reset position controls.
- Photo layer controls: bring forward / send backward.
- Photo opacity control.
- Remove and replace uploaded photos, logo, and flag.
- Visible guidance: upload a transparent/background-removed PNG for best results.
- Draft autosave/restore for unfinished new cards.
- Full-screen clean preview.
- 4x high-resolution card export.
- Coin confirmation before creating paid cards; editing remains free.

## Squad Builder updates
- Fixed Formation and Custom Formation modes.
- Custom mode lets the user drag player cards freely with a finger.
- Custom positions can be locked or reset.
- Squad can be saved with any number from 1 to 11 field players; all 11 are not required.
- Fixed formations allow empty slots.
- Team name is centered independently of the team logo.
- Optional bench section (up to 7 players).
- Team logo, manager and custom background controls.
- Existing squads can be edited.
- Full-screen preview and 4x high-resolution export.

## Profile updates
- Privacy Policy link.
- About section.
- Rewarded-ad daily usage indicator.
- App version.
- `Developer: ABIR AHOMOD` footer.

The Privacy Policy page is included as `privacy-policy.html`. When GitHub Pages is enabled for the repository root, the app expects it at:

`https://abtachpoint.github.io/dream-squad-card-maker/privacy-policy.html`

## Coin rules
- Starter balance: 40 coins
- Daily reward: 10 coins
- Rewarded ad: 5 coins
- Rewarded ad daily limit: 2
- Free Pack: free
- Premium Pack: 15 coins per new card
- Big Time Pack: 25 coins per new card
- Editing an already saved card does not charge again

## Google Play Billing product IDs
- `coins_100`
- `coins_250`
- `coins_550`
- `coins_1200`
- `coins_2500`

## Upload note
Upload the project folder contents to the repository root. Do not upload the ZIP itself as the project.
