#!/usr/bin/env bash
# Builds the Play Store bundle (AAB) and a matching APK for device testing, after the commit gate.
# Refuses to finish unless both are signed with the upload key pinned below.
set -euo pipefail
cd "$(dirname "$0")/.."
UPLOAD_SHA256="05:44:E2:53:A1:E5:2E:BF:24:36:4C:85:67:64:DC:57:43:58:B3:BA:F7:0B:E7:94:CC:58:D3:9E:E7:56:82:DF"

[ -f android/key.properties ] || { echo "android/key.properties missing: copy it from .secrets/"; exit 1; }
python3 tools/build_bank.py >/dev/null
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
~/ai-inbox/_tools/release-check.sh "$PWD"
bash scripts/check-release-ad-ids.sh

jobq run --name chemistry-mcqs-release-aab -- flutter build appbundle --release
jobq run --name chemistry-mcqs-release-apk -- flutter build apk --release
(cd android && ./gradlew --stop >/dev/null 2>&1 || true)

AAB=build/app/outputs/bundle/release/app-release.aab
APK=build/app/outputs/flutter-apk/app-release.apk
aab_sha=$(keytool -printcert -jarfile "$AAB" | awk '/SHA256:/{print $2; exit}')
APKSIGNER=$(ls ~/Android/Sdk/build-tools/*/apksigner | tail -1)
apk_sha=$("$APKSIGNER" verify --print-certs "$APK" | awk -F': ' '/certificate SHA-256 digest/{print toupper($2); exit}' | sed 's/../&:/g;s/:$//')
for pair in "AAB:$aab_sha" "APK:$apk_sha"; do
  [ "${pair#*:}" = "$UPLOAD_SHA256" ] || { echo "FAIL ${pair%%:*} not signed with the upload key (${pair#*:})"; exit 1; }
done
echo "OK signed with the upload key"
ls -la "$AAB" "$APK"

# Keep the signed artefacts: later builds (e.g. STORE_SHOTS) overwrite build/.
VER=$(awk '/^version:/{print $2}' pubspec.yaml)
mkdir -p dist
cp "$AAB" "dist/igcse-chemistry-mcqs-$VER.aab"
cp "$APK" "dist/igcse-chemistry-mcqs-$VER.apk"
ls -la dist/
