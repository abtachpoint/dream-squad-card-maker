#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Creating Android platform files..."
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

# settings.gradle.kts: Google Services plugin used by Firebase Android config.
settings = android / 'settings.gradle.kts'
if settings.exists():
    s = settings.read_text()
    marker = 'id("com.google.gms.google-services") version "4.5.0" apply false'
    if marker not in s:
        needle = 'id("com.android.application")'
        idx = s.find(needle)
        if idx >= 0:
            line_end = s.find('\n', idx)
            s = s[:line_end+1] + '    ' + marker + '\n' + s[line_end+1:]
        else:
            raise SystemExit('Could not patch settings.gradle.kts')
    settings.write_text(s)

# app/build.gradle.kts: package, Firebase plugin, min SDK, Codemagic release signing.
build = app / 'build.gradle.kts'
if not build.exists():
    raise SystemExit('Expected android/app/build.gradle.kts')
s = build.read_text()
if 'id("com.google.gms.google-services")' not in s:
    s = s.replace('id("dev.flutter.flutter-gradle-plugin")', 'id("dev.flutter.flutter-gradle-plugin")\n    id("com.google.gms.google-services")')
s = s.replace('com.soikot.dream_squad_card_maker', 'com.soikot.dreamsquad')
s = re.sub(r'minSdk\s*=\s*flutter\.minSdkVersion', 'minSdk = 24', s)

# Insert release signing config once.
if 'CM_KEYSTORE_PATH' not in s:
    signing = '''\n    signingConfigs {\n        create("release") {\n            storeFile = file(System.getenv("CM_KEYSTORE_PATH"))\n            storePassword = System.getenv("CM_KEYSTORE_PASSWORD")\n            keyAlias = System.getenv("CM_KEY_ALIAS")\n            keyPassword = System.getenv("CM_KEY_PASSWORD")\n        }\n    }\n'''
    s = s.replace('\n    buildTypes {', signing + '\n    buildTypes {')

s = s.replace('signingConfig = signingConfigs.getByName("debug")', 'signingConfig = signingConfigs.getByName("release")')
build.write_text(s)

# Manifest permissions, AdMob app ID and app label.
manifest = app / 'src' / 'main' / 'AndroidManifest.xml'
ms = manifest.read_text()
ms = ms.replace('android:label="dream_squad_card_maker"', 'android:label="Dream Squad Card Maker"')
root_tag = '<manifest xmlns:android="http://schemas.android.com/apk/res/android">'
perms = '''<manifest xmlns:android="http://schemas.android.com/apk/res/android">\n    <uses-permission android:name="android.permission.INTERNET" />\n    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="28" />'''
if 'android.permission.INTERNET' not in ms:
    ms = ms.replace(root_tag, perms)
meta = '''\n        <meta-data\n            android:name="com.google.android.gms.ads.APPLICATION_ID"\n            android:value="ca-app-pub-1379059201302335~9775813971" />'''
if 'com.google.android.gms.ads.APPLICATION_ID' not in ms:
    ms = ms.replace('\n    </application>', meta + '\n    </application>')
manifest.write_text(ms)

# Put MainActivity in the package-matching folder.
kotlin_root = app / 'src' / 'main' / 'kotlin'
if kotlin_root.exists():
    for p in kotlin_root.rglob('MainActivity.kt'):
        p.unlink()
target = kotlin_root / 'com' / 'soikot' / 'dreamsquad' / 'MainActivity.kt'
target.parent.mkdir(parents=True, exist_ok=True)
target.write_text((root / 'tool' / 'MainActivity.kt').read_text())

print('Android package, Firebase, AdMob and release signing configured.')
PY

echo "Android platform ready: com.soikot.dreamsquad"
