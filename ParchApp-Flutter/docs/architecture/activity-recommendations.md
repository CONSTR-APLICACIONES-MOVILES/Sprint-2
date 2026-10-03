# Firebase Activity Details and recommendations

## What is connected

Production app composition uses Firebase Auth, Firestore activity discovery and
`FirebaseStudySessionsRepository`. It calls the existing backend in
`us-central1`; it does not write canonical schedule fields directly to Firestore.
The shared local project is **demo-parchapp**. The checked-in live configuration targets `parchapp-852e8`; deployment of
the Activity callables to that project has not been verified.

The existing flow remains:

`StudySessionView → StudySessionViewModel → ManageStudySession / GetRecommendedSlots → StudySessionsRepository → FirebaseActivityDataSource → HTTPS callables`

`StudySession` remains the Activity entity and `ManageStudySession.load` remains
the details use case. State uses ValueNotifier and route-owned ViewModels.
The repository interface retains its existing methods; recommendation fetching
adds an optional duration argument for legacy activities without a duration.
Home loads summaries through the same Firebase repository's `ActivityCatalog`
interface and the existing cards navigate using actual document IDs.

Backend sources: `C:/Users/gabri/MovsLocal/Backend/docs/activity-api.md`,
`docs/data-model.md`, and `functions/src/activityCallables.js`.

Creation and general editing use the existing client-write contract in
`docs/data-model.md` and `firestore.rules`, through the same repository:

`ActivityForm → ActivityEditorViewModel → ManageStudySession → StudySessionsRepository → FirebaseActivityDataSource → Firestore`

Home's **New Activity**, the Alerts creation action and Schedule's planning action
open this form. It loads groups by authenticated membership and creates an
auto-ID activity with `createdBy` from Auth and a server timestamp. **Modify
Session** in Details edits title, description, location, category and status.
Only the organizer can edit; the server enforces authorization. Group and owner
are immutable. Unscheduled activities may also keep optional requested date/time
text; these fields do not constitute a canonical schedule. Scheduled activity
times still change only through recommendation decisions. General edits do not
emit recommendation events or alter BQ3.

The form keeps input after a save error, prevents concurrent submissions, and
waits for server acknowledgement. Successful creation opens the saved document's
Details. Successful editing reloads Details; a failed reload reports that changes
were saved and offers a separate retry. No new design pattern is introduced:
the editor is another MVVM ViewModel; the existing Repository and Firebase data
adapter remain the integration boundaries. ActivitiesDependencies injects them.

| Frontend operation | Callable / mapping |
| --- | --- |
| Load details | `getActivity({activityId})` |
| Explicit recommendation search | `getActivityRecommendations({activityId, durationMinutes})` |
| Displayed candidate | `presentActivityRecommendations({activityId, recommendationIds: [slot.id]})` |
| Unchanged choice, including alternatives | `acceptActivityRecommendation({activityId, recommendationId: slot.id})` |
| Custom times | `modifyActivityRecommendation({activityId, recommendationId: slot.id, startTime, endTime})` |
| Batch identity | `SlotRecommendations.id = batchId` |

Individual candidate IDs are never replaced with the batch ID in decision calls.
The adapter awaits presentation acknowledgement before deciding, coalesces
in-flight acknowledgements, retries failed displayed-candidate acknowledgements,
and preserves IDs for identical retries. Backend transactions atomically record
BQ3 and schedule changes; no separate Firebase Analytics transport is used.
A decision is successful when the decision callable succeeds. A failed subsequent
details refresh shows “Time saved” with its own retry, without repeating the save.

The server ranks candidates using availability and preferences. Flutter preserves
that order and displays the server's reasons and participant counts. Searches
are explicit, including a duration input (15–720 minutes) and refresh/change-duration
actions. The backend currently supports **today in Bogotá only**. Display and
editing use Bogotá wall times and send UTC instants; device timezone does not
silently change the intended interval. The backend rejects stale/unavailable
slots. There is no fabricated expiry timestamp.

Legacy activities retain nullable canonical times and display **Not scheduled**
plus their original free-text date/time. `canOrganize` compares the authenticated
UID with `createdBy`; server membership and organizer authorization remain
authoritative. Group RSVP labels are explicitly group-level, not invented
activity attendance.

## Preserved UI and unsupported data

The existing cards, theme, navigation, participant list, and time editor remain.
The editor restricts real recommendation edits to time; mandatory room validation
does not apply to decisions. The backend has no room, topics, resources, reminders
or cancellation fields. These are empty in the mapped entity, their controls are
hidden, and unsupported writes are rejected rather than reported as persisted.
Maps, invitations, room reservations, chat and resource downloads remain previews.

The original hardcoded detail data lives only in the explicitly injected mock
repository used by existing tests. Fixed category and amenity labels were moved
into session data; the North Library Gate label now uses the actual location,
and the unsupported “everyone ready” claim was removed. Live Home cards use
Firestore IDs and server status instead of sample readiness counts/avatars.
Mock Alerts' fixed study-session links are excluded from live composition.

Email/password sign-in, account creation, restored sessions and sign-out use
Firebase through the existing auth layers. Google sign-in is not configured and
does not simulate success. Other dashboard, group, schedule, profile and alert
content still uses its existing previews; this integration does not claim to
connect those unrelated features.

## Run locally

Requirements: Flutter, Node 22 and Java 21+. The Backend checkout must have its
root and functions dependencies installed. In a backend terminal:

