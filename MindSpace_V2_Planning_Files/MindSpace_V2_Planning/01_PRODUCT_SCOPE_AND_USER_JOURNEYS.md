# 01 — Product Scope and User Journeys

## 1. Product vision
MindSpace is a mental-wellbeing platform inspired by the convenience of expert marketplaces such as AstroTalk, but designed around qualified mental-health professionals, informed consent, privacy, clinical boundaries, and transparent pricing. Users can start with a supportive MindSpace AI chat, then choose a verified psychologist, psychiatrist, counsellor, or physiotherapist where appropriate. The platform should never imply that physiotherapy is psychiatric treatment: show each professional category and service scope clearly.

## 2. User roles
- **Patient / client:** creates account, sets preferences, uses wellbeing chat, searches professionals, books sessions, pays, joins calls, views their own history and controls sharing.
- **Psychiatrist:** verified medical professional; can provide services within credentials and applicable law, manage availability, appointments, clinical notes and follow-up.
- **Clinical psychologist / counsellor / therapist:** verification appropriate to their title and jurisdiction; offers only services within training, registration and scope.
- **Physiotherapist:** separate specialty and service catalogue for physical rehabilitation/stress-related muscle tension where clinically appropriate; not presented as a substitute for mental-health care.
- **Platform admin / verification reviewer:** reviews documents, suspends accounts, manages categories, refunds, complaints and audit trails. Admin should not read private conversations by default.
- **Support / safety operator:** handles reported safety incidents using least-privilege access and documented procedures.
- **AI MindSpace assistant:** provides supportive, non-diagnostic wellbeing guidance, explains options, and routes users to professional or emergency help when needed.

## 3. Patient journey
1. Welcome → age/region eligibility and plain-language explanation of service limits.
2. Register/login → email/phone verification, secure session and consent.
3. Choose intent: stress support, sleep, relationship concerns, mood support, psychiatric consultation, physical rehabilitation, or “not sure”.
4. Start free AI chat/check-in. Clearly label it as AI, not a clinician. Offer privacy controls and “talk to a professional”.
5. Professional discovery: specialty, language, availability, verified credentials, session type, rate, cancellation policy, and accessible options.
6. View profile → see credentials and verification date, scope, approach, languages, price, availability and user reviews moderated for privacy.
7. Book now or schedule → show total/minimum charge, estimated cost, cancellation terms, and consent before payment.
8. Pay via gateway → server verifies gateway signature/webhook before marking order paid.
9. Chat / voice / video session → waiting room, connection test, consent, timer and visible rate. Calls should not be recorded by default.
10. End session → calculate bill from server timestamps, show itemized receipt, allow clinician note/follow-up, feedback and report issue.
11. Post-session → optional self-care plan and follow-up booking. AI summaries are opt-in and clinician-reviewed if used clinically.

## 4. Professional journey
1. Register using a professional account path; account remains `pending_verification`.
2. Submit identity, qualification, applicable registration number, specialty, experience, languages, profile photo, service regions and payout details through secure upload.
3. Verification reviewer checks authenticity and current status using appropriate official registers/processes; no public listing before approval.
4. Set service types, rates, availability, cancellation rules, session durations and buffer times.
5. Receive booking request; accept/decline or configure instant booking.
6. For a session: review only information the client consented to share, enter waiting room, verify client/session, start call, document appropriate clinical notes in a restricted area.
7. End session; see billing summary, earnings after fees, payout status, disputes and cancellations.
8. Maintain credentials and re-verification; suspend bookings if registration expires or is challenged.

## 5. Admin journey
- Review professional applications and document expiry.
- Configure specialties, platform fees, minimum session price/rules, refund policy and supported regions.
- Monitor operational metrics without exposing conversation content unnecessarily.
- Handle complaints, refunds, payment disputes, user reports, security incidents and safety escalations.
- Use audited break-glass access only when justified and policy-approved.

## 6. MVP feature priorities
### P0 — foundation
- Patient/professional/admin roles; email/phone verification; password reset; device/session management.
- Professional verification workflow and visible verified badge.
- Patient profile, specialty discovery, filters, profile pages and availability.
- Appointment booking, cancellation, reminders, timezone-safe scheduling.
- AI chat with session history, deletion/export controls and safety escalation UI.
- Text chat with clinician after booking or under an explicit free/paid policy.
- Payment gateway sandbox, order ledger, refund state and receipts.
- Feature flags, audit logs, support/reporting and admin dashboard.

### P1 — paid real-time sessions
- Voice and video through managed WebRTC.
- Server-authoritative call lifecycle and billing timer.
- Waiting room, reconnection, call quality checks, connection-loss grace period.
- Clinician availability/presence and missed-call handling.
- Post-session summary, follow-up plan and ratings/reports.

### P2 — differentiators
- Marathi/Hindi/English UI and language preference matching.
- Accessibility: captions where supported, text fallback, screen-reader support.
- “Calm Start” pre-session breathing exercise and optional session goals.
- Continuity timeline: patient-controlled goals and notes shared only with selected clinician.
- “Right Care Navigator”: transparent decision support that suggests categories, not diagnoses.
- Low-bandwidth mode and audio-only fallback.
- Optional trusted contact chosen by the user, with explicit consent and safe boundaries.
- Anonymous educational group workshops only after moderation, consent and safeguarding design.

## 7. Do not build into MVP
- AI diagnosis, prescription recommendations, automatic medication changes, or claims to replace therapy.
- Automatic emotion/diagnosis inference from voice, face, or video.
- Default call recording, automatic sharing of transcripts with clinicians, or unreviewed AI clinical notes.
- Gamified rewards that pressure vulnerable users to keep engaging or spend more.
- “Unlimited” support claims, guaranteed outcomes, or urgency-based upselling.
- Per-minute billing without clear rates, a connection grace period, spending controls and a hard stop.

## 8. Product success measures
- Successful onboarding and professional verification completion.
- Appointment completion and call connection success.
- Clear pre-payment price comprehension; low unexpected-bill complaints.
- Patient-reported helpfulness and safety reports resolved on time.
- Professional response reliability and rebooking based on user choice.
- Privacy incidents, payment disputes and crisis-flow failures (target: zero severe avoidable failures).
