# TaskMaster Android controller (early MVP)

This Flutter application can create and list tasks through the private FastAPI backend. **It does not yet execute tasks or control other Android apps.**

## Build locally

Install Flutter and Android SDK, then:

```bash
cd mobile
flutter create --platforms=android --project-name taskmaster --org dev.taskmaster .
flutter pub get
flutter test
flutter build apk --debug
```

GitHub Actions builds a debug APK artifact on changes under `mobile/`. Download the artifact from a successful workflow run.

## Connecting

1. Start the backend using `backend/README.md` with a strong token.
2. Enter a trusted HTTPS endpoint and token in the Android app.
3. On an Android emulator, `http://10.0.2.2:8000` maps to host localhost, but Android cleartext network policy may block HTTP until a development-only network security configuration is added. Never weaken production network security.
4. A physical phone requires a securely reachable endpoint, TLS, and network access; the local backend currently binds to loopback and therefore cannot yet be accessed from another device.

**Do not expose the backend directly to the internet.** Secure device pairing and worker authentication are future milestones.
