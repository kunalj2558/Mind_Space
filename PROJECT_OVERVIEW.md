# Mind_Space (HearMe) - Complete Architecture & Technical Documentation

> **Mind_Space** is a mental health and AI medical triage ecosystem connecting patients and doctors with real-time symptom analysis, voice check-ins, clinical triage alerts, gamified wellness rewards, and multi-language support.

---

## 1. High-Level Architecture

The project consists of three interconnected systems:

```
┌────────────────────────────────────────────────────────────────────────┐
│                        Flutter Client App                              │
│              (Mobile / Web / Desktop - Dart 3 & Flutter)               │
└───────────────────▲────────────────────────────────▲───────────────────┘
                    │                                │
          REST / JWT / JSON                   REST / SSE Streams / Audio
                    │                                │
┌───────────────────▼──────────────┐   ┌─────────────▼───────────────────┐
│     Node.js Express Server       │   │     Python FastAPI Chatbot      │
│   (Auth, Business Logic, DB)     │   │   (Groq Whisper & Llama 3.3)    │
└───────────────────▲──────────────┘   └─────────────▲───────────────────┘
                    │                                │
                    │ Saves alerts & triage data     │
                    └────────────────────────────────┘
                    │
            ┌───────▼────────┐
            │  MongoDB Atlas │
            └────────────────┘
```

1. **Flutter App (`lib/`)**: Cross-platform frontend featuring patient/doctor interfaces, voice recording, live streaming chat, dark/light themes, and 7 supported regional languages.
2. **Node.js Express Backend (`server/`)**: Core REST API managing authentication (JWT), MongoDB data persistence, doctor-patient linking, rewards, user streaks, and history.
3. **Python FastAPI Chatbot (`chatbot/`)**: Microservice powered by Groq (Whisper Large v3 for audio transcription, Llama 3.3 70B & Llama 3.1 8B for medical advice and clinical risk triage).

---

## 2. Directory Structure

```
Mind_Space/
├── lib/                               # Flutter Cross-Platform Client Application
│   ├── main.dart                      # App entry point, MultiProvider & Theme/Locale configs
│   ├── core/                          # Core architectural utilities
│   │   ├── constants/
│   │   │   └── api_constants.dart     # Central API route definitions
│   │   ├── locale/
│   │   │   ├── app_strings.dart       # Multilingual translation dictionaries (7 languages)
│   │   │   └── locale_provider.dart   # App locale state manager
│   │   ├── providers/
│   │   │   ├── auth_provider.dart     # Authentication state, JWT tokens, persistent session
│   │   │   └── coins_provider.dart    # Coins, streaks, daily tasks & gamification state
│   │   ├── theme/
│   │   │   ├── app_theme.dart         # Material 3 colors, gradients, card styling
│   │   │   └── theme_provider.dart    # Light/Dark mode state
│   │   └── widgets/
│   │       ├── animated_button.dart   # Micro-animated interactive buttons
│   │       ├── auth_text_field.dart   # Styled form inputs
│   │       ├── glass_card.dart        # Glassmorphic UI container
│   │       └── theme_toggle_button.dart
│   ├── models/
│   │   └── user_model.dart            # User data model
│   ├── screens/
│   │   ├── auth/                      # Login, Registration, and Role Selection screens
│   │   ├── chat/                      # AI Medical Chat (Live SSE Streaming & History)
│   │   ├── dashboard/                 # Patient and Doctor Dashboard views
│   │   ├── doctor/                    # Doctor Patient Management & Detail views
│   │   ├── history/                   # Chat History and MindSpace Check-in Logs
│   │   ├── linking/                   # Unique 6-character Code Sharing & Doctor Linking
│   │   ├── mental_health/             # Voice Check-in with Audio Recording & Urgency Analysis
│   │   ├── notifications/             # Doctor Triage Alerts & Notifications
│   │   ├── profile/                   # User Profile & Medical Details Editor
│   │   ├── rewards/                   # Coin Balance, Rewards Redemption & Content Viewer
│   │   ├── splash/                    # Splash screen with auto-login check
│   │   └── welcome/                   # Onboarding & Welcome carousel
│   └── services/
│       ├── api_service.dart           # HTTP Client wrapper with Bearer token injector
│       ├── auth_service.dart          # Auth request handlers
│       ├── chat_service.dart          # Chatbot SSE stream parser and text sender
│       └── mental_health_service.dart # Audio check-in uploader and rewards client
│
├── server/                            # Node.js Express REST API & Database Service
│   ├── package.json                   # Dependencies (Express, Mongoose, JWT, Bcrypt)
│   ├── .env.example                   # Environment configuration template
│   └── src/
│       ├── index.js                   # Server entrypoint and route mounters
│       ├── config/
│       │   └── db.js                  # MongoDB Mongoose connection handler
│       ├── middleware/
│       │   ├── auth.js                # JWT Bearer token validator middleware
│       │   └── roleCheck.js           # Role-based access control ('doctor' | 'patient')
│       ├── models/
│       │   ├── User.js                # Core user account schema (uniqueCode, credentials)
│       │   ├── Patient.js             # Patient health profile (bloodGroup, records, linkedDoctor)
│       │   ├── Doctor.js              # Doctor credentials (specialization, hospital, patients list)
│       │   ├── MentalHealthNotification.js # Doctor triage alerts (urgency: low/moderate/high)
│       │   ├── MindSpaceRecord.js     # Patient voice check-in transcripts & responses
│       │   ├── ChatSession.js         # Saved AI chat dialogues
│       │   ├── UserStats.js           # Gamification stats (coins, streak, sessions)
│       │   └── RedeemedReward.js      # Redeemed wellness content library
│       ├── routes/
│       │   ├── auth.js                # Register & Login endpoints
│       │   ├── users.js               # User profile retrieval and updating
│       │   ├── doctors.js             # Doctor's patient list and individual patient views
│       │   ├── patients.js            # Doctor code linking and medical summaries
│       │   ├── rewards.js             # Coin balance sync and rewards storage
│       │   ├── history.js             # Chat and voice check-in history endpoints
│       │   └── mental-health.js       # Doctor notification dispatch and inbox
│       └── utils/
│           └── generateCode.js        # Generates unique 6-character alphanumeric user code
│
├── chatbot/                           # Python FastAPI AI Microservice
│   ├── main.py                        # FastAPI endpoints, LangChain pipelines & Groq clients
│   ├── requirements.txt               # Dependencies (FastAPI, Groq, LangChain, Uvicorn, httpx)
│   └── .env.example                   # Environment configuration template (GROQ_API_KEY)
│
├── assets/                            # Images, icons, and illustrations
├── render.yaml                        # Deployment blueprint for Render Cloud
├── pubspec.yaml                       # Flutter package manifest and dependencies
└── .gitignore                         # Git tracking rules
```

