# MindSpace (HearMe) V2 — Product & Engineering Plan

This planning pack evolves the supplied Mind_Space (HearMe) architecture: Flutter client, Node.js/Express + MongoDB backend, and Python FastAPI AI chatbot. V2 adds a clinician marketplace and verified doctor/therapist profiles, appointments, paid chat, voice/video consultations, wallet/checkout, session billing, consent, safety workflows, and operational administration.

## Product principle
**MindSpace supports mental wellbeing and access to qualified professionals; it is not an emergency service and the AI is not a psychiatrist.** The AI may provide supportive conversation, wellbeing education, and navigation to care. It must not diagnose, prescribe, or replace a licensed clinician.

## Files in this pack
1. `01_PRODUCT_SCOPE_AND_USER_JOURNEYS.md` — roles, user journeys, MVP scope and differentiators.
2. `02_SYSTEM_ARCHITECTURE.md` — architecture, services, technology choices and deployment boundaries.
3. `03_AUTH_DATA_MODEL_AND_APIS.md` — authentication, role permissions, MongoDB entities and API catalogue.
4. `04_CHAT_CALLS_AND_REALTIME.md` — free/paid chat, voice/video, scheduling and per-minute billing.
5. `05_PAYMENTS_SECURITY_PRIVACY_AND_COMPLIANCE.md` — payment flow, security, privacy, clinical governance and India launch checklist.
6. `06_AI_SAFETY_ROADMAP_TESTING_AND_RELEASE.md` — AI safety, crisis handling, QA, roadmap, acceptance criteria and launch plan.

## Important assumptions / decisions to validate
- Initial market: India; initial languages: English, Hindi, Marathi. Keep localization extensible to the seven languages listed in the original plan.
- Client: Flutter mobile-first, with responsive web considered later.
- Existing services retained initially: Express API, MongoDB Atlas, FastAPI AI service, current chat/check-in/history concepts.
- Calls: use a managed WebRTC provider (for example, Agora, Daily, or Twilio) rather than building media infrastructure from scratch. Select after pricing, data-processing, regional availability, and reliability review.
- Payments: use an RBI-compliant payment gateway available to the business in India (for example, Razorpay or Cashfree), subject to onboarding and current terms. Do not store card/UPI credentials.
- Rates: clinicians set a displayed rate per minute and/or session. Product team decides actual prices, cancellation rules, taxes, platform commission, and payout cycle before launch.
- Clinical services: only verified and appropriately registered professionals may offer regulated clinical services. Verify the applicable registration and telemedicine/telepsychology rules with Indian legal and clinical advisors before accepting real patients.
- The supplied source file documents a planned architecture and endpoints; it does not prove those features are already implemented. Audit the repository before reusing code.

## Delivery approach
Build in vertical slices. Start with authentication, professional verification, discovery, appointments, and text chat. Add sandbox payments and timed calls only after the core safety and session state machine passes tests. Do not launch paid clinical consultations until clinical, legal, privacy, payment, and incident-response reviews are complete.
