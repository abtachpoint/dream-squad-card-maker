#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"

trap 'rm -rf "$TMP"' EXIT

echo "=== Dream Squad Android preparation ==="

# ------------------------------------------------------------
# Required source files
# ------------------------------------------------------------

if [ ! -f "$ROOT/tool/google-services.json" ]; then
  echo "ERROR: tool/google-services.json is missing"
  exit 1
fi

if [ ! -f "$ROOT/tool/MainActivity.kt" ]; then
  echo "ERROR: tool/MainActivity.kt is missing"
  exit 1
fi

if ! grep -q '^package com\.soikot\.dreamsquad' "$ROOT/tool/MainActivity.kt"; then
  echo "ERROR: tool/MainActivity.kt has wrong package name"
  exit 1
fi

echo "Required files verified."

# ------------------------------------------------------------
# Generate fresh Android project
# ------------------------------------------------------------

echo "Generating clean Flutter Android platform..."

flutter create \
  --platforms=android \
  --org com.soikot \
  --project-name dream_squad_card_maker \
  "$TMP/bootstrap"

rm -rf "$ROOT/android"
cp -R "$TMP/bootstrap/android" "$ROOT/android"

cp \
  "$ROOT/tool/google-services.json" \
  "$ROOT/android/app/google-services.json"

# ------------------------------------------------------------
# Configure generated Android project
# ------------------------------------------------------------

python3 - "$ROOT" <<'PY'
from pathlib import Path
import re
import sys

root = Path(sys.argv[1])
android = root / "android"
app = android / "app"

# ------------------------------------------------------------
# settings.gradle.kts
# ------------------------------------------------------------

settings = android / "settings.gradle.kts"
text = settings.read_text()

google_plugin = (
    'id("com.google.gms.google-services") '
    'version "4.4.2" apply false'
)

if google_plugin not in text:
    marker = 'id("com.android.application")'
    pos = text.find(marker)

    if pos < 0:
        raise SystemExit(
            "ERROR: Android application plugin not found "
            "in settings.gradle.kts"
        )

    line_end = text.find("\n", pos)

    if line_end < 0:
        line_end = len(text)

    text = (
        text[:line_end + 1]
        + "    "
        + google_plugin
        + "\n"
        + text[line_end + 1:]
    )

settings.write_text(text)

# ------------------------------------------------------------
# app/build.gradle.kts
# ------------------------------------------------------------

build = app / "build.gradle.kts"
text = build.read_text()

if 'id("com.google.gms.google-services")' not in text:
    text = text.replace(
        'id("dev.flutter.flutter-gradle-plugin")',
        'id("dev.flutter.flutter-gradle-plugin")\n'
        '    id("com.google.gms.google-services")'
    )

# Correct namespace + application ID.
text = text.replace(
    "com.soikot.dream_squad_card_maker",
    "com.soikot.dreamsquad",
)

# Explicit Android 16 / API 36.
text = re.sub(
    r"compileSdk\s*=\s*flutter\.compileSdkVersion",
    "compileSdk = 36",
    text,
)

text = re.sub(
    r"minSdk\s*=\s*flutter\.minSdkVersion",
    "minSdk = 24",
    text,
)

text = re.sub(
    r"targetSdk\s*=\s*flutter\.targetSdkVersion",
    "targetSdk = 36",
    text,
)

# ------------------------------------------------------------
# Codemagic release signing
# ------------------------------------------------------------

if "CM_KEYSTORE_PATH" not in text:
    signing_config = r'''
    signingConfigs {
        create("release") {
            storeFile = file(System.getenv("CM_KEYSTORE_PATH"))
            storePassword = System.getenv("CM_KEYSTORE_PASSWORD")
            keyAlias = System.getenv("CM_KEY_ALIAS")
            keyPassword = System.getenv("CM_KEY_PASSWORD")
        }
    }

'''

    match = re.search(r"\n(\s*)buildTypes\s*\{", text)

    if not match:
        raise SystemExit(
            "ERROR: buildTypes block not found in build.gradle.kts"
        )

    text = (
        text[:match.start() + 1]
        + signing_config
        + text[match.start() + 1:]
    )

text = text.replace(
    'signingConfig = signingConfigs.getByName("debug")',
    'signingConfig = signingConfigs.getByName("release")',
)

release_signing = (
    'signingConfig = signingConfigs.getByName("release")'
)

if release_signing in text and "isMinifyEnabled = false" not in text:
    text = text.replace(
        release_signing,
        release_signing
        + "\n            isMinifyEnabled = false"
        + "\n            isShrinkResources = false"
    )

# ------------------------------------------------------------
# WorkManager compatibility
# ------------------------------------------------------------

work_dependency = (
    'implementation("androidx.work:work-runtime:2.11.2")'
)

if work_dependency not in text:
    if re.search(r"\ndependencies\s*\{", text):
        text = re.sub(
            r"\ndependencies\s*\{",
            "\ndependencies {\n"
            "    "
            + work_dependency,
            text,
            count=1,
        )
    else:
        text += (
            "\n\ndependencies {\n"
            "    "
            + work_dependency
            + "\n}\n"
        )

# Keep rules are harmless while shrinking is disabled,
# and protect us if it is enabled later.
if "proguardFiles(" not in text:
    marker = "isShrinkResources = false"

    if marker in text:
        text = text.replace(
            marker,
            marker
            + '\n            proguardFiles('
              'getDefaultProguardFile('
              '"proguard-android-optimize.txt"), '
              '"proguard-rules.pro")'
        )

