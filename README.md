# 🏥 OfflineMedic

> Offline AI-powered medical assistant for rural communities — built on Gemma 4 via LiteRT. No internet required.

![Gemma 4](https://img.shields.io/badge/Gemma_4-E4B-blue?style=flat-square)
![LiteRT](https://img.shields.io/badge/LiteRT-Google_AI_Edge-green?style=flat-square)
![Flutter](https://img.shields.io/badge/Flutter-Android-blue?style=flat-square)
![License](https://img.shields.io/badge/License-CC_BY_4.0-lightgrey?style=flat-square)
![Hackathon](https://img.shields.io/badge/Gemma_4_Good_Hackathon-2026-orange?style=flat-square)

---

## 🎥 Demo Video
[▶ Watch on YouTube](https://youtube.com/your-link)

## 🌐 Live Demo
[Try the Demo](https://your-demo-link)

## 📦 Download APK
[⬇ Download OfflineMedic.apk](https://github.com/SAIRAJ41/OfflineMedic/releases/latest)

---

## 📌 Table of Contents
- [Overview](#overview)
- [The Problem](#the-problem)
- [How It Works](#how-it-works)
- [Features](#features)
- [App Screens](#app-screens)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Gemma 4 Usage](#gemma-4-usage)
- [Project Structure](#project-structure)
- [Setup & Installation](#setup--installation)
- [Team](#team)
- [Prize Tracks](#prize-tracks)
- [License](#license)

---

## Overview

OfflineMedic is a fully offline Android application built for community health workers (CHWs) and rural communities where internet connectivity is unavailable or unreliable. The app runs Google's Gemma 4 E4B model entirely on the device via LiteRT — no server, no cloud, no data connection needed at runtime.

A health worker can photograph a wound, speak symptoms in Hindi or Marathi, or type a question and the app instantly returns a color-coded triage result with step-by-step first aid guidance in the local language. If the situation is critical, the app triggers an emergency calling system that works over basic GSM — not internet.

---

## The Problem

Over 3.5 billion people live in areas with limited or no internet access. Community health workers in rural India, Africa, and Southeast Asia make critical medical decisions daily with:

- No access to medical references
- No doctors nearby
- No internet connectivity
- No reliable decision support tools

Existing medical apps require internet to function — making them useless in exactly the situations where they are needed most. A wrong triage call can cost a life.

---

## How It Works

```
User Input (Photo / Voice / Text)
            │
            ▼
┌─────────────────────────┐
│   Whisper.cpp (local)   │  ← Voice → Text (offline STT)
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│   Gemma 4 E4B via LiteRT│  ← Core AI brain (100% on-device)
│   - Reads image/text    │
│   - Reasons medically   │
│   - Generates triage    │
│   - Translates output   │
└────────────┬────────────┘
             │
    ┌─────────────────┐
    ▼                 ▼
🩺 Triage Result   🚨 Emergency System
(Red/Yellow/Green)  (108 call + GPS SMS)
```

### Input Layer
- **Photo** — photographs wound, burn, rash, or medication label → Gemma 4 vision encoder analyzes on-device
- **Voice** — Whisper.cpp (base model) transcribes speech locally in Hindi, Marathi, English, handles mixed language input
- **Text** — typed symptoms in any supported script including Devanagari

### AI Processing (Gemma 4)
- Visual wound and condition analysis
- Symptom understanding from messy panic-style input
- 3-level triage classification (URGENT / MODERATE / MILD)
- Step-by-step first aid generation
- Red flag danger detection
- Drug interaction checking
- Emergency dispatcher script generation
- Multilingual output

### Output Layer
- Color-coded triage result
- Step-by-step instructions with icons
- Voice readout via Android TTS
- Emergency popup with one-tap 108 dial
- Offline hospital map

---

## Features

### Input Features
- Voice commands in local language (Whisper.cpp)
- Text input with local script support
- Photo-based condition analysis (Gemma 4 multimodal)
- Image quality validation before processing
- Panic handling — fallback to visual buttons if speech is unclear

### Predefined Emergency Cards
Instantly available without AI processing — works even during model load:
- Heart attack response
- CPR step-by-step
- Snake bite treatment
- Choking (Heimlich manoeuvre)
- Severe bleeding control
- Seizure first response
- Burns and scalds treatment
- Drowning / unconscious patient

### Output Features
- **Condition action response** — what to do now, what NOT to do, when to seek help
- **Color-based triage** — Red (urgent) / Yellow (moderate) / Green (mild)
- **Step-by-step first aid** — short numbered instructions, icon-based for low-literacy users
- **Voice readout** — Android TTS reads instructions aloud
- **Simple language** — plain English, no medical jargon
- **Local language support** — Hindi and Marathi

### Emergency System
- One-tap auto-dial to 108 (auto-detected by GPS region)
- Gemma 4 generates a dispatcher briefing script before the call
- SMS fallback with GPS coordinates if call fails
- Nearest hospital finder from pre-downloaded OpenStreetMap data
- One-tap call to nearest PHC or clinic

### Trust & Safety
- Not positioned as a doctor replacement
- No final diagnosis claims
- No exact species or disease certainty stated
- Critical case escalation warning on every URGENT result
- Encourages professional help on every moderate and urgent result
- Trust disclaimer shown contextually on every result screen
- Gemma 4 confidence level shown on output

### Drug Interaction Checker
- Photograph medication label — Gemma 4 reads drug name
- Checks interactions against offline database
- Flags dangerous combinations in plain language
- Dosage verification against WHO safe range by age and weight

### Case History & Logging
- Every assessment auto-saved in local SQLite
- Today's case summary on dashboard
- CHW can add follow-up notes
- Export to PDF when internet is available

### User Modes
| Health Worker Mode | Emergency Mode |
|---|---|
| Full feature set | Ultra-simplified 3-button interface |
| Case history logging | Larger text throughout |
| Drug checker | More aggressive 108 prompting |
| Detailed triage output | Designed for panicking non-medical users |

---

## App Screens

| Screen | Description |
|---|---|
| Home Dashboard | Case summary, Gemma 4 status, recent assessments |
| Input Selection | Choose photo / voice / text, select language |
| Voice Recording | Live Whisper.cpp transcription with waveform |
| Triage — RED | Urgent result with immediate steps + emergency button |
| Triage — YELLOW | Moderate result with monitoring instructions |
| Triage — GREEN | Mild result with home care guidance |
| Emergency Call | Auto-dial 108, dispatcher script, SMS fallback |
| Drug Checker | Label scan, interaction result, dosage check |
| Offline Map | Nearby hospitals and clinics with one-tap call |

---

## Tech Stack

| Component | Technology |
|---|---|
| AI Model | Gemma 4 E4B |
| Inference Runtime | LiteRT (Google AI Edge) |
| Speech-to-Text | Whisper.cpp — base model |
| Text-to-Speech | Android native TTS |
| App Framework | Flutter |
| Local Database | SQLite |
| Offline Maps | OpenStreetMap pre-downloaded tiles |
| Fine-tuning | Unsloth on Kaggle GPU |
| Emergency Calls | Android telephony API (GSM only) |
| Hospital Data | India Health Facilities (data.gov.in) |

---

## Architecture

```
OfflineMedic Android App
│
├── UI Layer (Flutter)
│   ├── 9 screens
│   ├── Language switcher
│   └── TTS voice readout
│
├── Input Layer
│   ├── Camera (photo)
│   ├── Whisper.cpp (voice → text)
│   └── Text input
│
├── AI Layer
│   ├── Gemma 4 E4B (LiteRT runtime)
│   ├── System prompt (medical behavior control)
│   └── Structured JSON output parser
│
├── Local Database (SQLite)
│   ├── Hospital directory
│   ├── Emergency numbers by country
│   ├── Predefined emergency cards
│   └── Case history logs
│
└── Emergency Layer
    ├── GSM auto-dial (108)
    ├── SMS + GPS fallback
    └── Offline hospital map (OpenStreetMap)
```

---

## Gemma 4 Usage

Gemma 4 E4B is the core intelligence of OfflineMedic. It runs 100% on-device via Google's LiteRT runtime with no internet connection required at runtime.

### Model Details
- **Model**: Gemma 4 E4B (4 billion parameters, edge-optimized)
- **Runtime**: Google LiteRT (Google AI Edge)
- **Fine-tuned with**: Unsloth on Kaggle GPU

### What Gemma 4 Does

| Task | Description |
|---|---|
| Visual analysis | Analyzes wound, rash, and label photos |
| Symptom reasoning | Understands messy panic-style input |
| Triage | Classifies URGENT / MODERATE / MILD |
| First aid | Generates step-by-step instructions |
| Danger detection | Identifies red flag warning signs |
| Drug checking | Cross-references medication interactions |
| Emergency script | Generates dispatcher briefing for 108 call |
| Translation | Outputs in Hindi, Marathi, English |

### System Prompt
```
You are OfflineMedic, an AI assistant for community
health workers in rural India.

Rules:
- Always give 3-level triage: URGENT / MODERATE / MILD
- Always list step-by-step first aid actions
- Always end with red flag warning signs
- Use simple language, no medical jargon
- If URGENT, always recommend hospital immediately
- Output in the user's chosen language
- Be conservative — when in doubt, escalate
- You are a first-aid guide, not a doctor
```

### Structured Output Format
```json
{
  "triage_level": "URGENT",
  "condition": "Suspected cellulitis",
  "do_now": ["Clean wound", "Apply antiseptic"],
  "do_not": ["Do not apply ice"],
  "red_flags": ["Fever above 104F", "Red streaks spreading"],
  "emergency_action": "CALL_NOW",
  "emergency_number": "108",
  "dispatcher_script": "I have an emergency...",
  "confidence": "high",
  "disclaimer": "This is first-aid guidance, not a diagnosis."
}
```

---

## Project Structure

```
OfflineMedic/
├── README.md
├── LICENSE
├── app/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── screens/
│   │   │   ├── home_screen.dart
│   │   │   ├── input_screen.dart
│   │   │   ├── voice_screen.dart
│   │   │   ├── triage_screen.dart
│   │   │   ├── emergency_screen.dart
│   │   │   ├── drug_checker_screen.dart
│   │   │   └── map_screen.dart
│   │   ├── services/
│   │   │   ├── gemma_service.dart
│   │   │   ├── voice_service.dart
│   │   │   ├── emergency_service.dart
│   │   │   └── database_service.dart
│   │   └── models/
│   │       └── triage_result.dart
│   ├── android/
│   └── pubspec.yaml
├── ai/
│   ├── prompts/
│   │   └── medical_system_prompt.txt
│   └── litert_setup/
│       └── gemma_litert_config.dart
├── fine-tuning/
│   └── gemma4_medic_unsloth.ipynb
├── data/
│   ├── emergency_numbers.json
│   ├── emergency_cards.json
│   └── build_hospital_db.py
└── docs/
    ├── architecture.png
    └── screens/
```

---

## Setup & Installation

### Requirements
- Android device with 4GB+ RAM
- Android 8.0 or above
- WiFi connection for first-time setup only

### Install from APK
```
1. Download OfflineMedic.apk from Releases
2. On your Android device:
   Settings → Security → Enable "Install from unknown sources"
3. Open the downloaded APK and install
4. Open OfflineMedic
5. Complete one-time WiFi setup:
   - Downloads Gemma 4 E4B model (~2GB)
   - Downloads offline maps for your district
   - Sets your region and language
6. Turn off internet — app works fully offline ✅
```

### Build from Source
```bash
# Clone the repo
git clone https://github.com/SAIRAJ41/OfflineMedic.git
cd OfflineMedic/app

# Install Flutter dependencies
flutter pub get

# Download Whisper model
# Place ggml-base.bin in assets/models/

# Download Gemma 4 E4B LiteRT model
# Place gemma4_e4b.tflite in assets/models/

# Run the app
flutter run
```

### Flutter Dependencies
```yaml
dependencies:
  whisper_flutter_new: ^1.0.0
  record: ^5.0.0
  path_provider: ^2.0.0
  sqflite: ^2.0.0
  flutter_map: ^6.0.0
```

### Android Permissions Required
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.CALL_PHONE"/>
<uses-permission android:name="android.permission.SEND_SMS"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
```

---

## App Size

| Component | Size |
|---|---|
| Flutter app (APK) | ~15 MB |
| Whisper base model | ~75 MB |
| Offline maps (district) | ~150 MB |
| Hospital directory | ~20 MB |
| Emergency cards + data | ~10 MB |
| **Total (excluding Gemma 4)** | **~270 MB** |
| Gemma 4 E4B model | ~2 GB |
| **Full install** | **~2.3 GB** |

---

## Team

| Member | Role |
|---|---|
| SAIRAJ41 (Lead) | AI, Gemma 4, LiteRT, GitHub management |
| Member 2 | Flutter UI, all screens |
| Member 3 | Emergency system, offline maps |
| Member 4 | Voice input, drug checker, demo video |

---

## Prize Tracks

| Track | Prize | Qualification |
|---|---|---|
| Main Track | Up to $50,000 | Overall vision + technical depth |
| Health & Sciences | $10,000 | Life-saving medical tool for rural communities |
| LiteRT Special | $10,000 | Gemma 4 E4B running via Google AI Edge LiteRT |
| Unsloth Special | $10,000 | Fine-tuned Gemma 4 published with weights |

**Total eligibility: up to $80,000**

---

## License

This project is licensed under the [Creative Commons Attribution 4.0 International License](LICENSE).

---

## Hackathon

**Gemma 4 Good Hackathon 2026** — hosted on Kaggle by Google LLC  
Submission deadline: May 18, 2026  
[Competition Page](https://www.kaggle.com/competitions/gemma-4-good-hackathon)

---

*Open source. Free. For the 3.5 billion people who need it most.*
