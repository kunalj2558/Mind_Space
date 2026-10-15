# 04 — Chat, Voice/Video, Session Flow and Per-Minute Billing

## 1. Three service layers
### A. Free MindSpace AI chat
- Always identify the assistant as AI, not a therapist or psychiatrist.
- Offer supportive reflection, grounding exercises, psychoeducation and care navigation.
- No diagnosis, prescribing, guarantees or pressure to purchase.
- Show a persistent “Talk to a professional” path and crisis guidance when appropriate.
- Make history saving and deletion choices understandable.

### B. Patient ↔ professional text chat
Decide one transparent commercial model before release:
1. included with a booked session for a stated period; or
2. a fixed-price asynchronous package with response-time expectations; or
3. per-minute live text session, if the interface can measure active interaction fairly.
Avoid charging per message without showing price and expected total. Do not imply that asynchronous messages receive emergency monitoring.

### C. Voice/video consultation
- Book a professional and select voice or video.
- Display clinician identity, credentials, rate, minimum charge, rounding rule, cancellation policy and expected total before confirming.
- Complete payment/preauthorization as legally and gateway-supported.
- Join a waiting room; test microphone/camera/network; show privacy and emergency location prompts where appropriate.
- Start billable time only under the disclosed session-start rule.
- End screen shows actual duration, rate snapshot, itemized charge, taxes/fees where applicable, and refund/dispute route.

## 2. Example session state machine
`scheduled → payment_pending → paid/authorized → waiting_room → connecting → active → ending → completed → settled`

Alternate terminal states: `cancelled`, `no_show`, `failed`, `refunded`, `disputed`.

Transitions must be server-validated. The client cannot mark an order paid, set a billable duration, change a rate, or settle a session.

## 3. Per-minute charging model
The business must decide the actual rates; do not hardcode prices in the app. Store a rate snapshot when the user confirms booking so later price changes do not alter an existing booking.

Illustrative formula only:
- `billable_seconds = max(0, server_end_time - server_billable_start_time - excluded_pause_seconds)`
- `billable_minutes = ceil(billable_seconds / 60)` **only if this rounding rule is clearly disclosed and legally/gateway appropriate**
- `session_fee = billable_minutes × locked_rate_per_minute`
- final payable/refundable amount = session fee + disclosed applicable taxes/fees − credits/refunds

Prefer fairer safeguards for users:
- Display an estimated cost and a spend cap before connecting.
- Offer a minimum connection grace period for technical failures.
- Give a 30–60 second low-balance warning, then end/pause according to the published rule.
- Use server-side event timestamps, not the phone clock.
- Store connection interruptions and the reason for pauses.
- Provide itemized receipts and a dispute mechanism.
- Never let a professional silently change the rate mid-call.

## 4. Payment approaches to evaluate
**Option A — prepaid wallet/session balance:** user adds funds or prepays a session. Simple user experience but may introduce stored-value, refund and regulatory obligations. Obtain gateway/legal advice before implementing a wallet.

**Option B — per-session checkout:** user pays a disclosed deposit or maximum amount; final charge/refund is reconciled after the call. Feasibility depends on gateway features, authorization/capture support and current India rules.

**Option C — scheduled fixed-duration package:** user pays for 15/30/45/60 minutes before the call. Simplest MVP for predictable cost and avoids a continuously changing bill. Offer extension only after explicit confirmation and another valid payment step.

**Recommended launch sequence:** begin with fixed-duration prepaid sessions and sandbox payments; introduce true per-minute metering only after gateway support, refunds, reconciliation and legal review are confirmed. Do not assume that a normal payment gateway supports automatic postpaid per-minute charging.

## 5. Payment lifecycle
1. Client asks API to create order for a server-calculated amount.
2. API stores a pending order with idempotency key and price/rate snapshot.
3. Client opens gateway checkout.
4. Gateway sends signed webhook; backend verifies signature and amount/currency/order identity.
5. Backend idempotently marks order paid/authorized; client redirect alone is not proof of payment.
6. Session starts only when booking/payment rules are satisfied.
7. Server computes final amount; ledger records charges/credits.
8. Refund and payout operations are separately tracked and reconciled against gateway reports.
9. Daily reconciliation flags mismatches; support can inspect an audited record.

## 6. Realtime provider integration
Use a managed WebRTC vendor selected after a proof-of-concept. Evaluate:
- India-region performance and network quality.
- Voice-only and video support, reconnect behavior, captions/accessibility.
- SDK stability across Android/iOS and supported web targets.
- Short-lived access tokens, room locks, encryption and access controls.
- Whether recording is off by default and whether the vendor uses media for training (must be checked contractually).
- Data processing locations, subprocessors, retention, incident response and price at expected concurrency.
- Provider webhooks for join/leave events and reconciliation.
Do not promise end-to-end encryption unless the selected product and configuration genuinely provide it.

## 7. Failed-call and refund policy
Define testable rules for: clinician does not join, patient does not join, either party cancels, gateway payment succeeds but booking fails, call fails before billable start, mid-call network loss, clinician emergency, abuse report, and disputed duration. Rules should be visible before purchase and consistently applied.

## 8. Chat-to-call upgrade flow
AI chat page → “Would you like a qualified professional?” → specialty navigator → verified profiles → compare rate/language/availability → choose text/voice/video → show cost and consent → checkout → appointment/call → optional follow-up. Never use fear, a crisis disclosure, or a risk score to pressure the patient into payment.
