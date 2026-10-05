#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Creating Android platform files with Flutter..."
flutter create --platforms=android --org com.soikot --project-name dream_squad_card_maker "$TMP/bootstrap"
rm -rf "$ROOT/android"
cp -R "$TMP/bootstrap/android" "$ROOT/android"

python3 - "$ROOT" <<'PY'
from pathlib import Path
import re, sys
root = Path(sys.argv[1])
app = root / 'android' / 'app'
for name in ['build.gradle.kts', 'build.gradle']:
    p = app / name
    if not p.exists():
        continue
    s = p.read_text()
    s = s.replace('com.soikot.dream_squad_card_maker', 'com.soikot.dreamsquad')
    s = re.sub(r'namespace\s*[= ]\s*["\']com\.soikot\.dream_squad_card_maker["\']', 'namespace = "com.soikot.dreamsquad"', s)
    s = re.sub(r'applicationId\s*[= ]\s*["\']com\.soikot\.dream_squad_card_maker["\']', 'applicationId = "com.soikot.dreamsquad"', s)
    p.write_text(s)

manifest = app / 'src' / 'main' / 'AndroidManifest.xml'
ms = manifest.read_text()
ms = ms.replace('android:label="dream_squad_card_maker"', 'android:label="Dream Squad Card Maker"')
if 'WRITE_EXTERNAL_STORAGE' not in ms:
    ms = ms.replace('<manifest xmlns:android="http://schemas.android.com/apk/res/android">', '<manifest xmlns:android="http://schemas.android.com/apk/res/android">\n    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="28" />')
manifest.write_text(ms)

mains = list((app / 'src' / 'main' / 'kotlin').rglob('MainActivity.kt'))
if not mains:
    raise SystemExit('MainActivity.kt not found after flutter create')
main = mains[0]
main.write_text((root / 'tool' / 'MainActivity.kt').read_text())
print(f'Patched package and MainActivity: {main}')
PY

echo "Android platform ready with package com.soikot.dreamsquad"
