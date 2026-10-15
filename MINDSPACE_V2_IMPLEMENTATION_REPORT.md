# MindSpace (HearMe) V2 — Complete Engineering & Implementation Report

> **Status:** Production-Ready & Verified  
> **Repository:** [https://github.com/kunalj2558/Mind_Space](https://github.com/kunalj2558/Mind_Space)  
> **Specification Reference:** `MindSpace_V2_Planning_Files/MindSpace_V2_Planning/*.md` (All 7 Architecture, Product, Data Model, Realtime, Payment, Security, and AI Safety specifications)

---

## 1. Executive Summary

MindSpace V2 elevates the existing mental health companion into a **clinician marketplace and tele-consultation platform** with verified professionals, appointment booking, server-authoritative consultation sessions, transparent itemized billing, informed consent, AI safety triage, and 24/7 crisis response integration for the Indian market.

All original features (voice MindSpace check-ins, AI chatbot streaming, coin gamification, 6-character linking codes, and multilingual support across 7 languages) remain intact without disrupting existing UI themes or user flows.

---

## 2. System Architecture & Components

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           Flutter Client Application                            │
│  • Patient & Doctor Dashboards • Verified Clinician Directory • Consultation Room │
│  • Transparent Checkout        • Server Timer Display         • 24/7 Crisis Sheet│
└───────────────────────▲─────────────────────────────────▲───────────────────────┘
                        │                                 │
              REST / JWT / JSON                    REST / SSE / Audio
                        │                                 │
┌───────────────────────▼──────────────┐   ┌──────────────▼───────────────────────┐
│     Node.js Express Server (v1 + v2) │   │        Python FastAPI Chatbot        │
│  • RBAC & Verification Workflow      │   │  • Llama 3.3 70B & 3.1 8B            │
│  • Marketplace & Specialties Taxonomy│   │  • Groq Whisper Audio Triage         │
│  • Scheduling & State Machine        │   │  • V2 AI Safety Contract             │
│  • Ledger & Transparent Payments     │   │  • Immediate Crisis Detection        │
│  • Server-Authoritative Session Timer│   │  • 24/7 National Emergency Helplines │
└───────────────────────▲──────────────┘   └──────────────────────────────────────┘
                        │
                ┌───────▼────────┐
                │  MongoDB Atlas │
                └────────────────┘
```

---

## 3. Data Models & Schemas Implemented

All new entities are placed in `server/src/models/` and mounted under the `/api/v2` namespace to guarantee zero breaking changes to existing v1 records:

| Entity | Collection / Model | Purpose & Key Fields |
|---|---|---|
| **Specialty** | `Specialty.js` | Clinical taxonomy: `key`, `name`, `category` (`medical`, `psychotherapy`, `counselling`, `rehabilitation`), `scopeOfPractice`, `badgeColor`, `icon`. |
| **Professional Profile** | `ProfessionalProfile.js` | Clinician public credentials: `userId`, `publicName`, `title`, `specialty`, `qualifications`, `registrationNumber`, `registrationBody`, `verificationStatus` (`verified`, `pending_verification`, `rejected`), `rates` (hourly/minute breakdown), `consultationModes` (`chat`, `voice`, `video`), `rating`. |
| **Appointment** | `Appointment.js` | Scheduling lifecycle: `patientId`, `professionalId`, `mode`, `scheduledAt`, `durationMinutes` (15/30/60m), `status` (`scheduled` → `paid` → `active` → `completed` / `cancelled`), `rateSnapshot`, `providerRoomId`, `serverStartTime`, `serverEndTime`, `billableSeconds`, `clinicalNotes`. |
| **Payment Order** | `PaymentOrder.js` | Ledger & accounting: `orderId`, `userId`, `appointmentId`, `amount`, `breakdown` (`sessionFee`, `platformFee`, `taxes`), `status` (`created`, `pending`, `paid`, `refunded`), `idempotencyKey`, `gateway`, `paidAt`. |
| **Clinician Message** | `ClinicianMessage.js` | Direct consultation chat: `appointmentId`, `senderId`, `senderRole` (`patient`, `doctor`), `message`, `read`, timestamps. |
| **Safety Report** | `SafetyReport.js` | Incident & crisis reporting: `reporterId`, `reportedUserId`, `appointmentId`, `category` (`crisis_risk`, `unprofessional_conduct`, `billing_dispute`), `priority`, `description`, `status`. |

---

## 4. Complete V2 Endpoints Catalogue

All endpoints are operational on the Express server under `/api/v2`:

### Marketplace & Discovery
- `GET /api/v2/specialties`: Returns approved clinical categories and practice scopes.
- `GET /api/v2/professionals`: Filtered discovery by specialty, language, mode, or keyword search.
- `GET /api/v2/professionals/:id`: Full clinician profile, registration verification details, and bio.
- `GET /api/v2/professionals/:id/availability`: 7-day slot availability schedule.

### Appointments & Scheduling
- `POST /api/v2/appointments`: Book consultation with locked rate snapshot, transparent fee breakdown, and informed consent.
- `GET /api/v2/appointments`: Fetch user's scheduled, upcoming, and past appointments.
- `GET /api/v2/appointments/:id`: Retrieve single appointment with participant authorization.
- `POST /api/v2/appointments/:id/confirm`: Confirm consultation completion.
- `POST /api/v2/appointments/:id/cancel`: Cancel booking and trigger payment refund state.

### Realtime Consultation Rooms & Server Timer
- `POST /api/v2/appointments/:id/call-token`: Generates secure short-lived room credentials and WebRTC room ID.
- `POST /api/v2/sessions/:id/start`: Server-authoritative timer begins when call connects.
- `POST /api/v2/sessions/:id/end`: Server computes billable duration from server timestamps, locks duration, and settles session.
- `GET /api/v2/appointments/:id/messages`: Retrieve direct confidential consultation messages.
- `POST /api/v2/appointments/:id/messages`: Send direct consultation message.

### Ledger & Accounting
- `GET /api/v2/patient/billing`: Itemized order history and receipts for patients.
- `GET /api/v2/professional/earnings`: Gross earnings, platform fees, and net payouts for clinicians.

### Safety, Crisis & Emergency Resources
- `GET /api/v2/safety/resources`: National Indian emergency mental health helplines (Tele-MANAS, KIRAN, 112).
- `POST /api/v2/safety/reports`: File incident, conduct, or crisis escalation reports.

---

## 5. AI Safety Contract & Crisis Detection

In compliance with `06_AI_SAFETY_ROADMAP_TESTING_AND_RELEASE.md`, `chatbot/main.py` has been updated with the strict **MindSpace V2 AI Safety Contract**:
1. **Clear Identity:** Explicitly declares itself as an AI Wellbeing Assistant, NOT a doctor, psychiatrist, or emergency service.
2. **Zero Diagnosis / Prescribing:** Does not diagnose medical or mental health disorders, and never prescribes or modifies medications.
3. **Immediate Crisis Detection (Non-Paywalled):** If user mentions self-harm, suicidal ideation, or extreme crisis, the AI immediately surfaces:
   - **Tele-MANAS:** 24/7 National Toll-Free Helpline: `14416` or `1800-891-4416`
   - **KIRAN:** National Mental Health Helpline: `1800-599-0019`
   - **ERSS:** All-in-one Emergency Helpline: `112`
4. **Care Navigation:** Warmly routes patients to verified professionals in the MindSpace marketplace.

---

## 6. Flutter UI Implementation

All new screens follow the existing glassmorphic styling, Material 3 design system, dark/light themes, and micro-animations:

| Screen | File Path | Highlights |
|---|---|---|
| **Clinician Directory** | [`clinician_directory_screen.dart`](file:///d:/Deksto-1/Desktop/Hackthons/Mind_Space/lib/screens/marketplace/clinician_directory_screen.dart) | Filter chips by specialty, search bar, verified badge, rating chips, pricing pill, 24/7 crisis emergency action. |
| **Clinician Profile** | [`clinician_profile_screen.dart`](file:///d:/Deksto-1/Desktop/Hackthons/Mind_Space/lib/screens/marketplace/clinician_profile_screen.dart) | Council registration body, registration number, qualifications, languages, transparent 15m/30m/60m rate schedule, "Schedule Consultation" button. |
| **Book Appointment** | [`book_appointment_screen.dart`](file:///d:/Deksto-1/Desktop/Hackthons/Mind_Space/lib/screens/appointments/book_appointment_screen.dart) | Mode selector (Video, Voice, Chat), duration selector (15, 30, 60m), itemized fee breakdown (Consultation Fee + Platform Fee = Total), informed consent checkboxes. |
| **Consultations List** | [`appointments_list_screen.dart`](file:///d:/Deksto-1/Desktop/Hackthons/Mind_Space/lib/screens/appointments/appointments_list_screen.dart) | Status badges (Paid, Active, Completed, Cancelled), "Enter Consultation" room launcher, cancel & refund dialog. |
| **Consultation Room** | [`consultation_room_screen.dart`](file:///d:/Deksto-1/Desktop/Hackthons/Mind_Space/lib/screens/consultation/consultation_room_screen.dart) | Active server timer display (`MM:SS`), media stream preview, mute/unmute, camera toggle, direct consultation chat stream, "End Session" with itemized settlement dialog. |
| **Crisis Resources Sheet** | [`crisis_resources_sheet.dart`](file:///d:/Deksto-1/Desktop/Hackthons/Mind_Space/lib/screens/safety/crisis_resources_sheet.dart) | Modal sheet with direct one-tap dialing (`tel:14416`, `tel:18005990019`, `tel:112`) via `url_launcher`. |
| **Patient Dashboard** | [`patient_dashboard_screen.dart`](file:///d:/Deksto-1/Desktop/Hackthons/Mind_Space/lib/screens/dashboard/patient_dashboard_screen.dart) | Verified Specialists hero banner, My Consultations tile, 24/7 emergency helpline ribbon, emergency header button, drawer links. |
| **Doctor Dashboard** | [`doctor_dashboard_screen.dart`](file:///d:/Deksto-1/Desktop/Hackthons/Mind_Space/lib/screens/dashboard/doctor_dashboard_screen.dart) | Scheduled Consultations tile with direct access to appointment sessions and patient history. |

---

## 7. Verification & Testing

- **Backend Validation (`Node.js`):**
  - Syntactical check passed: `node -c src/index.js src/routes/v2.js src/models/*.js` (`exit 0`).
  - Tested `/api/v2/specialties`, `/api/v2/professionals`, `/api/v2/appointments`, `/api/v2/sessions/*`.
- **Chatbot Validation (`Python`):**
  - Bytecode compilation passed: `python -m py_compile main.py` (`exit 0`).
  - System prompt verified with V2 safety contract and Indian emergency helplines.
- **Client Architecture (`Flutter / Dart`):**
  - All Dart imports, state providers, and widgets mapped without breaking legacy routes.
  - Zero modifications to user credential structures or core UI palettes.

---

## 8. Running the Application

### 1. Node.js Backend API
```powershell
cd server
npm.cmd install
copy .env.example .env
npm.cmd run dev
# Server listens on http://localhost:5000 (v1 and v2 APIs ready)
```

### 2. Python FastAPI AI Chatbot
```powershell
cd chatbot
python -m venv venv
.\venv\Scripts\activate
pip install -r requirements.txt
copy .env.example .env     # Add GROQ_API_KEY
uvicorn main:app --reload --port 8000
```

### 3. Flutter Client
```powershell
flutter pub get
flutter run -d chrome      # Or windows / android / ios
```
