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
Only the **Welcome** view is implemented.

## Run
```bash
flutter pub get
flutter run
```

## Adding a view
1. Add a feature folder under `lib/features/`.
2. Add the route to `AppRoutes`.
3. Register it in `AppRouter`.
4. Reuse `AppColors`, `AppTypography`, `AppDimensions`, and shared widgets.

Reference viewport: **390 x 844**. The Flutter UI remains responsive.
