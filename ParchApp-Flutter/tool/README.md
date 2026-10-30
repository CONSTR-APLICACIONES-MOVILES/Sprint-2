# Local verification targets

The production entry point is `lib/main.dart`. These targets run only against isolated Firebase emulators.

- `local_ui_preview.dart`: opens the real app routes using the local owner fixture.
- `activity_metrics_smoke.dart`: verifies native publication, recommendation, analytics and friendship contracts. The owner fixture requires the emulator-only `orgAnalytics` claim for aggregate assertions; the backend verification fixture scripts provision it locally. This does not grant regular application users dashboard access.
- `viva_storage_smoke.dart`: verifies native persistence and storage behavior.

Both UI and metrics targets require `USE_FIREBASE_EMULATORS=true` and `FIREBASE_EMULATOR_PROJECT=demo-parchapp-activity-metrics`. Start the backend emulators and run its dedicated activity/social fixture scripts first. Never point these targets at production. Android emulator host defaults to `10.0.2.2`; ports are Auth 9099, Firestore 8080 and Functions 5001.

```powershell
flutter run -d emulator-5554 -t tool/local_ui_preview.dart --dart-define=USE_FIREBASE_EMULATORS=true --dart-define=FIREBASE_EMULATOR_PROJECT=demo-parchapp-activity-metrics
```

Private planning/defense notes and generated evidence remain ignored by Git.
