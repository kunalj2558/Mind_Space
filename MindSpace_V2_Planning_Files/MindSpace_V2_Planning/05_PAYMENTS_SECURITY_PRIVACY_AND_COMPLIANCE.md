# 05 — Payments, Security, Privacy and Compliance (India-first planning)

This is an engineering/product checklist, not legal advice. Before launch, engage Indian counsel and a qualified clinical-governance lead to validate the rules applicable to each professional category, platform structure, data flow and payment model.

## 1. Payment and commercial controls
- Select a gateway only after checking current India onboarding, supported payment methods, marketplace/aggregator rules, refunds, webhooks, settlement and professional payout support.
- Keep gateway secrets server-side. Verify webhook signatures and implement idempotency.
- Do not store card numbers, UPI PINs, CVVs or payment credentials.
- Separate patient charges, platform fee, professional earnings, taxes, refunds and chargebacks in an auditable ledger.
- Publish rates, minimum duration, rounding, cancellation/no-show, technical-failure, refund and payout rules.
- Avoid implementing a stored-value wallet until its legal/regulatory implications are reviewed.
- Reconcile orders, gateway settlements, refunds and payouts daily.

## 2. Sensitive information and privacy
Mental-health conversations and records are highly sensitive. Collect the minimum necessary data for a stated purpose.
- Provide clear privacy notice, purpose-specific consent and age/eligibility rules.
- Keep AI chat, clinician messages, formal clinical notes, credential documents, payment records and audit logs separated by access policy.
- Do not share AI chat history with a clinician unless the patient explicitly chooses what to share.
- Do not record voice/video by default. If recording is introduced, require separate explicit consent from all participants, explain access/retention and allow refusal without blocking alternatives where feasible.
- Provide account export/deletion request workflows, retention schedules, legal holds and documented exceptions.
- Avoid putting symptoms, diagnosis, message bodies or session links in push notifications, analytics events, URLs or logs.
- Use private object storage, short-lived signed links and encryption in transit/at rest.
- Keep third-party AI/realtime/payment data-processing terms and subprocessors documented.

## 3. Security controls
- TLS everywhere; secure cookies or platform-protected token storage.
- Argon2id password hashing, token rotation, revocation and brute-force protection.
- MFA for professionals/admins; session management and device logout.
- RBAC plus record-level authorization on every API; test IDOR/BOLA vulnerabilities.
- Least-privilege database/service credentials and network restrictions.
- Rate limiting, schema validation, upload type/size checks, malware scanning for documents, secure headers and CSRF protection where relevant.
- Secrets manager, secret scanning, dependency/SAST checks and patching process.
- Immutable/audited events for credential verification, record access, refunds, role changes and safety escalation.
- Backups with encryption, retention limits and restore drills.
- Security incident response, breach triage, user support and regulator/counsel notification decision process.

## 4. Professional credential verification
- Verify identity, qualifications, applicable registration/licence, current standing, specialty claims and expiry dates.
- Keep documents private and reviewer access restricted.
- Publicly show only information necessary for informed choice and legally permitted disclosure.
- Re-check expired or challenged credentials; disable booking while verification is unresolved.
- Do not use a generic “doctor verified” label for every role. Clearly distinguish psychiatrist, clinical psychologist, counsellor/therapist and physiotherapist, including their scope.

## 5. India launch review
Obtain current professional advice on:
- Applicable professional registration and scope rules for psychiatrists, clinical psychologists, counsellors/therapists and physiotherapists.
- Telemedicine/telepsychology rules, consent, identity checks, documentation, prescriptions and emergency limitations for each category.
- Digital Personal Data Protection Act and rules/status, other applicable health-record/privacy obligations, cross-border processing and vendor contracts.
- Consumer protection, e-commerce disclosures, grievance officer/support, refunds, advertising claims and platform liability.
- GST/tax invoicing, TDS or other applicable tax treatment, professional payouts and marketplace structure.
- Payment gateway, marketplace settlement, stored value/wallet and automatic charge/capture constraints.
- Child/minor safeguarding; safest MVP may restrict consultations to adults until a specialist policy is approved.
- Accessibility and language obligations where applicable.

## 6. Crisis and emergency boundaries
- State clearly that the platform is not an emergency response service and availability is not guaranteed.
- If a user indicates immediate danger, self-harm intent, abuse or urgent medical risk, show a calm crisis flow with local emergency resources and encourage contacting a trusted person or emergency service. Do not put this behind a paywall.
- Avoid automatic disclosure to family, employers, clinicians or authorities except where a documented, legally reviewed policy and necessary safeguards apply.
- Train support staff; create escalation coverage and test it. Do not market “24/7 crisis monitoring” unless the platform truly staffs and audits it.

## 7. Vendor due diligence
For AI, video, SMS, analytics, cloud and payment vendors, document: data collected, purpose, storage region, subprocessors, retention/deletion, training use, encryption, incident notice, availability, pricing and contract exit plan.
