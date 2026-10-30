# Home availability and Quick Status

Home has two independent editors, matching the Java DashboardActivity / StatusService / QuickStatusSheet split.

- Availability bubble beside the user name: reads the authenticated profile effectiveStatus and opens the same PresenceSheet as Profile. Saving calls the existing authenticated updatePresence backend contract with ownerId, expiration and visibility. Home reloads the profile after success; expired presence displays Offline. A resume reload and 30-second repaint keep expiry visible. It does not edit calendar busy intervals.
- Quick Status pencil: edits Free until and Next activity through QuickStatusSheet. Like Java, blank fields retain saved values and the data persists locally. PreferencesQuickStatusRepository namespaces storage by Firebase project and UID. Upcoming non-cancelled activities with known start times take priority over the manual next-activity fallback. This local text is not broadcast or treated as shared calendar availability.

Layers: entities and repository contract under domain/, SharedPreferences adapter under data/repositories/, editor under presentation/widgets/. ActivitiesDependencies injects the adapter, guards account changes around reads/writes and refreshes Home. No new backend endpoint or organization analytics access is required.

Verification: test/features/home_status_test.dart covers persistence across repository recreation, account/project isolation, blank-field preservation, the bubble callback and expiry, activity priority, and failed-save retry without losing input. Existing Home tests cover identity, loading/errors and narrow layouts.

This change does not reproduce the Java motion-sensor suggestion workflow. Availability selection uses the existing Flutter presence selector.
