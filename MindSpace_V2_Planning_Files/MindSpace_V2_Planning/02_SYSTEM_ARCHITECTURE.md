# 02 — System Architecture

## 1. Architecture principle
Extend the existing stack incrementally; do not rewrite all of MindSpace before an audited working baseline exists.

## 2. Target architecture
```text
Flutter App (patient / clinician / admin-responsive views)
  | HTTPS REST + WebSocket/SSE
  v
Node.js + Express API (auth, RBAC, appointments, chat, billing, audit)
  |-- MongoDB Atlas (application records, indexes, backups)
  |-- Object storage (private credential documents; short-lived signed URLs)
  |-- Payment gateway (checkout + signed webhooks)
  |-- Realtime provider (WebRTC voice/video, room tokens)
  |-- Notification provider (push, email, SMS; minimal sensitive content)
  |-- FastAPI AI service (supportive chat, safety routing, optional transcription)
  |-- Observability (redacted logs, metrics, traces, alerts)
```

## 3. Keep from the supplied architecture
- Flutter/Dart client, localization, theme and auth providers.
- Express backend and Mongoose/MongoDB models.
- FastAPI AI service and existing chat streaming concept.
- Existing profile, history, doctor-patient linking, notification and check-in ideas.

## 4. Rework or add
- Separate `User` identity from role-specific `PatientProfile` and `ProfessionalProfile`.
- Replace simple doctor-code linking as the primary care relationship with explicit consented `CareRelationship` records. A linking code may remain as an optional invitation mechanism, not blanket access to every chat.
- Add professional verification, specialty catalogue, availability, appointments, session rooms, payment orders, ledger entries, refunds, payouts, consent receipts, reports and audit events.
- Avoid storing every chat transcript as clinical data by default. Keep AI chats, clinician messages, formal clinical notes and billing records in separate collections with separate permissions and retention.
- Replace any client-authoritative “coin/balance” or timer calculation with server-authoritative ledgers and session timestamps.
- Keep AI provider keys and payment secrets on the server only.

## 5. Suggested service boundaries
- **Identity & access:** registration, login, MFA/OTP policy, password reset, token rotation, role/scope authorization.
- **Marketplace:** clinician profiles, verification status, specialty taxonomy, discovery and reviews.
- **Scheduling:** availability slots, appointment locks, rescheduling, cancellation, reminders.
- **Conversation:** AI chat, patient-clinician text chat, message delivery/read states and retention controls.
- **Realtime session:** room creation, short-lived participant tokens, join/leave events, quality/reconnect events.
- **Billing:** order creation, signed webhook verification, rate snapshot, session usage calculation, refunds and payout reconciliation.
- **Safety:** crisis UI, user reports, safety queue and escalation playbooks.
- **Governance:** consent records, audit events, retention jobs, access reviews and data exports/deletion workflows.

Initially these can be modules in a modular monolith plus the existing AI microservice. Split services only when scale or team ownership requires it.

## 6. Realtime session design
- Use a managed WebRTC provider; the API issues short-lived room tokens only to the patient and assigned professional for the booked session.
- Never expose provider secret keys or unrestricted room creation to the client.
- Use server-side session states: `scheduled → payment_pending → ready → connecting → active → ending → completed`, with terminal alternatives `cancelled`, `no_show`, `failed`, `disputed`.
- The client displays a timer, but server timestamps determine billable duration. Record start only when the required participants are connected and the session is accepted under the published policy.
- For disconnects, pause or continue billing only according to a clearly disclosed rule. Recommended MVP: grace window for brief technical interruption, then pause/stop and offer reconnect; validate policy with clinicians/legal advisors.
- Do not record audio/video by default. If a future feature records sessions, require separate explicit consent from all participants, a documented purpose, secure storage, retention/deletion rules and legal review.

## 7. Deployment environments
- `local`: local database or development Atlas project; mock payment and mock call provider.
- `staging`: separate database, sandbox gateway, test identities and synthetic data.
- `production`: private secrets, least-privilege IAM, TLS, WAF/rate limits as appropriate, database network restrictions, encrypted backups, monitoring, incident response and tested restore.
- CI: format/lint, unit tests, API contract tests, dependency scanning, secret scanning, build and staging deployment.
- Infrastructure-as-code is recommended before production; keep credentials out of git and logs.

## 8. Availability and scaling
- Start with managed MongoDB, managed app hosting/container service, object storage and managed realtime. Load-test expected concurrency before sizing.
- Scale the Express and FastAPI services independently; use a queue for reminders, webhooks and non-blocking AI jobs.
- Add idempotency keys to booking/payment operations and indexes for patient, clinician, appointment, status and timestamps.
- Define service-level targets only after baseline tests; do not advertise 24/7 clinician availability unless staffed.