---

## 3. Complete Endpoints Catalog

### A. Node.js Express Backend (`http://<host>:5000/api`)

| Method | Endpoint | Auth | Role | Description |
|---|---|---|---|---|
| `GET` | `/health` | No | Any | Server health check (`{"status": "ok"}`) |
| **Authentication** | | | | |
| `POST` | `/api/auth/register` | No | Any | Register as `patient` or `doctor`. Generates unique 6-char code and returns 30-day JWT. |
| `POST` | `/api/auth/login` | No | Any | Authenticate with email/password and obtain JWT. |
| **User Profile** | | | | |
| `GET` | `/api/users/profile` | Bearer | Any | Fetch profile with attached role-specific details. |
| `PUT` | `/api/users/profile` | Bearer | Any | Update profile details (blood group, specialization, phone, etc.). |
| **Doctor Specific** | | | | |
| `GET` | `/api/doctors/patients` | Bearer | Doctor | Get all patients linked to the logged-in doctor. |
| `GET` | `/api/doctors/patients/:patientId/mindspace` | Bearer | Doctor | View a patient's historical voice check-ins. |
| `GET` | `/api/doctors/patients/:patientId/chats` | Bearer | Doctor | View a patient's chat history for clinical review. |
| **Patient Specific** | | | | |
| `POST` | `/api/patients/link` | Bearer | Patient | Link to a doctor using the doctor's 6-character unique code. |
| `GET` | `/api/patients/doctor` | Bearer | Patient | Retrieve currently linked doctor info. |
| `GET` | `/api/patients/records` | Bearer | Patient | Retrieve patient medical records. |
| `GET` | `/api/patients/medical-summary` | Bearer | Patient | Summarized medical context used by the AI chatbot. |
| **Rewards & Gamification** | | | | |
| `GET` | `/api/rewards/stats` | Bearer | Any | Fetch user stats (coin balance, current streak, sessions). |
| `PUT` | `/api/rewards/stats` | Bearer | Any | Sync client coin earnings, check-ins, and streaks to server. |
| `GET` | `/api/rewards/redeemed` | Bearer | Any | Get all previously redeemed guides/meditations. |
| `POST` | `/api/rewards/redeemed` | Bearer | Any | Save a newly redeemed reward to user's personal vault. |
| `GET` | `/api/rewards/mindspace` | Bearer | Any | List patient's voice check-in records. |
| `POST` | `/api/rewards/mindspace` | Bearer | Any | Save a voice check-in transcript and coins rewarded. |
| **History** | | | | |
| `GET` | `/api/history/chats` | Bearer | Any | Fetch all saved chat sessions. |
| `POST` | `/api/history/chats` | Bearer | Any | Save or update a conversation session. |
| `DELETE` | `/api/history/chats/:id` | Bearer | Any | Delete a specific conversation session. |
| `GET` | `/api/history/mindspace` | Bearer | Any | Retrieve MindSpace voice session logs. |
| `DELETE` | `/api/history/mindspace/:id` | Bearer | Any | Remove a MindSpace log entry. |
| **Clinical Notifications** | | | | |
| `POST` | `/api/mental-health/notifications` | Service/Open | Bot/Server | Called by Chatbot server to dispatch doctor alerts. |
| `GET` | `/api/mental-health/notifications` | Bearer | Doctor | Fetch all triage notifications for logged-in doctor. |
| `GET` | `/api/mental-health/notifications/patient/:id` | Bearer | Doctor | Fetch triage notifications for a particular patient. |
| `PUT` | `/api/mental-health/notifications/:id/read` | Bearer | Doctor | Mark an alert notification as acknowledged/read. |

