# 03 — Authentication, Data Model and API Plan

## 1. Authentication and authorization
- Use a maintained password-hashing algorithm (Argon2id preferred; bcrypt acceptable with appropriate parameters), short-lived access tokens and refresh-token rotation/revocation.
- Verify email/phone; rate-limit login, OTP and password reset. Offer MFA for professionals and admins.
- Use RBAC plus resource-level checks. A `patient` role alone must never grant access to another patient's records.
- Professional accounts are not bookable until `verificationStatus=verified` and credentials are current.
- Store minimal identity data; never store raw payment credentials. Keep secrets in a secret manager/environment, not source control.
- Add `accountStatus`: `active`, `pending_verification`, `restricted`, `suspended`, `deleted`.

## 2. Proposed MongoDB collections
| Collection | Key fields / purpose |
|---|---|
| `users` | email/phone, passwordHash, roles, accountStatus, locale, createdAt |
| `patientProfiles` | userId, displayName, age/eligibility fields, preferences, emergency guidance acknowledgement |
| `professionalProfiles` | userId, public name, specialtyIds, qualifications, registration details, languages, bio, verificationStatus, rate cards, payout status |
| `credentialReviews` | professionalId, private document refs, reviewer, outcome, expiry, audit metadata |
| `specialties` | label, scope description, booking category and eligibility rules |
| `availabilitySlots` | professionalId, startAt, endAt, timezone, status, buffer |
| `appointments` | patientId, professionalId, serviceType, mode, scheduledAt, status, cancellation policy snapshot |
| `careRelationships` | patientId, professionalId, consent scope, grantedAt, revokedAt |
| `aiChatSessions` | patientId, messages or secure message refs, model metadata, retention policy, consent flags |
| `clinicianConversations` | appointmentId or careRelationshipId, participants, messages, read state |
| `consultationSessions` | appointmentId, providerRoomId, state, connected timestamps, disconnect events, billableSeconds |
| `rateSnapshots` | appointmentId/sessionId, currency, perMinuteRate, rounding rule, taxes/fees disclosure |
| `paymentOrders` | userId, appointmentId/sessionId, gatewayOrderId, amount, currency, status, idempotencyKey |
| `ledgerEntries` | order/session, debit/credit, amount, reason, immutable creation record |
| `refunds` | orderId, amount, reason, gatewayReference, status |
| `payouts` | professionalId, gross, fees, net, period, status, gateway reference |
| `consentReceipts` | userId, purpose, policyVersion, timestamp, withdrawnAt |
| `safetyReports` | reporterId, category, priority, assignedTeam, status, restricted details |
| `auditEvents` | actorId, action, resourceType/id, timestamp, reason, metadata with sensitive fields redacted |
| `notifications` | userId, type, delivery state, minimal non-sensitive payload |

Use schema validation, timestamps, indexes and deletion/retention policies. Encrypt sensitive fields where supported and store credential files in private object storage, not public URLs.

## 3. API route catalogue (illustrative; align naming with existing routes)
### Identity
- `POST /api/v2/auth/register`
- `POST /api/v2/auth/login`
- `POST /api/v2/auth/refresh`
- `POST /api/v2/auth/logout`
- `POST /api/v2/auth/verify-contact`
- `POST /api/v2/auth/password-reset`
- `GET /api/v2/me`
- `PATCH /api/v2/me`

### Professional verification and discovery
- `POST /api/v2/professionals/applications`
- `POST /api/v2/professionals/applications/:id/documents`
- `GET /api/v2/professionals/me/application`
- `GET /api/v2/professionals` (verified public profiles only)
- `GET /api/v2/professionals/:id`
- `GET /api/v2/specialties`
- `POST /api/v2/admin/professionals/:id/verify` (admin only, audited)
- `POST /api/v2/admin/professionals/:id/reject` (admin only, audited)

### Availability and booking
- `GET /api/v2/professionals/:id/availability`
- `PUT /api/v2/professionals/me/availability`
- `POST /api/v2/appointments`
- `GET /api/v2/appointments`
- `GET /api/v2/appointments/:id`
- `POST /api/v2/appointments/:id/cancel`
- `POST /api/v2/appointments/:id/reschedule`
- `POST /api/v2/appointments/:id/confirm`

### Chat and calls
- `POST /api/v2/ai/chat/sessions`
- `POST /api/v2/ai/chat/sessions/:id/messages`
- `GET /api/v2/ai/chat/sessions/:id`
- `POST /api/v2/appointments/:id/messages`
- `GET /api/v2/appointments/:id/messages`
- `POST /api/v2/appointments/:id/call-token` (authorized participants only)
- `POST /api/v2/sessions/:id/start`
- `POST /api/v2/sessions/:id/end`
- `POST /api/v2/sessions/:id/connection-events`

### Payments
- `POST /api/v2/payments/orders`
- `POST /api/v2/payments/webhooks/:gateway`
- `GET /api/v2/payments/orders/:id`
- `POST /api/v2/payments/orders/:id/refund` (authorized policy path)
- `GET /api/v2/patient/billing`
- `GET /api/v2/professional/earnings`
- `GET /api/v2/professional/payouts`

### Safety, privacy and support
- `POST /api/v2/safety/reports`
- `GET /api/v2/professional/alerts`
- `POST /api/v2/consents`
- `GET /api/v2/privacy/export`
- `POST /api/v2/privacy/deletion-request`
- `GET /api/v2/admin/audit-events` (strictly restricted)

## 4. Authorization matrix
- Patient: own profile, own AI sessions, their appointments, their own bills, and clinician messages for sessions they participate in.
- Professional: own profile/availability, assigned appointments, only consented patient-shared information, own clinical notes, own earnings.
- Admin: account verification and platform operations; no default access to private message bodies or clinical notes.
- Safety team: narrowly scoped access to reported incidents, logged and reviewed.
- AI service: receives only the minimum context required for the current request; no broad database credentials.
- Payment webhook: signature-verified server-to-server event; idempotent processing only.

## 5. Migration from V1
1. Inspect actual schemas and routes before changing them; the supplied Markdown is a design document, not proof of deployed code.
2. Add `/api/v2` routes alongside existing routes; do not break current clients.
3. Migrate roles and profiles with a dry run, backup and rollback plan.
4. Convert doctor links to explicit consented `careRelationships`; never silently grant expanded access.
5. Keep old chat/check-in records private by default; ask for new sharing consent.
6. Test old app compatibility, then deprecate legacy endpoints only after usage metrics confirm safe removal.
