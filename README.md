# Hand Hygiene AI — v1.0 prototype

Bilingual Flutter app (Persian RTL / English LTR) for Android and iOS.

## Included
- Separate alcohol-handrub and soap-and-water checklists.
- Select a video from the device gallery (no server upload).
- Stopwatch and manual duration entry.
- Human reviewer identification, item-by-item findings, notes, and confirmation.
- Calculates the percentage of checklist items marked Done among items marked Done or Missed; Not observable is excluded.
- Copies a text review report to the clipboard.

## Scope and clinical limitations
This is a **human-review prototype**, not an AI video-analysis product. It does not inspect video frames, recognize hand movements, or verify microbial cleanliness or complete surface coverage. The displayed percentage is a simple checklist summary, **not an official WHO score and not a validated staff-performance score**. Do not use it for staff ranking, discipline, or clinical decisions. The checklist and timing rules require review against current WHO guidance and local infection-prevention policy before operational use.

## Privacy
This prototype does not upload videos to a server or store review records in a cloud database. The selected original video remains on the device. Obtain consent, de-identify recordings, and establish institutional access and retention rules before use.

## Build
GitHub Actions → Build Android APK → Run workflow. Download the `hand-hygiene-ai-android` artifact after a successful run.

iOS validation requires macOS and Xcode. App Store/TestFlight distribution additionally requires Apple code signing and developer setup.

Local:
```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```