---

### B. Python FastAPI AI Chatbot (`http://<host>:8000`)

| Method | Endpoint | Request Payload / Format | Response & Functionality |
|---|---|---|---|
| `GET` | `/health` | None | Service status (`{"status": "ok", "service": "hearme-chatbot"}`) |
| `POST` | `/chat` | JSON: `{"message": "...", "session_id": "...", "language": "en", "medical_context": "..."}` | Synchronous LLM reply using Llama 3.3 70B with medical safety triage guidelines. |
| `POST` | `/chat/stream` | JSON: `{"message": "...", "session_id": "...", "language": "en", "medical_context": "..."}` | Real-time **Server-Sent Events (SSE)** token stream using Llama 3.1 8B. |
| `POST` | `/mental-health/analyze` | Multipart Form: `audio` (file), `patient_id`, `patient_name`, `doctor_id` (optional), `language` | 1. Transcribes audio via **Groq Whisper Large v3**.<br>2. Generates supportive patient feedback in their native language.<br>3. Generates clinical note + assesses urgency (`low`, `moderate`, `high`).<br>4. Auto-saves notification to Node.js backend. |
| `POST` | `/rewards/redeem` | JSON: `{"reward_type": "guided_meditation" \| "weekly_wellness" \| "premium_health_tips", "language": "en"}` | Generates customized meditation scripts, wellness plans, or tips in selected language. |

---

## 4. Main Features & How They Work

### 1. Dual-Role Architecture & Patient-Doctor Linking
- Users choose **Patient** or **Doctor** upon registration.
- Every user is assigned a unique 6-character uppercase alphanumeric code (e.g., `A3X9K2`).
- Patients link to their doctor by entering the doctor's code. This gives the doctor read access to their triage alerts, chat records, and MindSpace check-ins.

### 2. AI Medical Chatbot (Streaming & Regional Multilingual)
- Supported languages: **English, Hindi, Tamil, Telugu, Marathi, Bengali, Kannada**.
- Built-in clinical knowledge base for skin, respiratory, and neurological conditions.
- Streams token-by-token responses directly to the Flutter UI for low latency.
- Strict safety guardrails: Empathetic triage guidance, clear emergency warnings, non-diagnostic posture.

### 3. Voice-Based "MindSpace" Check-ins & Urgency Detection
- Patients record up to 30 seconds of spoken thoughts about their mental state.
- **Audio Pipeline**:
  1. Flutter records `.m4a` audio using `record` package.
  2. Uploaded to `/mental-health/analyze`.
  3. Audio is transcribed via **Groq Whisper Large v3 Turbo**.
  4. Llama 3.3 generates a warm, comforting message back to the patient.
  5. If linked to a doctor, an automated clinical summary is generated with urgency scoring (`high`, `moderate`, `low`).
  6. High-urgency alerts (e.g., detecting crisis or extreme distress) trigger notifications in the doctor's dashboard.

### 4. Gamification, Mind Coins & Streaks
- **Daily Check-in**: Daily attendance rewards (+10 coins).
- **MindSpace Voice Session**: Completed audio check-in rewards (+20 coins).
- **Chat Conversations**: Conversing with the AI assistant grants coins (+5 coins).
- **Streak Tracking**: Tracks current and best daily streaks.
- **Redemption Store**:
  - *Guided Meditation Script* (100 coins)
  - *Weekly Wellness Plan* (200 coins)
  - *Premium Health Tips* (150 coins)
  - All unlocked content is saved locally and in the cloud vault.

### 5. Doctor Clinical Dashboard
- View list of all linked patients.
- Monitor triage alerts categorized by urgency level with unread badges.
- Access patient details, historical voice transcripts, and AI consultation logs.

---

## 5. Quick Start Guide

### Prerequisites
- Flutter SDK (v3.19+)
- Node.js (v18+)
- Python (v3.10+)
- MongoDB Atlas cluster or local MongoDB instance
- Groq API Key

### 1. Run Node.js Server
```bash
cd server
npm install
# Ensure .env contains:
# PORT=5000
# MONGODB_URI=your_mongodb_connection_string
# JWT_SECRET=your_jwt_secret_key
npm run dev
```

### 2. Run Python Chatbot
```bash
cd chatbot
python -m venv venv
# Windows: .\venv\Scripts\activate
# Linux/Mac: source venv/bin/activate
pip install -r requirements.txt
# Ensure .env contains:
# GROQ_API_KEY=your_groq_api_key
# BACKEND_URL=http://localhost:5000/api
uvicorn main:app --reload --port 8000
```

### 3. Run Flutter Application
```bash
flutter pub get
flutter run -d chrome     # Or windows / android / ios
```
