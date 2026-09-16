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
Welcome, sign-in and account creation are implemented with a mock auth backend.
Auth is the reference MVVM feature.
Alerts follows the same MVVM/domain/repository boundaries with an in-memory mock repository.
Open Alerts using the notification bell in Home, or navigate to `/alerts`.
Search, category filters, read status and alert responses work for the current app session.
The activity-creation sheet, maps and unimplemented destinations remain previews; no invitations are sent.
Successful sign-in and account creation open the Home dashboard preview.
Home uses sample content and placeholder actions; real authentication remains unimplemented.

## Study session detail

Open the study-session card in Home, or choose **View session** on its alert.
The route is `/activities/study-sessions/linear-algebra`.
The detail belongs to `features/activities/` and uses MVVM, domain use cases and an injected repository.
Topic completion, title/room/date/time editing and confirmed cancellation work in memory and survive route changes.
Invalid edits keep the previous session. Cancelled sessions cannot be edited.
Unknown IDs and load/save failures have explicit UI states.
Maps, chat, invitations, reservation services and file downloads are clearly identified as unconnected previews.
Groups and Schedule now have registered placeholder screens; they are not implemented modules.

Architecture: [contract](docs/architecture/architecture-contract.md), [state ADR](docs/architecture/adr-001-state-management.md), [remaining work](docs/architecture/implementation-backlog.md).

## Run
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
