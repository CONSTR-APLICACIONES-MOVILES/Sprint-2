# Implementation backlog

This is outstanding work, not implemented capability. Ownership below identifies a feature boundary, not an assigned team member.

## Resolved integration debt

- Home → Alerts → Home navigation and the stale authentication-completion test.
- Registered Groups/Schedule destinations instead of routing to unknown locations.
- Study-session detail linked by route ID from Home and Alerts.
- Session edits, topic progress and cancellation through injected MVVM/domain/repository layers.
- Session validation, error recovery, duplicate-submit and disposal protection.
- Shared primary cobalt token and reusable bottom navigation.
- Time-change alert descriptions now use the repository data.

## Prioritized pending work

| Priority | Boundary | Remaining behavior / TODO | Completion evidence |
| --- | --- | --- | --- |
| 1 | Auth | Real identity provider, restore/revoke session, recovery and account switching | Provider integration and session lifecycle tests |
| 1 | Activities | Replace mock storage; persist edits/cancellation; authorize writes; reconcile conflicts | Repository contract, persistence/restart and failure tests |
| 1 | Home | Inject HomeViewModel before connecting availability, search, groups and plan summaries | A session edit/cancellation updates its Home summary |
| 2 | Schedule | Availability updates and comparisons; calendar integration | Domain rules, registered functional views and navigation tests |
| 2 | Activities | Create/publish plans, invitations, RSVP, reminders and other plan types | Commands with real outcomes and end-to-end tests |
| 2 | Groups/Profile | Membership, chat, participant profiles and live status | Repository-driven views; remove fixed sample profiles/statuses |
| 2 | Alerts | Backend notifications, other entity references, metadata-driven cards | Non-sample identities render correctly; deep-link fallback tests |
| 2 | External adapters | Maps/directions, resource downloads, sharing, clipboard and calendars | Isolated adapters and platform integration tests; no simulated success messages |
| 2 | Context/Recommendations | Sensor permissions, context and ranking | Explainable, tested domain results based on real inputs |
| 2 | Analytics | Event schema, pipeline and per-member BQs | Traceable event-to-result implementation |
| 3 | Maintenance | Evaluate unused flutter_svg and cupertino_icons dependencies | Dependency cleanup with lockfile review |

Home's remaining TODO comments map to these rows: calendar sync and quick status → Schedule; publish/RSVP/options → Activities; chat/availability requests → Groups; search → Home; share/copy → external adapters. They remain visible until implemented.

## Verification

Run `flutter analyze --no-pub` and `flutter test --no-pub` from the Flutter root.
Tests cover routing, MVVM boundaries, domain validation, failure recovery, session-scoped state and responsive layouts.
Mocks do not demonstrate authentication, backend integration, push delivery, sensor capabilities or offline persistence.
