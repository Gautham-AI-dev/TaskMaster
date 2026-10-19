# TaskMaster — standalone Android MVP

The Flutter application runs without a PC, backend server, account, or network connection. It persists tasks using local SharedPreferences and demonstrates an explicit approval workflow for deterministic `echo:` actions.

## Build

```bash
cd mobile
flutter create --platforms=android --project-name taskmaster --org dev.taskmaster .
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

GitHub Actions is configured to build a debug APK on mobile changes. A successful build has not yet been independently confirmed.

## Current limits

- Supported demo: enter `echo: Hello TaskMaster`, tap Create task, Prepare, Review and approve.
- Unsupported goals are saved as tasks but cannot execute yet.
- This is **not** a general-purpose Android automation agent.
- SharedPreferences is appropriate only for this small prototype; production task storage should use a transactional local database, encryption for sensitive data, audit events, and migrations.
- No PC pairing, cloud services, local LLM, or Android AccessibilityService.
