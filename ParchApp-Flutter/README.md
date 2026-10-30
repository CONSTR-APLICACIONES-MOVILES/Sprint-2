# ParchApp Flutter

ParchApp coordinates groups, activities, availability, invitations and consented friendships. Flutter consumes the shared Firebase backend also used by Android Java.

## Documentation

| Document | Contents |
|---|---|
| [Architecture](docs/architecture.md) | Diagrams, MVVM, storage, concurrency, caching and connectivity |
| [Features](docs/features.md) | Screens, permissions and offline policy |
| [Testing](docs/testing.md) | Commands, fixtures and physical acceptance |
| [Business questions](docs/business-questions.md) | BQ2/3/13/14, sources and interpretation |

These replace the historical phase reports as the current technical documentation.

## Prerequisites

Verified toolchain: **Flutter 3.47.4, Dart 3.13.3, Android SDK and JDK 21**. Use pubspec.lock. Android Gradle Plugin is 9.1.0; Java bytecode targets 17. The Dart constraint alone does not establish compatibility with older Flutter/Android toolchains.

Install Git and Android Studio/SDK, accept licenses and provide an emulator or USB-debuggable phone. iOS requires macOS/Xcode and separate provider/device validation.

```powershell
flutter doctor -v
flutter doctor --android-licenses
flutter devices
```

The separate backend checkout uses Node.js 22, npm and Java 21 for emulators.

## Install and run with cloud Firebase

From this directory:

```powershell
flutter pub get
flutter run -d <device-id> --dart-define=USE_FIREBASE_EMULATORS=false
```

**Cloud is the default.** Checked-in lib/firebase_options.dart and native Firebase configuration target **parchapp-ee6cc**, callables in **us-central1**, Firestore default database. Client configuration identifies a project; it is not an administrator credential. Auth, callable validation and Firestore rules protect access.

Use your own authorized QA account; never commit passwords. A valid restored Firebase account opens Home. Removing the app from Recents is not logout; explicit Sign out is. Revoked accounts and clearing app data are different scenarios.

### Optional integrations

- **Google Sign-In:** registered package, signing fingerprints and provider must match. Email/password success does not prove OAuth configuration.
- **Calendar:** requires consent/scopes and provider configuration. Failed import is not a successful empty-calendar import. Friendship grants no calendar permission.
- **Maps:** configure GOOGLE_MAPS_API_KEY through the environment, Gradle property or ignored android/maps.properties. Core group flows do not certify the map/location provider.
- **Share URLs:** `--dart-define=APP_LINK_BASE_URL=https://<authorized-host>` enables configured URLs; otherwise enter share codes through Discover. Native verified App Links are not certified.
- **Biometrics:** optional device capability with explicit opt-in. The adapter stores saved email/password in OS secure storage, separately from Firebase session persistence and the offline database.

## Isolated emulator mode

From the separate Backend checkout:

```powershell
npm ci
npm --prefix functions ci
npm run emulators
```

Standard ports: Auth **9099**, Firestore **8080**, Functions **5001**. From Flutter:

```powershell
flutter run -d emulator-5554 --dart-define=USE_FIREBASE_EMULATORS=true --dart-define=FIREBASE_EMULATOR_PROJECT=demo-parchapp
```

Android emulator host defaults to 10.0.2.2; desktop/web to 127.0.0.1. For a physical phone use an authorized reachable `--dart-define=FIREBASE_EMULATOR_HOST=<host>`. Emulator projects must start with demo-. Never run reset/seed scripts against production.

Optional SHOW_CONNECTIVITY_DEBUG_CONTROLS=true exposes diagnostics. Normal builds hide the global strip; contextual indicators say Offline copy. Simulated offline mode is not a physical network cut.

## Verify and build

```powershell
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --debug --dart-define=USE_FIREBASE_EMULATORS=false
```

Output: build/app/outputs/flutter-apk/app-debug.apk. Current release configuration also uses debug signing; it is not a production-signed Play Store release.

Final full regression on 2026-10-30: **331 passed, one existing skipped case**. Implemented code, local tests, deployed functions, emulator behavior and physical-device behavior are separate claims. External acceptance includes hardware, configured providers, Java↔Flutter walkthrough, TA distribution, submission and ethics video. Dashboard readers need ParchApp sign-in; refreshing aggregates additionally requires orgAnalytics.
