# Schedule, Profile and Alerts integration — 2026-10-19

Production dependency injection now selects real repositories for all three
features. Explicit mock factories remain for isolated tests. No Java sources were
edited. The shared backend has additive authenticated callable endpoints; its
existing Java rules and group/activity commands remain supported.

## Flows

- Schedule loads actual shared-group peers. Unknown day data raises a sync error
  rather than generating fake free slots. Google's primary-calendar FreeBusy
  endpoint requests only occupied intervals for 56 days in Bogotá. Midnight
  splitting, overlap merging and persistence happen server-side. Sync again
  refreshes existing snapshots, including removed events. No calendar event
  titles, places, descriptions or attendees are sent to the backend.
- Profile loads Auth identity and verification plus private saved academic fields,
  active/busy status and photo. Initial unset fields are empty; unavailable
  punctuality metrics show a dash. Profile updates return the acknowledged result
  without a second read that could misleadingly report save failure. Name updates
  also update group display names. Camera capture encodes a small image rather
  than persisting a device-specific path. Cancel leaves the photo unchanged.
- Alerts lists actual activities from the user's groups, excluding their own
  activities. Read state and accepted/maybe/declined responses survive a new
  repository and sign-in. Responses belong to individual activities; the old
  group-card Going arrays remain separate. Activity Details displays activity
  response when present, otherwise labels legacy group RSVP. BQ5 events are
  emitted after saved invitation responses with actual activity/group metadata.

## Verification

- 152 Flutter tests pass, including repository/HTTP privacy tests, unknown-calendar
  handling, failed writes and cross-account inbox isolation.
- flutter analyze --no-pub reports no issues.
- Shared backend: 23 function tests and 42 Firestore rules/API tests pass.
  Coverage includes unauthorized peers, forged profile statistics, private
  collection access, calendar replacement/midnight boundaries, recommendation
  snapshots, conflicting responses and retry-safe signup membership.
- Actual Flutter Firebase SDK smoke passed in headless Chrome against local Auth,
  Functions and Firestore with two users: activities/BQ3, group RSVP, profile/photo
  persistence, future dated snapshots, private-profile isolation, read-state
  persistence and invitation responses visible in Activity Details.
- Android debug APK compiled successfully. Gradle reports existing plugin Kotlin
  migration warnings; they did not fail compilation. Physical-device execution
  and a real Google consent flow were not verified.

Start the Backend emulators, then from the Flutter root run:

```powershell
node tool/seed_activity_emulator.cjs
flutter run -d chrome --target tool/activity_emulator_smoke.dart --dart-define-from-file=build/emulator_fixture.json
```

Re-seed before every full run. The fixture now contains an organizer and a second
participant, both emulator-only accounts.

## Limits and remaining Sprint 2 work

No production Functions deployment was performed. Deploy the new mobile endpoints
before running a live-project Flutter build. Real OAuth needs valid Google
Calendar API, consent/test users and matching client/package/signature settings.
The current google_sign_in authenticate path targets native mobile; a dedicated
web Google sign-in button flow remains separate from the SDK emulator smoke.

The inbox is in-app, loaded on opening/refresh: push notifications, reminder
scheduling and separate unread revisions for changed activity times are not
implemented. Acceptance does not claim automatic quorum confirmation, calendar
reservation or conflict resolution. Group creation, maps, chat, unsupported
activity edits and remaining Home sample cards are still outstanding.

Calendar import is manual; snapshots carry updatedAt but there is no background
refresh, age warning, disconnect/delete workflow or offline write queue yet.
Personal and friend calendars show busy blocks, not event titles. External
calendar-provider failures preserve the previous snapshot. Photos are capped at
130 KB and stored privately in Firestore for this prototype. Quick profile status
is separate from calendar occupancy. Completed plans currently counts confirmed,
ended plans authored by the user; attendance statistics are unavailable.

On a physical device verify front/rear camera, cancellation/permissions, Google
consent, repeat sync, app restart, cross-user activity responses and loss/recovery
of network. For local emulators on a phone, configure FIREBASE_EMULATOR_HOST to
the development machine's reachable address; the Android emulator default
10.0.2.2 is not a physical-device address.

The original sprint-2-verification.md records the earlier audit. Its simulated
Schedule/Profile/Alerts gaps are superseded by this document; its remaining
external deployment and physical-device caveats still apply.
