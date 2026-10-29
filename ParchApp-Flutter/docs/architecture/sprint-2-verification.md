# Sprint 2 verification — 2026-10-19

Scope: Flutter and compatibility checks against the existing shared backend.
No Java source, backend contract, Firestore rules or live deployment was changed.
Existing local changes to macos/Flutter/GeneratedPluginRegistrant.swift were preserved.

## Corrected and connected

- Production Active Groups previously used MockActiveGroupsRepository while
  sending events to real Firebase Analytics. It now queries groups containing the
  authenticated UID and reads the newest activity per group for BQ5 metadata.
- Going uses a Firestore transaction with arrayUnion(current UID) and
  arrayRemove(current UID), preserving other users' responses. The returned state
  reflects the committed transaction without requiring a second network read.
  Reopening loads the persisted RSVP. Already confirmed users cannot resubmit
  from the updated card. The shared arrays represent group RSVPs, not independent
  attendance for every historical activity.
- BQ5 sets the current analytics identity through the existing SHA-256 adapter
  before recording a successful response. Failed writes emit no response event;
  failed telemetry cannot turn a committed response into a reported save failure.
  Groups without activities do not invent an invitation ID or timestamp.
- Schedule opens the current device day instead of October 15, 2026. Latest-request
  versioning prevents older results/errors overwriting newer day, duration or
  participant selections. Pending refreshes clear obsolete slots; successful
  retries clear old errors. Async results after disposal are ignored.
- Availability rejects zero/negative durations or steps, preventing an infinite
  loop for invalid steps. Busy intervals retain half-open boundary semantics.
- Schedule's radio control uses RadioGroup, clearing existing deprecation notices.

## Verification

- Original baseline: 127 Flutter tests passed.
- Final result: 140 Flutter tests passed; flutter analyze --no-pub reported no
  issues. git diff --check passed.
- Regression tests cover out-of-order successful and failed schedule requests,
  retry recovery, current-day initialization, invalid durations/steps and adjacent
  busy intervals; group mapping, session isolation, committed/failed RSVP writes,
  repeated responses, missing activities and analytics identity/failure handling.
- Backend: 23 function tests passed; 27 Firestore rules/API tests passed using
  Java 21 and the demo-parchapp Firestore emulator.
- Actual Flutter Firebase SDK smoke target passed in headless Chrome against
  Auth, Firestore and Functions emulators: authentication, group discovery,
  activity creation/editing/reopening, recommendation presentation, unchanged
  acceptance, time modification, canonical schedule preservation, BQ3 values
  (100% then 50%), real group discovery and RSVP persistence through a new repository.
- Reproduce: start Backend emulators, run node tool/seed_activity_emulator.cjs,
  then flutter run -d chrome --target tool/activity_emulator_smoke.dart
  --dart-define-from-file=build/emulator_fixture.json. Fixture credentials are
  emulator-only. Re-seed before each full smoke run.

## Remaining work before closing Sprint 2

1. Schedule and Google Calendar import still use simulated data. Authorization
   exists but imported events are mock events held in memory. Real synchronization
   needs a persistence/API contract: current shared group busy blocks describe
   today only and client rules prohibit modifying members. A date-aware schedule
   contract must preserve compatibility with Java. Do not treat empty or unknown
   future schedules as evidence that everyone is free.
2. Profile remains a mock profile (including academic information and statistics),
   although sign-out uses real Auth and the camera adapter exists. Connect identity
   and define persistence for profile/status/photo fields before claiming they
   are synchronized between devices or clients.
3. Alerts remains in-memory. There is no live invitation/notification inbox or
   delivery pipeline connected to this screen. General Home content also retains
   previews beyond the real activity list and creation flow.
4. Google Firebase sign-in is explicitly unconfigured. Email/password Auth is
   connected. Calendar authorization does not establish Firebase Google sign-in.
5. Group creation is backend-only under current rules. Group RSVP arrays are reset
   on new activity creation; the shared contract cannot represent independent
   RSVP rounds for multiple simultaneous activities. Confirm/maybe UI and BQ5
   interpretation must respect this limitation until an additive backend design
   is agreed and tested for both clients.
6. Actual analytics export, scheduled aggregation and unified dashboard need
   environment verification. Emulator tests do not validate BigQuery export,
   the scheduled BQ5 job or the deployed dashboard.
7. Physical-device validation remains pending: camera permissions/cancel flow,
   Google consent, background/resume, reopening, network failure and navigation.
   No claim is made that all Sprint 2 requirements are complete.
8. No actual examiner feedback was found in sprintsinstruct. Reconcile these
   findings with that feedback when supplied.

Sprint 3 must build on verified flows: durable pending operations, reconnection
and conflict handling, local storage, cache invalidation and measured concurrency.
An offline banner alone does not implement eventual connectivity.
