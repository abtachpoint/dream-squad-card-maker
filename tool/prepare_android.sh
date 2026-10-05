#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Generating a clean Flutter Android platform..."
flutter create --platforms=android --org com.soikot --project-name dream_squad_card_maker "$TMP/bootstrap"
rm -rf "$ROOT/android"
cp -R "$TMP/bootstrap/android" "$ROOT/android"
cp "$ROOT/tool/google-services.json" "$ROOT/android/app/google-services.json"

python3 - "$ROOT" <<'PY'
from pathlib import Path
import re, sys
root = Path(sys.argv[1])
android = root / 'android'
app = android / 'app'

# Plugin management: add Google Services beside the Flutter-generated Android plugins.
settings = android / 'settings.gradle.kts'
s = settings.read_text()
plugin_line = 'id("com.google.gms.google-services") version "4.4.2" apply false'
if plugin_line not in s:
    marker = 'id("com.android.application")'
    idx = s.find(marker)
    if idx < 0:
        raise SystemExit('Could not find Android application plugin in settings.gradle.kts')
    line_end = s.find('\n', idx)
    s = s[:line_end + 1] + '    ' + plugin_line + '\n' + s[line_end + 1:]
settings.write_text(s)

# App Gradle configuration: package, API 36, Firebase and Codemagic release signing.
build = app / 'build.gradle.kts'
s = build.read_text()
if 'id("com.google.gms.google-services")' not in s:
    s = s.replace(
        'id("dev.flutter.flutter-gradle-plugin")',
        'id("dev.flutter.flutter-gradle-plugin")\n    id("com.google.gms.google-services")',
    )

s = s.replace('com.soikot.dream_squad_card_maker', 'com.soikot.dreamsquad')
s = re.sub(r'compileSdk\s*=\s*flutter\.compileSdkVersion', 'compileSdk = 36', s)
s = re.sub(r'minSdk\s*=\s*flutter\.minSdkVersion', 'minSdk = 24', s)
s = re.sub(r'targetSdk\s*=\s*flutter\.targetSdkVersion', 'targetSdk = 36', s)

if 'CM_KEYSTORE_PATH' not in s:
    signing = '''
    signingConfigs {
        create("release") {
            storeFile = file(System.getenv("CM_KEYSTORE_PATH"))
            storePassword = System.getenv("CM_KEYSTORE_PASSWORD")
            keyAlias = System.getenv("CM_KEY_ALIAS")
            keyPassword = System.getenv("CM_KEY_PASSWORD")
        }
    }
'''
    s = s.replace('\n    buildTypes {', signing + '\n    buildTypes {')

s = s.replace(
    'signingConfig = signingConfigs.getByName("debug")',
    'signingConfig = signingConfigs.getByName("release")',
)
build.write_text(s)

# Manifest: AdMob, network access, app label and image cropper activity.
manifest = app / 'src' / 'main' / 'AndroidManifest.xml'
ms = manifest.read_text()
ms = ms.replace('android:label="dream_squad_card_maker"', 'android:label="Dream Squad Card Maker"')
manifest_tag = '<manifest xmlns:android="http://schemas.android.com/apk/res/android">'
if 'android.permission.INTERNET' not in ms:
    ms = ms.replace(manifest_tag, manifest_tag + '\n    <uses-permission android:name="android.permission.INTERNET" />')

admob = '''
        <meta-data
            android:name="com.google.android.gms.ads.APPLICATION_ID"
            android:value="ca-app-pub-1379059201302335~9775813971" />'''
if 'com.google.android.gms.ads.APPLICATION_ID' not in ms:
    ms = ms.replace('\n    </application>', admob + '\n    </application>')

ucrop = '''
        <activity
            android:name="com.yalantis.ucrop.UCropActivity"
            android:screenOrientation="portrait"
            android:theme="@style/Theme.AppCompat.Light.NoActionBar" />'''
if 'com.yalantis.ucrop.UCropActivity' not in ms:
    ms = ms.replace('\n    </application>', ucrop + '\n    </application>')
manifest.write_text(ms)

# Package-matching MainActivity with gallery export channel.
kotlin_root = app / 'src' / 'main' / 'kotlin'
if kotlin_root.exists():
    for p in kotlin_root.rglob('MainActivity.kt'):
        p.unlink()
target = kotlin_root / 'com' / 'soikot' / 'dreamsquad' / 'MainActivity.kt'
target.parent.mkdir(parents=True, exist_ok=True)
target.write_text((root / 'tool' / 'MainActivity.kt').read_text())

print('Android configured: compileSdk=36, targetSdk=36, minSdk=24, package=com.soikot.dreamsquad')
PY

echo "Clean Android platform is ready."
