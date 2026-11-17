# Release and hosting kit: IGCSE Chemistry MCQs

## Build
- Package `com.homilabs.igcse_chemistry_mcqs` (locked after the first Play upload). Version 1.0.0 (versionCode 1).
- One command: `bash scripts/build_release.sh`. It rebuilds the bank, runs the gate (format, analyze, test,
  `release-check.sh`, `check-release-ad-ids.sh`), builds the AAB and a matching APK through `jobq`, and fails unless
  both are signed with the upload key.
- Upload to Play: `dist/igcse-chemistry-mcqs-<version>.aab`. The APK (`dist/igcse-chemistry-mcqs-<version>.apk`) is for
  test phones only. Raise `version:` in `pubspec.yaml` (e.g. `1.0.1+2`) before every new upload.
- Signing (set up 17 Nov 2026): upload keystore `.secrets/igcse-chemistry-upload.keystore`, alias `upload`, RSA 2048,
  valid 10,000 days. Passwords in `.secrets/igcse-chemistry-upload-credentials.txt`; `android/key.properties` points at
  the keystore by absolute path. Both are gitignored — keep a second copy off this machine. Upload certificate SHA-256
  `E0:10:22:05:0B:96:86:1E:14:75:05:FB:62:02:3F:B2:BF:7A:F9:2F:02:33:3C:D8:FC:10:E0:CD:C7:61:4F:CD`.
  Play App Signing holds the app signing key; this is the upload key only.
- Ads: Google Mobile Ads SDK. Release ids are in `config/admob.json`; debug builds use Google test units. The app stores
  no data of its own.

## Icon and store graphics
- `python3 tools/make_icons.py` draws the flask icon (adaptive vector, mipmaps, `store-assets/icon-512.png`) and
  `store-assets/feature-graphic.png`. No AI model is involved.
- `flutter test test_store/store_shots_test.dart` renders the 8 phone screenshots (1080×2160, no ads) into
  `store-assets/screenshots/phone/`. The test renderer cannot draw subscripts and arrows, so the shots use
  formula-free questions; phones draw them from system fonts.

## Website: https://igcse-chemistry.homilabs.org
- Subdomain created in hPanel on 17 Nov 2026 (document root `public_html/igcse-chemistry`); the same files also answer at
  https://homilabs.org/igcse-chemistry/.
- Pages: landing, `/privacy.html`, `/terms.html`, `/app-ads.txt`. Source in `website/`; publish with
  `bash scripts/publish-site.sh`.
- After approval, replace "Coming soon on Google Play" in `website/index.html` with
  https://play.google.com/store/apps/details?id=com.homilabs.igcse_chemistry_mcqs and publish again.

## AdMob (homilabs.smc@gmail.com, publisher pub-2087846699268567)
- App "IGCSE Chemistry MCQs", ID `ca-app-pub-2087846699268567~2738830970` (created 17 Nov 2026, not linked to a store
  yet). Units: banner `…/9156899667`, interstitial `…/6530736329` (see `config/admob.json`).
- After the Play listing is live: AdMob → Apps → IGCSE Chemistry MCQs → App settings → Add store. Limited ad serving
  lifts after AdMob verifies the app.
- Not done yet: a Privacy & messaging (European regulations) consent message for this app, as made for physics.

## Play Console (Homilabs organization account, developer ID 9161588402757830740)
App created 17 Nov 2026, Play app ID 4973992089820948185, default language en-US. Declarations mirror the physics app:

| Item | Value |
|---|---|
| Privacy policy URL | https://homilabs.org/igcse-chemistry/privacy.html |
| Ads | Yes |
| Sign in details | No restricted parts |
| Content rating (IARC) | All Other App Types; No to every question except "primarily news or educational". ESRB Everyone, PEGI 3, ClassInd All ages |
| Target audience | 13–15, 16–17, 18+ |
| Data safety | Collected and shared via AdMob: approximate location, app interactions, crash logs, diagnostics, device or other IDs; not ephemeral; required; purposes Analytics, Advertising or marketing, Fraud prevention; encrypted in transit; no accounts; no deletion mechanism |
| Advertising ID | Yes: Analytics; Advertising or marketing; Fraud prevention, security and compliance |
| Government / Financial / Health | No / none / none |
| Category, contact | Education; homilabs.smc@gmail.com; https://igcse-chemistry.homilabs.org |
| Store listing | Name, short and full description, icon, feature graphic, 8 phone screenshots; AI asset declaration "Don't label assets" |
| Countries | All 178 |
| Production release | "1 (1.0.0)", versionCode 1, target SDK 36, 10.5 MB download, saved 17 Nov 2026 |

**Short description** (76 of 80): `1,440 IGCSE Chemistry MCQs by topic with answers, plus 50 timed mock papers.`

## Tested (17 Nov 2026)
- Oppo CPH2743 (Android 16) over wireless adb: debug build — home, topic practice, table and formula questions,
  answer feedback, mock paper with no ad during the paper; release build launches, no crash (ads "no fill" while the
  new units warm up).
- 44 unit/widget tests, `flutter analyze` clean, `release-check.sh` PASS, release ad ids match.

## Open items
- The 11 changes were submitted for review on 17 Nov 2026 (managed publishing is off, so approval publishes the app).
  Watch Publishing overview for the quick-check result and Google's review.
- After approval: link the Play listing in AdMob and replace "Coming soon" on the website.
- Homi spot-checks a sample of questions (AI-written bank; see README).
- Trademark: "IGCSE" and "Cambridge" are used descriptively, with a not-affiliated notice on the website and in the app.
