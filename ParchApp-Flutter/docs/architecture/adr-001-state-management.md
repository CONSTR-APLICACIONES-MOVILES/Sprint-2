# ADR 001: Native observable state for MVVM v1

Status: accepted before the auth/welcome migration.

The architecture guide recommends Riverpod, but the existing project has no state-management dependency. The current scope is two independent auth forms and a navigation-only welcome screen.

Use Flutter `ValueNotifier` with immutable `AuthState`, constructor injection and route-owned ViewModels. This supports observable state, testable commands and explicit disposal without a new package. It is MVVM: ViewModels never hold or command a View.

Riverpod was considered for dependency scopes and reactive composition. Defer it until shared reactive state creates a concrete need; adoption must update this contract through an ADR rather than introduce a second pattern feature by feature.

Tradeoff: listeners and lifecycle management are explicit. Tests cover disposal during requests, loading transitions and UI navigation. ViewModel state cannot contain passwords; form controllers remain in Views and credentials are passed only to commands.
