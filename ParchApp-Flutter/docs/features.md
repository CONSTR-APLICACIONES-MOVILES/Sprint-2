# Features and offline policies

Status describes implemented behavior. Provider configuration, deployment and physical acceptance are separate checks.

| Area | Functionality | Authorization and persistence |
|---|---|---|
| Authentication | Email/password registration/login, configured Google provider, recognized account, recovery, logout, optional biometrics | Valid SDK-restored session opens Home. Network failure does not force logout. New login/recovery needs provider connectivity; biometric credentials use opt-in OS secure storage |
| Home | Authenticated identity, profile summary, availability bubble, activities, shortcuts, Quick Status | Cached activity/profile reads. Manual Quick Status is local UID/project Preferences; presence is expiring server data with privacy |
| Groups | Own groups, filters/search, members/detail, creation, invitations, consented responses and owner revocation | Member-restricted. List has Firestore offline fallback; uncached detail and management require network |
| Schedule / Compare | Days, authorized peers, availability, comparison and planning context | Loaded peers/days have snapshots. Fresh comparison/import requires services and consent. Friendship alone grants no schedule access |
| Activity creation | Details/group/location/review, publication, result and retry | Group membership, server validation and durable journal. Same requestId prevents duplicate publications after lost responses |
| Activity management | Details, suggested times, exposure acknowledgement, unchanged/modified selection, metadata editing and cancellation | Only organizer edits/cancels. Selection is separate from activity CONFIRMED state |
| Attendance | Join / Maybe / Cannot attend, including changing one's mind | Per-activity expectedResponse detects stale conflicts. First-response timing is preserved. Supported responses queue offline with pending sync |
| Participants | Organizer invites/removes group members; members join; group owner invites accepted friends to the group first | Group membership and activity attendance are separate consent steps. Participant writes require network |
| Alerts | Activity invitations/reminders/updates, friendship requests/acceptances and group invitations | Real identities, consent actions, no fabricated personal message. Accepted friendship notices support Dismiss/swipe/read removal. Event read/dismiss needs network; ordinary activity mark-read can queue |
| Friends / username | Unique normalized username, prefix search, minimal public profile, request/accept/decline/cancel/remove | Works without common group; versioned server transactions. Friends snapshot available offline; search/mutations online. No private email/calendar/location exposed |
| Sharing | Group/profile/activity code, copy/share/QR when URL configured, preview, confirmation, expiry/revocation | Profile preview is minimal; friendship not automatic. Activity codes preserve membership. Share sheet is not delivery proof; native App Links not certified |
| Checklist / resources | Personal completion, organizer-maintained topics and HTTPS links | Server membership/ownership checks; writes require network. Links are not uploaded attachments |
| Calendar | ICS sharing, import status, configured availability import | Provider consent/configuration and export behavior require manual verification. Failed import is not valid empty availability |
| Profile / privacy | Profile edits, camera workflow, expiring availability/visibility, preferences/close friends | Read snapshot offline; server writes online. Camera uses bounded data URLs, not an image file cache |
| Organization analytics | Shared BQ2/3/13/14 cards and preserved team cards | Backend dashboard with ParchApp sign-in; refresh requires the organization claim. Operational outputs may improve the app without exposing raw aggregates |

## Demonstration flows

1. Owner creates group; friend accepts membership; owner publishes activity and invites participant.
2. Participant changes decline → maybe → join; organizer sees updated counts after refresh.
3. Owner removes/reinvites; group member joins without obtaining organizer edit/cancel powers.
4. Accounts without shared groups request/accept friendship and dismiss its acceptance notice, without gaining private calendar access.
5. Preload supported views, disconnect, inspect saved content, queue an activity response, restart/reconnect and verify one server result.
6. Terminate without logout and reopen Home using the persisted valid Firebase session; explicit logout still returns to authentication.

## Limitations

- In-app SENT does not prove push, email/WhatsApp delivery or execution while terminated.
- Google/Calendar, camera, location and biometrics need configured providers/hardware; a settings screen is not proof of configuration.
- No chat, room reservation service, attachment uploads or persistent image cache is claimed.
- Normal builds hide the global diagnostic strip. Offline copy is contextual, not a promise that every operation works offline.
- Shared contracts do not replace a Java↔Flutter device walkthrough.