build.write_text(text)

# ------------------------------------------------------------
# ProGuard
# ------------------------------------------------------------

proguard = app / "proguard-rules.pro"

proguard.write_text(
r'''# Dream Squad Card Maker

-keep class androidx.work.impl.WorkDatabase_Impl { *; }

-keep class * extends androidx.room.RoomDatabase {
    <init>(...);
}

-keep class * extends androidx.work.InputMerger {
    <init>(...);
}

-keepattributes *Annotation*
'''
)

# ------------------------------------------------------------
# Gradle properties
# ------------------------------------------------------------

gradle_properties = android / "gradle.properties"

gp = (
    gradle_properties.read_text()
    if gradle_properties.exists()
    else ""
)

if "android.enableR8.fullMode=false" not in gp:
    gp += "\nandroid.enableR8.fullMode=false\n"

gradle_properties.write_text(gp)

# ------------------------------------------------------------
# AndroidManifest.xml
# ------------------------------------------------------------

manifest = app / "src" / "main" / "AndroidManifest.xml"
ms = manifest.read_text()

ms = ms.replace(
    'android:label="dream_squad_card_maker"',
    'android:label="Dream Squad Card Maker"',
)

manifest_tag = (
    '<manifest xmlns:android='
    '"http://schemas.android.com/apk/res/android">'
)

if "android.permission.INTERNET" not in ms:
    ms = ms.replace(
        manifest_tag,
        manifest_tag
        + '\n    <uses-permission '
          'android:name="android.permission.INTERNET" />'
    )

# Always use the full MainActivity name.
ms = ms.replace(
    'android:name=".MainActivity"',
    'android:name="com.soikot.dreamsquad.MainActivity"',
)

admob = '''
        <meta-data
            android:name="com.google.android.gms.ads.APPLICATION_ID"
            android:value="ca-app-pub-1379059201302335~9775813971" />'''

if "com.google.android.gms.ads.APPLICATION_ID" not in ms:
    ms = ms.replace(
        "\n    </application>",
        admob + "\n    </application>",
    )

ucrop = '''
        <activity
            android:name="com.yalantis.ucrop.UCropActivity"
            android:screenOrientation="portrait"
            android:theme="@style/Theme.AppCompat.Light.NoActionBar" />'''

if "com.yalantis.ucrop.UCropActivity" not in ms:
    ms = ms.replace(
        "\n    </application>",
        ucrop + "\n    </application>",
    )

manifest.write_text(ms)

# ------------------------------------------------------------
# MainActivity
# ------------------------------------------------------------

kotlin_root = app / "src" / "main" / "kotlin"

if kotlin_root.exists():
    for old_file in kotlin_root.rglob("MainActivity.kt"):
        old_file.unlink()

source_activity = root / "tool" / "MainActivity.kt"

target_activity = (
    kotlin_root
    / "com"
    / "soikot"
    / "dreamsquad"
    / "MainActivity.kt"
)

target_activity.parent.mkdir(
    parents=True,
    exist_ok=True,
)

target_activity.write_text(
    source_activity.read_text()
)

# ------------------------------------------------------------
# Hard verification
# ------------------------------------------------------------

if not target_activity.exists():
    raise SystemExit(
        "ERROR: MainActivity.kt was not created"
    )

activity_text = target_activity.read_text()

if "package com.soikot.dreamsquad" not in activity_text:
    raise SystemExit(
        "ERROR: Generated MainActivity package is wrong"
    )

manifest_text = manifest.read_text()

if (
    'android:name="com.soikot.dreamsquad.MainActivity"'
    not in manifest_text
):
    raise SystemExit(
        "ERROR: Manifest MainActivity reference is wrong"
    )

build_text = build.read_text()

if 'namespace = "com.soikot.dreamsquad"' not in build_text:
    raise SystemExit(
        "ERROR: Android namespace is wrong"
    )

if 'applicationId = "com.soikot.dreamsquad"' not in build_text:
    raise SystemExit(
        "ERROR: Android applicationId is wrong"
    )

print("")
print("Android configuration verified:")
print("  package    = com.soikot.dreamsquad")
print("  compileSdk = 36")
print("  targetSdk  = 36")
print("  minSdk     = 24")
print("  MainActivity =", target_activity)
PY

# ------------------------------------------------------------
# Final shell verification
# ------------------------------------------------------------

echo ""
echo "=== MAIN ACTIVITY CHECK ==="

MAIN_ACTIVITY="$ROOT/android/app/src/main/kotlin/com/soikot/dreamsquad/MainActivity.kt"
MANIFEST="$ROOT/android/app/src/main/AndroidManifest.xml"

test -f "$MAIN_ACTIVITY"

grep -q \
  '^package com\.soikot\.dreamsquad' \
  "$MAIN_ACTIVITY"

grep -q \
  'android:name="com.soikot.dreamsquad.MainActivity"' \
  "$MANIFEST"

echo "MainActivity file:"
find \
  "$ROOT/android/app/src/main/kotlin" \
  -name "MainActivity.kt" \
  -print

echo ""
echo "Manifest launcher activity:"
grep \
  'com.soikot.dreamsquad.MainActivity' \
  "$MANIFEST"

echo ""
echo "Clean Android API 36 project is ready."