```powershell
cd C:\Users\gabri\MovsLocal\Backend
$env:JAVA_HOME = 'C:/Program Files/Eclipse Adoptium/jdk-21.0.6.7-hotspot'
$env:Path = "$env:JAVA_HOME/bin;$env:Path"
npm run emulators
```

Ports: Auth 9099, Firestore 8080, Functions 5001, Emulator UI 4000.
In another terminal:

```powershell
cd C:\Users\gabri\MovsLocal\Sprint-2\ParchApp-Flutter
flutter pub get
node tool/seed_activity_emulator.cjs
flutter run -d chrome
```

Sign in with `organizer@parchapp.test` / `ParchApp123!` (local fixture credentials
only), open the newly created activity, enter a duration, and find today's times.
The seed script creates actual auto-ID group/activity documents in the local
emulator and writes `build/emulator_fixture.json`. It never accesses a live
project. Existing accounts/activities are not deleted.

To verify creation and editing manually on Android:

1. Run `flutter run -d emulator-5554` and sign in with the fixture account.
2. In Home select **New Activity**, choose a real group, enter a title and create.
3. In Details select **Modify Session**, change title/location and save.
4. Return to Home and reopen the activity to verify the saved data.
5. In `http://127.0.0.1:4000/firestore`, inspect its `activities` document.
6. Search today's recommended times in Details and accept or modify a suggestion.
   Check `startTime`/`endTime` and the recommendation decision in the emulator.

An account without groups cannot create an activity. The Groups preview does not
create backend membership; use the fixture for local testing. Emulator data is
local and is not a live-project deployment or durable across emulator resets
unless the backend emulator is configured to export/import its state.

On an Android emulator use the normal Android Flutter device target; the app
uses `10.0.2.2` automatically. Web and desktop use `127.0.0.1`. A host override is
available as `--dart-define=FIREBASE_EMULATOR_HOST=...`; physical devices also
require backend emulator bind/network configuration. Android HTTP access is
enabled for debug builds. Use web/Android for callable testing; native desktop
plugin support varies by Firebase product.

## Verification

```powershell
flutter analyze --no-pub
flutter test --no-pub
node tool/seed_activity_emulator.cjs
flutter run -d chrome --target=tool/activity_emulator_smoke.dart --dart-define-from-file=build/emulator_fixture.json
```

The smoke target uses actual Flutter Firebase SDKs and a fresh fixture: sign-in,
Firestore discovery, creation with server identity/timestamp, metadata editing,
reopening through a fresh repository, null dates, unchanged acceptance, modification, detail
refresh and the backend BQ3 query. It reports PASS only after verifying 1/1 = 100%
and then 1/2 = 50%. Run while there is enough time left today in Bogotá (before
22:30 for this fixture); no fake clock is passed to the backend. Re-seed before
each smoke run. `--web-browser-flag=--headless` can run it without a visible window;
PASS/FAIL is printed in Flutter's output.

On Android the demo app can still log `FIS_AUTH_ERROR` while Firebase's native
SDK requests an optional instance token with emulator placeholder credentials.
That warning remains unresolved; verify persistence using the smoke result and
Firestore documents, not the absence of this log message.

The installed Windows Flutter web-test harness had asset/path failures before
tests loaded, so this standalone web target is used for SDK verification.
Repository and widget tests cover null mapping, candidate/batch IDs, acknowledgement
ordering/failure, supported payloads, refresh-after-commit failure, permissions,
expiry/server rejection, duplicate submissions, sign-out failure, and screen states.

## Live project configuration

The current main branch includes `lib/firebase_options.dart` and platform
configuration for **parchapp-852e8**. These files are preserved. To select them:

```powershell
flutter run -d emulator-5554 --dart-define=USE_FIREBASE_EMULATORS=false
```

Before testing live, enable Email/Password authentication and deploy the backend
callables and rules to that same project. This restoration does not deploy them
or write test data there. The Backend checkout still defaults to demo-parchapp.

By default, FirebaseDependencies initializes the configured default app, then
uses a separate named demo-parchapp app for local Auth, Firestore and Functions.
This avoids mixing the native google-services.json default app with emulator
configuration. Native Firestore requires a default app even when instanceFor is
used; emulator placeholder options satisfy Android Functions API-key syntax
validation. The placeholders are not live credentials.

The SDK smoke target also runs on Android: replace `-d chrome` with
`-d emulator-5554`. Re-seed before every run. After testing, stop the target and
run the normal app with `flutter run -d emulator-5554`.

## Restoration after the Calendar merge

The compile failure came from missing Calendar authentication injection and an
uninitialized AuthorizeGoogleCalendar field. ScheduleDependencies now supplies
both dependencies, and authorization completes before calendar import. Calendar
still imports mock events into memory; its OAuth addition does not implement
Firestore persistence or feed the backend recommendation engine automatically.

Activity Details was recovered from a local Git tree, preserved at
`refs/recovery/activity-details-before-sync`. The restoration retains Calendar,
Groups, platform Firebase configuration, and the original Activity UI. The
recovered tree predates the final Android initialization fix, so that fix was
adapted to the newly checked-in live Firebase configuration.

The recovered original tree is local. The verified restoration is also saved at
`refs/recovery/activity-details-restored`, including the Calendar compile fix.
These references protect the saved trees from Git garbage collection and can be
used with `git show` or `git restore --source=<reference> -- <file>` for selected
files. They do not publish changes or automatically back up future edits.
