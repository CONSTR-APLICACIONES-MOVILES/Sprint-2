# Identity, offline behavior and quality — 2026-10-19

## Identity

Production Home uses the authenticated name immediately, then the private
profile's name/initials. Returning from Profile refreshes them. Live shortcuts
replace static sample cards. Sign-In resolves the profile name when recognizing
or authenticating a user, falling back to Auth identity. Registration saves
displayName/profile name and returns the entered name; profile failure never
requests re-creating an account that Auth already created successfully.

## Offline scope

OfflineMobileApi decorates the real API. SharedPreferences stores a versioned,
project/UID-scoped cache and queue without passwords or Auth tokens. Up to 64
saved results cover Profile, Alerts, peers, visited calendar days, Home summaries
and opened Activity Details. Unvisited data is explicitly unavailable.

Use offline / Go online tests app behavior without toggling the device radio.
These simulation controls now require the explicit build flag
`--dart-define=SHOW_CONNECTIVITY_DEBUG_CONTROLS=true`; they are hidden in normal
builds. With no pending responses, the connection strip is also hidden. Real
pending responses retain their review/retry controls. Startup validates restored
Auth accounts and opens Sign-In for explicit confirmation; transport errors do
not discard an account, while a confirmed missing/disabled account is signed out.
Connectivity events, resume and a 30-second timer retry pending work. A network
interface is not proof of internet: transient callable failures also use saved
data. Authorization/validation errors do not silently fall back to cache.

Only invitation responses and mark-read commands are queued, up to 100. Storage
must acknowledge persistence before the UI reports Pending sync. Identical inputs
coalesce; conflicting pending responses are refused. Ordered replay checks the
original UID and uses idempotent server commands. Conflicts stay visible for
retry or confirmed discard. Alerts reloads after synchronization. Saved work
survives restart and cannot be accessed/replayed under another authenticated UID.

Profile updates, creation/editing, recommendation searches and Calendar imports
require connectivity. Group management and uncached views also require it.
SharedPreferences is prototype storage, not an encrypted transactional database.
Cached availability may be stale; it does not guarantee a reservation. queuedAt
is local metadata; server receipt time remains authoritative. BQ5's client-event
pipeline still needs dedicated offline-replay analytics delivery. Expiry, OS
background scheduling and a secure local DB remain Sprint 3 work. Persisted
bounded backoff and automatic rejection pauses are implemented in the
[Activities/Alerts Sprint 3 increment](sprint-3-activities-alerts.md).
Offline behavior does not replace physical-device or sensor criteria. Camera
was left unchanged in this iteration.

## Quality and SonarQube

Both repositories have sonar-project.properties. Flutter imports LCOV through
sonar.dart.lcov.reportPaths and separates sources/tests. The scanner waits for
the configured server gate. No token is committed.

```powershell
.\tool\check_quality.ps1
# With an authorized Dart-capable instance and official SonarScanner CLI:
$env:SONAR_HOST_URL = 'http://your-authorized-server:9000'
$env:SONAR_TOKEN = '<set privately>'
.\tool\check_quality.ps1 -Scan
```

The script runs analysis/tests/coverage and writes coverage/summary.json. -Scan
verifies that the server exposes a Dart analyzer before invoking the scanner.
The server owns quality profiles/thresholds; no passed Sonar gate is claimed.
Native Dart requires a supporting edition. Official references:
[Dart](https://docs.sonarsource.com/sonarqube-server/analyzing-source-code/languages/dart),
[LCOV](https://docs.sonarsource.com/sonarqube-server/analyzing-source-code/test-coverage/dart-test-coverage),
[editions](https://www.sonarsource.com/plans-and-pricing/sonarqube/).

Backend/compose.sonar.yml provides loopback-only evaluation Community Build for
backend JavaScript. Its Compose configuration was validated. Docker's Linux
engine is unavailable, and no authorized Dart-capable server/token was supplied.
No actual Sonar analysis ran. Flutter analyzer/coverage results are local under
build/quality-tests.log and coverage/summary.json. Coverage describes instrumented
files, not necessarily every source file or platform flow.

Verified results: 166 Flutter tests; 23 backend function tests and 43 rules/API
tests; Flutter analysis without observations; Android debug APK compiled.
LCOV covers 3726 of 5382 instrumented lines (69.23%) across 118 instrumented files.
The SDK emulator smoke also verified registration/edited recognized names and an
offline response surviving a controller restart before successful replay.

## Deployment

The Firebase CLI account does not list access to the configured live project
parchapp-852e8. The backend defaults to demo-parchapp. No production deployment
occurred and no other project was selected by guessing. Deploy getActivities
and the clientUserId guard with the other mobile functions before a live build.
