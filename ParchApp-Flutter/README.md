# ParchApp Flutter Starter

Shared native Flutter foundation for the ParchApp prototype.

## Included
- Material Design 3
- Centralized ParchApp design tokens
- Inter typography through `google_fonts`
- Shared dimensions and spacing
- `go_router` foundation
- Feature-based folder structure
- Reusable primary/secondary buttons
- Welcome screen translated from Stitch
- ParchApp logo asset

## Current scope
Sign-in, account creation, session restoration and sign-out use Firebase Auth.
The app defaults to the shared `demo-parchapp` emulators; live configuration is explicit.
Auth is the reference MVVM feature.
Alerts follows the same MVVM/domain/repository boundaries with an in-memory mock repository.
Open Alerts using the notification bell in Home, or navigate to `/alerts`.
Search, category filters, read status and alert responses work for the current app session.
Activity creation saves to Firestore; maps and unimplemented destinations remain previews. No invitations are sent.
Successful sign-in and account creation open Home, whose activity cards query Firestore by group membership and use real document IDs.
The remaining Home content and other feature previews still use sample data and placeholder actions.

## Study session detail

Open a Firestore activity card in Home. The route is `/activities/study-sessions/<document-id>`.
The detail belongs to `features/activities/` and uses MVVM, domain use cases and an injected repository.
Activity Details and time recommendations use the shared Firebase callable API in `us-central1`.
Home's **New Activity** opens a form with the user's real groups. Creation and
**Modify Session** persist title, description, location, category and status
through the same repository and the existing Firestore rules. Only the organizer
can edit. Optional requested date/time text does not schedule the activity.
Organizers can search today's Bogotá availability, accept an unchanged suggestion, or modify its time.
The backend records BQ3 with the decision. Presentation is acknowledged first; details refresh errors are separate from save errors.
Legacy unscheduled activities keep null dates. Unsupported room/topic/resource/cancellation edits are unavailable in live data.
The original mock repository and editing behavior remain available for isolated tests.
Unknown IDs and load/save failures have explicit UI states.
Maps, chat, invitations, reservation services and file downloads are clearly identified as unconnected previews.
Groups and Schedule retain their existing screens and mock repositories. Calendar
authorization is wired, but event import still uses MockGoogleCalendarDataSource
and stores imported blocks only in memory.

Architecture: [contract](docs/architecture/architecture-contract.md), [state ADR](docs/architecture/adr-001-state-management.md), [remaining work](docs/architecture/implementation-backlog.md).

## Run
Start the backend emulators before running. See [Firebase activity setup and verification](docs/architecture/activity-recommendations.md) for fixture credentials, SDK smoke testing, and live-project configuration.
```bash
flutter pub get
flutter run
```

## Adding a view
1. Follow auth's `presentation/`, `domain/`, and `data/` layers under `lib/features/`.
2. Add the route to `AppRoutes`.
3. Register it in `AppRouter`.
4. Reuse `AppColors`, `AppTypography`, `AppDimensions`, and shared widgets.
5. Create and inject dependencies from `app/dependency_injection/`; Views must not construct data implementations.
6. Add ViewModel and navigation tests, then run `flutter analyze --no-pub` and `flutter test --no-pub`.

Reference viewport: **390 x 844**. The Flutter UI remains responsive.
