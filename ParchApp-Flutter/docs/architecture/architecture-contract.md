# Architecture Contract v1

Status: accepted. Auth is the reference implementation for new features.

| Decision | Contract |
| --- | --- |
| Organization | Feature-first under `lib/features/<feature>/`. |
| Layers | `presentation/`, `domain/`, `data/`. Dependencies: Presentation → Domain ← Data. |
| Presentation | MVVM. Views render state, own Flutter controllers, and forward actions. ViewModels coordinate use cases and expose immutable UI state. |
| State | Flutter `ValueNotifier` with immutable state for v1; see [ADR 001](adr-001-state-management.md). Views must not assign ViewModel state. |
| Domain | Pure Dart entities, repository interfaces, validation and use cases. No Flutter, router, data or app imports. |
| Data | Data sources return transport models; repositories map them to domain entities. No presentation imports. |
| Composition | Production repositories, data sources, use cases and ViewModels are created only in `app/dependency_injection/`. Inject dependencies through constructors. This does not restrict creation of widgets, value objects or Flutter controllers. Tests may compose their own dependencies. |
| Navigation | Views react to successful ViewModel state and call the router. ViewModels receive no `BuildContext`, route names, view contracts or navigation callbacks. Simple navigation-only buttons may route directly in the View. |
| External systems | Access through repository interfaces and data sources/adapters. Views never call SDKs or construct concrete data dependencies. |
| Lifecycle | Route composition owns/disposes ViewModels; Views attach/detach listeners. Ignore async completions after disposal and prevent duplicate submissions. |
| Exceptions | Document an accepted ADR before implementing a deviation. |

## Reference flow

`SignInView → SignInViewModel → SignIn → AuthRepository ← AuthRepositoryImpl → AuthDataSource`

- `presentation/views/`: sign-in and account-creation screens.
- `presentation/widgets/`: auth-only reusable UI.
- `presentation/view_models/`: commands and explicit idle/loading/authenticated/validationError/authenticationError state.
- `domain/entities/`, `domain/repositories/`, `domain/use_cases/`: framework-independent contracts and rules.
- `data/models/`, `data/repositories/`, `data/data_sources/`: mappings and the current mock backend.

Welcome is presentation-only because it displays content and routes forward. Do not invent domain/data implementations for empty layers. Shared widgets and the existing `core/theme/` tokens remain reusable; theme relocation is outside this refactor.

App composition now injects Firebase Auth for email/password sign-in, account creation, restored sessions and sign-out. The mock remains available for tests. Password recovery and Google account switching remain informational placeholders. See [Firebase activity integration](activity-recommendations.md) for local emulator and live-project configuration.

## Current feature boundaries

- Home is an explicitly scoped presentation-only preview. Its remaining sample actions are tracked in [the implementation backlog](implementation-backlog.md); it must adopt injected state before real data/actions are connected.
- Activities owns study sessions. Its detail follows `StudySessionView → StudySessionViewModel → ManageStudySession → StudySessionsRepository ← MockStudySessionsRepository`. Domain validates title, room, time range, topic identity and cancellation constraints. UI handles navigation and dialogs.
- Study-session repositories are scoped to the app router. FirebaseStudySessionsRepository persists recommendation decisions through the shared callable API, acknowledges candidate presentation before decisions, and maps backend data into the existing entities. The mock's edits, cancellation and topic progress remain in-memory test behavior; those unsupported fields are unavailable for Firebase activities. No reservation, notification or external file operation is performed.
- Alerts uses a callable repository for real group activity invitations, per-user read state and activity responses. It references a study session by ID through the central router, without importing Activities data. Mutations update local state only after acknowledgement; account changes clear the cached inbox.
- Active Groups uses `ManageActiveGroups → ActiveGroupsRepository ← FirebaseActiveGroupsRepository → FirestoreGroupsDataSource`. Reads use authenticated membership and the latest activity; Going responses update only the authenticated user's shared group RSVP arrays. BQ5 sets the anonymized analytics identity before recording a saved response; analytics failure never fails the saved RSVP.
- Schedule uses FirebaseScheduleRepository for membership and dated free/busy snapshots; GoogleFreeBusyDataSource supplies only occupied intervals through the authorized Calendar API. Profile uses FirebaseProfileRepository for private identity/profile/photo persistence. Both depend on MobileApi through the data layer, composed only in dependency injection. Domain remains pure Dart. See [mobile integration](mobile-integration.md).
- Native ValueNotifier remains sufficient for these independent screens; no second state-management framework has been introduced.

## Contributor checklist

1. Follow auth's layer boundaries; do not introduce `model/`, `presenter/` or `view/` as parallel feature roots.
2. Put dependencies in the composition root and business validation in use cases.
3. Test success, loading, validation/backend failure and dependency injection. Test navigation in Views, including leaving during an async request.
4. Run `flutter analyze --no-pub` and `flutter test --no-pub` before merging. Architecture tests protect dependency boundaries; review still checks semantics.
