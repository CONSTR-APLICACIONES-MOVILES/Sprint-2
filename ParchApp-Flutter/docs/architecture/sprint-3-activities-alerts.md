# Sprint 3 — Activities and Alerts

Current implementation and acceptance evidence (26 October 2026):
[local sprint 3 closure](../CIERRE_SPRINT_3.md).

The durable per-account invitation queue, selective retry/discard, backoff and serialized writes are retained. Details and Alerts now expose cache age. Large cache JSON operations use a native compute isolate while the serial queue remains the only storage writer. Web does not claim background threading.

BQ9 now has validated comparison receipts (including comparisons without slots), transactional creation attribution, first-confirmation history, mature cohorts and a callable-backed aggregate view under Profile. Instrumented direct creations and unknown older clients remain distinct. See the closure document for test-data isolation and privacy details.

Pending external acceptance: physical-device loss/recovery/conflict verification, configured live Firebase deployment, App Distribution, and connection to the team's published analytics dashboard. The local implementation does not claim these outcomes.
