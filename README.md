# IGCSE Chemistry MCQs

Offline Android app (Flutter) for practising Cambridge IGCSE Chemistry (0620, syllabus 2026–2028)
multiple-choice questions. No login, no tracking. Ads: AdMob, not yet live (see below).

## Features
- **Topic practice**: pick one of the 12 syllabus topics, any of its subtopics, Core only or
  Core + Extended, and 10/20/40/all questions. Each answer is marked straight away with an explanation.
- **Mock papers**: 50 papers of 20 questions for *Mixed* (all topics, weighted like Papers 1/2) and
  for each topic, at Core (Paper 1 style) or Extended (Paper 2 style) level. Optional 23-minute timer
  (the real Papers 1 and 2 give 45 minutes for 40 questions), question navigator, flags, change answers,
  then a marked result with a score by subtopic and a full review.
- Papers are deterministic: "Mixed paper 7 (Extended)" is always the same 20 questions.

## Question bank
- Source: `content/raw/<part>/batch_NN.json` (parts `c1` … `c12`, one per syllabus topic), format in
  [content/QUESTION_FORMAT.md](content/QUESTION_FORMAT.md).
- Build and validate: `python3 tools/build_bank.py` → `assets/data/bank.json` (bundled in the app).
  It checks schema, 4 distinct options, ids, duplicates and prints counts per subtopic and the answer letter balance.
- Topics and subtopic codes come from the official 2026–2028 syllabus, in `TOPICS` in `tools/build_bank.py`.
- All questions are original, written to the syllabus learning points; they are not past-paper questions.
- Status: 1,440 questions (120 per topic). Each was written by an AI agent and checked for format and
  arithmetic; **Homi must spot-check the bank before release**.

## Develop
```bash
python3 tools/build_bank.py
flutter test
jobq run --name chemistry-mcqs-release -- flutter build apk --release
```
Release signing reads `android/key.properties` (gitignored). Without it the release APK is signed
with the debug key, which is fine for testing but not for the Play Store.

## Website: https://igcse-chemistry.homilabs.org (not yet created)
- Pages: landing, `/privacy.html`, `/terms.html`, `/app-ads.txt`. Source in `website/`.
- Hostinger subdomain of homilabs.org, document root `public_html/igcse-chemistry`. Create it in hPanel first.
- Publish: `bash scripts/publish-site.sh`.

## Before release (open items)
- AdMob: create the app "IGCSE Chemistry MCQs" and its units in homilabs.smc@gmail.com; paste ids into
  `config/admob.json`, `android/app/src/main/AndroidManifest.xml` and `lib/ads/ad_ids.dart`.
  `scripts/check-release-ad-ids.sh` refuses to release while Google's sample ids are in use.
- Upload keystore for this app, kept in `.secrets/` (not created yet).
- Store listing, icon and screenshots (not made yet).
