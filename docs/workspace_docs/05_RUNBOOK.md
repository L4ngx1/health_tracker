# Runbook

## Setup
```bash
flutter pub get
```

## Validation
```bash
flutter analyze
flutter test
```

## Run
```bash
flutter run -d windows
flutter run -d android
flutter run -d edge
```

## Diagnostics
```bash
flutter devices
flutter doctor -v
```

## Common Issues
- Windows LNK1168: close running app process and rerun.
- Missing plugin on desktop: guard mobile-only plugin calls.
- Google Sign-In Android failure: verify SHA1/SHA256 and refresh google-services.json.

## Git Checks
```bash
git fetch origin
git status
git diff origin/main -- <file>
```
