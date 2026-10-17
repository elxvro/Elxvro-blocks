# Online weekly duel – implementation requirements

This feature is NOT enabled in v0.29.0 until a real backend and identity provider are configured.

## Account and matchmaking
- Authenticate with a verified identity provider (Google Play Games sign-in or an independently verified account); never trust a client-supplied player ID.
- Server issues short-lived session tokens and stores a unique, non-public player ID.
- Registration requires explicit consent to terms/privacy; publish a deletion mechanism.
- Matchmaking only during the weekly event window. Match records are server-owned, use UTC timestamps, and assign two eligible participants.
- Server chooses a common random seed and ruleset for both players.
- The duel result is decided from server-validated moves or replay verification, not arbitrary client score submission.
- Disconnects, forfeits, ties, and reconnection deadlines must be defined before release.

## Weekly event
- Choose one fixed weekday and time zone; store event start/end in UTC.
- A server-side cron job or scheduled function opens and closes the event exactly once using idempotency keys.
- Only registered players may enter. Protect against duplicate registrations and replayed result submissions.
- Ranking/rewards are awarded once after the event closes. Keep an auditable ledger.

## Data protection and anti-abuse
- TLS, rate limits, secure password hashing if passwords are used, no hardcoded credentials, server-side authorization on every endpoint.
- Delete-account endpoint, retention policy, and updated privacy notice.
- Never display simulated opponents or label local weekly progression as online competition.
- Roll out in closed testing first; maintain compatibility with existing saves and offline play.

## Pending configuration
Choose Firebase (Auth, Firestore, scheduled Cloud Functions) or existing PHP/MySQL hosting (API, MySQL, cron, WebSocket or polling). Credentials, domain and deployment access are required for a live online duel.
