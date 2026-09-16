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
Successful auth opens a completion placeholder; Home and real authentication remain unimplemented.

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
