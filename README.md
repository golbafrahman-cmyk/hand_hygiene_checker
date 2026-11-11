# Hand Hygiene AI / ارزیابی هوشمند بهداشت دست

Bilingual Flutter application scaffold for Android and iOS.

## Current prototype
- Persian (RTL) and English (LTR) interface.
- Select alcohol-based hand rub or soap-and-water handwashing.
- Pick a demonstration video from the device.
- Clearly labels AI analysis as not yet implemented.
- Human review is planned before any score is finalized.

## Planned implementation phases
1. Video intake, consent, quality checks, and secure storage.
2. Separate validated checklists for alcohol rub and soap-and-water technique.
3. Computer-vision pipeline for hand landmarks, action segmentation, sequence, and elapsed time.
4. Reviewer dashboard to confirm/correct AI findings and issue final reports.
5. Role-based access, audit trail, retention controls, and export.
6. Android release and iOS TestFlight/App Store builds.

## Important clinical limitation
This scaffold does not analyze video and does not produce a clinical or staff-performance score. A video alone cannot reliably prove complete surface coverage or microbiological hand decontamination. The scoring rubric and thresholds must be reviewed against current WHO guidance and locally approved infection-prevention policy, then validated against trained human observers before operational use.

## Build
Install Flutter stable, then run:
```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```
For iOS, use macOS with Xcode:
```sh
flutter build ios --release
```
