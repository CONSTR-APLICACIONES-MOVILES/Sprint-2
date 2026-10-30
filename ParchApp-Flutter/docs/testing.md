# Testing and acceptance

## Flutter automated checks

From ParchApp-Flutter, after flutter pub get:

```powershell
flutter analyze --no-pub
flutter test --no-pub
flutter test --no-pub --coverage
dart run tool/coverage_summary.dart
```

Final full regression on 2026-10-30: **331 passed, one existing skipped case**. This describes a tested checkout with controlled fixtures, not complete production/provider coverage. Regenerate coverage; historical percentages are not current evidence.

Focused commands:

```powershell
flutter test --no-pub test/core/offline_mobile_api_test.dart test/core/sqlite_offline_store_test.dart test/core/restore_auth_session_test.dart
flutter test --no-pub test/features/groups/groups_offline_test.dart test/features/alerts/notification_lifecycle_test.dart test/features/activity_participants_test.dart
flutter test --no-pub test/features/activities/creation_attempt_monitor_test.dart test/features/expansions/social_views_test.dart
```

Coverage includes offline deadlines/cache, denied permissions, durable snapshots/outbox, account isolation, restored Auth, attendance changes, dismissal and creation observation recovery. Widget tests cover narrow/large-text layouts. Fakes do not contact production.

## Backend tests (separate checkout)

```powershell
npm ci
npm --prefix functions ci
npm run test:functions
npm run test:rules
```

The standard runner uses Auth/Firestore emulators under demo-parchapp and ports 9099/8080. Inspect existing personal emulator data before reset/seed commands. Never substitute a production project in a test reset URL.

With a disposable Firestore instance already configured on 8180:

```powershell
$env:FIRESTORE_EMULATOR_HOST = '127.0.0.1:8180'
node --test --test-concurrency=1 tests/activity.metrics.test.js tests/activity.metrics.rules.test.js tests/social.reminders.test.js tests/friend.notifications.test.js tests/activity.participants.test.js
```

The latest focused execution passed **30 integration/rules tests**; unit execution passed **78 tests**, including dashboard/server metric contracts. Several other legacy suites hard-code 8080: use their documented standard runner, not the 8180 environment blindly. These counts do not claim every backend suite was rerun together.

## Native emulator targets

[tool/README](../tool/README.md) describes isolated smoke targets. activity_metrics_smoke.dart exercises Firebase SDK flows; viva_storage_smoke.dart exercises actual native SQLite reopen/replay and compute with an in-memory remote.

```powershell
flutter run -d emulator-5554 -t tool/viva_storage_smoke.dart
flutter run -d emulator-5554 -t tool/activity_metrics_smoke.dart --dart-define=USE_FIREBASE_EMULATORS=true --dart-define=FIREBASE_EMULATOR_PROJECT=demo-parchapp-activity-metrics
```

The metrics target requires its dedicated backend fixtures. Read scripts/verify-activity-metrics.cjs and scripts/verify-social-reminders.cjs first: they reset a disposable demo project and require the standard 8080/9099 ports. Fixtures verify calculations, not actual user outcomes.

## Two-account acceptance

Use authorized account A (organizer) and B (participant); never publish passwords.

- [ ] Friendship request/accept; dismiss acceptance, refresh/restart and verify it remains hidden.
- [ ] Group invitation and explicit acceptance; nonmember denied private activity access.
- [ ] Publish/invite; B changes declined → maybe → accepted → declined; organizer counts agree after refresh.
- [ ] Organizer-only edit/cancel hidden from B; direct unauthorized call also denied.
- [ ] Remove/reinvite/rejoin respects membership and contains no duplicate IDs.
- [ ] Save presence, revisit Home/Profile, verify expiry/visibility from B.
- [ ] Invalid/expired/revoked codes, self-friendship, stale commands and account switching.
- [ ] Recovery, Google/Calendar, camera, location and biometric denial/cancellation on configured devices.

## Physical offline acceptance

Preload Home, Activity Details, Alerts, Profile and Groups. Disable Wi-Fi and mobile data; no working tunnel. Navigate saved views, queue a supported response, terminate/reopen, reconnect and verify one server result. Repeat without a saved copy and with A→B→A isolation. Search/new friendship/participant writes must not pretend to succeed offline.

ADB termination/reopen has returned the emulator to Home without login; group offline policies have automated coverage. **Physical-device evidence remains pending.** Four API resources are not four navigated physical screens.

## Analytics acceptance

Organization login reads shared aggregates. Check source/window/sample/environment/update time; empty/pending/unknown states remain visible. BQ14 must not invent a winner from tiny cohorts. Refresh reports failures from team/activity updaters independently. Verify any signed-in ParchApp account can read, anonymous reads fail, and ordinary accounts cannot use the organization refresher. Production answers require actual refreshed documents, not fixture percentages.

## Delivery

- [ ] Record APK commit/version/SHA-256 and cloud/emulator flags.
- [ ] Test that exact APK on physical hardware.
- [ ] Firebase App Distribution invitations and confirmed TA access.
- [ ] Course Teams message and official GitHub submission before the announced deadline.
- [ ] Six-minute ethics video and oral rehearsal.

No invitation/message/submission/video is implied by tests. Release currently uses debug signing. SonarQube needs an authorized Dart-capable server: tool/check_quality.ps1 -Scan is not certified without its report.
