# 06 — AI Safety, Roadmap, Testing and Release

## 1. AI behavior contract
The MindSpace AI assistant should:
- Be transparent that it is AI and not a psychiatrist, psychologist or emergency service.
- Use supportive, non-judgmental language and ask one manageable question at a time.
- Offer general wellbeing education, grounding, breathing, sleep-hygiene suggestions and care navigation.
- Avoid diagnosis, prescription, medication changes, certainty claims and treatment guarantees.
- Encourage professional evaluation for persistent, severe or worsening symptoms.
- Detect possible crisis language as a trigger for a safer response, not as a diagnosis or definitive risk score.
- Never pressure a distressed user to buy a consultation.
- Explain uncertainty and avoid pretending that voice tone, facial expression or text can reliably diagnose a condition.

## 2. Safety flow
1. User message arrives; run safety checks before normal generation.
2. If crisis indicators are present, respond with calm supportive language, ask about immediate danger only when appropriate, and display locally validated emergency resources.
3. Encourage immediate contact with local emergency services/trusted support if there is imminent danger.
4. Offer a professional contact path, but do not require payment to see crisis guidance.
5. If the user explicitly consents to alerting a selected clinician or trusted contact, follow the defined workflow; otherwise do not silently share private conversation.
6. Record only minimal safety-event metadata needed for follow-up, with restricted access and a documented retention policy.
7. Human review/escalation must be clearly described; do not imply someone is monitoring messages in real time if they are not.

## 3. Voice and video policy
- No automatic emotion inference, face analysis or diagnosis from voice/video in MVP.
- Audio transcription is optional and requires a clear purpose, consent and retention controls.
- If a transcript is generated, show the user what will be saved/shared; allow correction where appropriate.
- AI-generated clinical summaries must be labelled as drafts, reviewed by the professional and never silently inserted into a formal record.
- Call recording is off by default.

## 4. Roadmap (suggested sequence)
### Phase 0 — repository and product audit (1 week)
- Inspect Flutter screens, Express routes/models, FastAPI endpoints, tests, environment files and deployment.
- Mark each original feature as implemented / partial / planned / broken.
- Create a threat model, data map, consent copy and clinical review questions.
- Establish Git branch, issue tracker, staging and seeded synthetic accounts.

### Phase 1 — secure core and marketplace (2–3 weeks)
- Harden auth/RBAC and role-based navigation.
- Add professional application/verification/admin review.
- Add specialty listings, clinician profile, availability and appointment booking.
- Add consent receipts, privacy controls, audit logging and basic support/report flow.

### Phase 2 — text chat and booking (1–2 weeks)
- Separate AI chat from clinician chat.
- Build appointment-linked patient-professional messages.
- Add notification reminders without sensitive content.
- Add session summaries and patient-controlled sharing.

### Phase 3 — payments (1–2 weeks)
- Integrate gateway sandbox and webhook verification.
- Implement order state machine, receipts, cancellation/refund cases and reconciliation.
- Start with fixed-duration prepaid sessions; do not launch real payments until all failure paths pass.
- Obtain commercial/legal approval for platform fee, clinician payout and tax treatment.

### Phase 4 — voice/video (2–3 weeks)
- Prototype at least one managed WebRTC vendor on target devices/networks.
- Implement waiting room, short-lived room tokens, session lifecycle, connection grace policy and server timer.
- Run network-loss, reconnect, duplicate webhook, simultaneous join and app-kill tests.
- Add per-minute billing only after metering and dispute tests pass.

### Phase 5 — controlled pilot (2–4 weeks)
- Invite a small group of verified professionals and consenting adult test users.
- Use limited hours, clear support coverage and conservative session limits.
- Review usability, safety events, failed connections, unexpected bills, refunds and privacy issues weekly.
- Expand only after clinical, legal, security and operational sign-off.

Timelines are planning estimates for a small team and depend on the current repository, vendor SDKs and review requirements.

## 5. Test plan
### Unit
- role/scope access rules, pricing math, rounding, timezone handling, state transitions, refund rules, webhook idempotency.
### Integration
- registration and verification, professional approval, booking conflicts, checkout webhook, payment success plus booking failure, call token access, message authorization.
### Safety
- self-harm/urgent danger wording, abuse disclosures, minors, hallucinated diagnosis, coercive upselling, emergency information visible without payment.
### Security
- broken object-level authorization, privilege escalation, session fixation/replay, brute force, upload abuse, secret leakage, webhook spoofing, IDOR and data export/deletion.
### Realtime
- denied camera/microphone, weak bandwidth, disconnect/reconnect, provider outage, duplicate join/leave events, session ending from either side, app killed mid-call.
### Privacy
- no transcript sharing without consent, admin cannot browse private messages by default, no sensitive notification content, retention/deletion tests.
### Accessibility/localization
- screen readers, text scaling, captions where supported, keyboard navigation on web, language switching and fallback.

## 6. Release acceptance criteria
- No unverified professional appears as bookable.
- Every private endpoint enforces resource-level access.
- Patient can see the exact price policy before confirming.
- Payment status is based on verified server-side gateway events.
- Duplicate payment webhooks do not duplicate charges or bookings.
- Client cannot alter the rate or billable duration.
- Failed-call and cancellation policies are tested and visible.
- AI does not claim to diagnose or replace clinicians; crisis guidance is never paywalled.
- No audio/video recording by default.
- Consent, export/deletion, audit, backup/restore and incident-response procedures are documented.
- Pilot sign-off obtained from clinical, legal, security and operations owners.

## 7. Team ownership suggestion
- Backend engineer: identity, RBAC, appointments, payments, ledger, audit.
- Flutter engineer: patient/professional flows, chat, booking, call UI, localization.
- AI engineer: AI chat safety, crisis tests, care navigation, privacy-minimized context.
- Product/clinical lead: clinician verification, scope definitions, policies, consent and pilot reviews.
- QA/release owner: test matrix, staging, device/network tests and launch checklist.

## 8. First ten implementation tasks
1. Audit actual code against the original Mind_Space Markdown.
2. Draw current database and API map.
3. Create V2 branch and staging environment.
4. Implement role and resource-level authorization tests.
5. Add professional application and verification status.
6. Build specialty discovery and clinician profile screens.
7. Add availability and appointment booking with conflict protection.
8. Separate AI chat from clinician text chat and consent-controlled sharing.
9. Integrate payment sandbox with signed webhook verification and refund states.
10. Prototype voice/video provider and server-authoritative session timer.
