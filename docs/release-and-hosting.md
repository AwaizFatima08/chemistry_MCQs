# Release and hosting kit: IGCSE Chemistry MCQs

## Build
- Package `com.homilabs.igcse_chemistry_mcqs`. Version 1.0.0+1. Lock the package name after the first Play upload.
- Gate: `python3 tools/build_bank.py`, `dart format`, `flutter analyze`, `flutter test`,
  `scripts/check-release-ad-ids.sh`, then the AAB and APK through `jobq`. See `scripts/build_release.sh`.
- Upload to Play: `build/app/outputs/bundle/release/app-release.aab`.
- Signing: upload keystore `.secrets/igcse-chemistry-upload.keystore` (to be created), alias
  `igcse-chemistry-upload`. `android/key.properties` points at it. Gitignored.
- Ads: Google Mobile Ads SDK. Release ids must be the chemistry AdMob units (see README). The app stores no data of its own.

## Website: https://igcse-chemistry.homilabs.org
- Pages: landing, `/privacy.html`, `/terms.html`, `/app-ads.txt`. Source in `website/`.
- Publish with `bash scripts/publish-site.sh` (SSH to Hostinger, document root `public_html/igcse-chemistry`).
- Create the subdomain in hPanel before the first publish.
- `app-ads.txt` currently holds a placeholder: replace the publisher id with the AdMob publisher id.

## Before the first Play upload
- Replace "Coming soon on Google Play" in `website/index.html` with the Play link after approval.
- Homi spot-checks questions (AI-written bank; see README).
- Trademark: "IGCSE" and "Cambridge" are used descriptively, with a not-affiliated notice on the website and in the app.
