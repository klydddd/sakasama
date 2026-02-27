# CLAUDE.md — Sakasama Flutter App Build Guide

> This file is the authoritative guide for Claude Opus to build the **Sakasama** Android application — a zero-friction, offline-first PhilGAP compliance companion for Filipino smallholder farmers.

---

## 🌾 Project Overview

**App Name:** Sakasama (Saka + Kasama)  
**Platform:** Android (Flutter, min SDK 21)  
**Target Users:** Filipino smallholder farmers, often elderly, low-tech literacy, rural  
**Primary Language:** Filipino / Cebuano (with English fallback)  
**Design Philosophy:** Offline-first, edge-computing, zero-friction, elderly-friendly  
**Color Palette:** `#2E7D32` (Forest Green), `#FFFFFF` (White), `#A5D6A7` (Light Green accent), `#1B5E20` (Dark Green)

---

## 🏗️ Architecture Overview

```
lib/
├── main.dart                      # App entry point
├── app.dart                       # MaterialApp, theme, routing
├── core/
│   ├── constants/                 # Colors, strings, asset paths
│   ├── theme/                     # AppTheme (green/white, large fonts)
│   ├── utils/                     # Helpers, formatters, validators
│   └── services/
│       ├── database_service.dart  # SQLite via drift
│       ├── ocr_service.dart       # Google ML Kit on-device OCR
│       ├── tts_service.dart       # flutter_tts for voice output
│       ├── stt_service.dart       # speech_to_text for voice input
│       ├── slm_service.dart       # Local SLM / RAG via llama.cpp or Ollama bridge
│       ├── pdf_export_service.dart# Compliance PDF generation
│       └── csv_export_service.dart# CSV export
├── data/
│   ├── models/                    # Farm journal, activity log, compliance record
│   ├── repositories/              # Abstract interfaces
│   └── local/                     # Drift DAOs and table definitions
├── features/
│   ├── onboarding/                # Welcome, language selection, farm setup
│   ├── dashboard/                 # Home screen with large action cards
│   ├── farm_journal/              # Daily log entry, activity list
│   ├── ocr_scan/                  # Camera scan → OCR → form autofill
│   ├── voice_assistant/           # Push-to-talk → SLM → TTS spoken answer
│   ├── compliance_forms/          # PhilGAP ICS form viewer/editor
│   ├── audit_export/              # Generate PDF/CSV compliance portfolio
│   └── settings/                  # Language, farm profile, about
└── l10n/                          # ARB files: Filipino (fil), Cebuano (ceb), English (en)
```

---

## 📱 Screen-by-Screen Specifications

### 1. Onboarding (First Launch Only)
- **Welcome screen** — Large Sakasama logo, tagline in Filipino: *"Ang iyong kasama sa pagsasaka"*
- **Language selection** — 3 large toggle buttons: Filipino | Cebuano | English
- **Farm profile setup** — Farm name, location (province/municipality), crop type (dropdown), farmer name
- **Permissions screen** — Camera, Microphone, Storage with simple icon explanations
- Store onboarding completion flag in SharedPreferences

### 2. Dashboard (Home)
- Top greeting: *"Magandang umaga, [Farmer Name]!"* (time-aware)
- **Progress card** — Days logged / 90 days progress bar with green fill
- **4 large action buttons** (minimum 80px height, 20sp text):
  - 📷 **I-Scan ang Resibo** (Scan Receipt)
  - 📝 **Mag-log ng Aktibidad** (Log Activity)
  - 🎙️ **Tanungin si Saka** (Ask Saka - Voice Assistant)
  - 📄 **I-export ang Ulat** (Export Report)
- Bottom nav: Home | Journal | Saka (voice) | Export

### 3. Farm Journal
- **Activity list** — Scrollable list of logged entries grouped by date
- **Add entry button** — FAB with `+` icon, prominent green color
- **Entry form fields** (large input, 18sp minimum):
  - Date (date picker)
  - Activity type (dropdown: Fertilization, Irrigation, Pest Control, Harvest, etc.)
  - Product/Input used
  - Quantity & unit
  - Notes (optional)
  - Photo attachment (optional)
- Auto-saves to SQLite

### 4. OCR Scan
- Camera viewfinder with green border guide overlay
- Instruction text: *"Itutok ang camera sa resibo o label"*
- **Capture button** — Large circular green button at bottom
- Processing screen with spinner: *"Kinukuha ang impormasyon..."*
- **Review screen** — Extracted fields displayed in editable cards
  - Fields: Date, Product Name, Quantity, Price, Supplier
  - Each field has green highlight if detected, yellow if uncertain
- **Confirm & Save** button → saves to journal entry
- **Retake** button if extraction is poor

### 5. Voice Assistant ("Tanungin si Saka")
- Large microphone button in center (80px diameter)
- Status indicator: Listening | Processing | Speaking
- Conversation display — scrollable Q&A bubbles
- Farmer asks question → STT transcribes → SLM answers → TTS speaks answer
- Pre-loaded sample questions as chips: *"Ano ang PhilGAP?"*, *"Paano mag-apply?"*
- All processing on-device, no network required

### 6. Compliance Forms Viewer
- List of PhilGAP ICS form types (Farm Journal, Pest Monitoring, Harvest Record, etc.)
- Tap to view pre-filled form based on logged data
- Editable fields with large touch targets
- Status badge: ✅ Complete / ⚠️ Incomplete

### 7. Audit Export
- Summary card: entries count, date range, completion percentage
- Toggle: PDF | CSV
- **Generate & Share** button
- Preview of PDF before export
- Share via any installed app (share_plus)

### 8. Settings
- Language toggle
- Farm profile edit
- About / Help screen with PhilGAP guide PDF viewer
- Data backup / restore (local file)

---

## 🎨 UI/UX Design Rules (MUST FOLLOW)

1. **Font sizes** — Never below 16sp for body, 20sp for buttons, 24sp for headings
2. **Touch targets** — Minimum 56dp height for all interactive elements; prefer 72-80dp for primary actions
3. **Color usage** — Green (`#2E7D32`) for primary actions, white backgrounds, light green (`#A5D6A7`) for cards/accents
4. **Icons** — Always pair icons with text labels; use large, simple icons
5. **Contrast** — All text must meet WCAG AA minimum (4.5:1 ratio)
6. **Spacing** — Generous padding (16-24dp) between elements; never cluttered
7. **Error states** — Use plain Filipino language, not technical error codes
8. **Loading states** — Always show progress indicators with descriptive text in Filipino
9. **Confirmation dialogs** — Large buttons, simple yes/no framing in Filipino
10. **Haptic feedback** — Use light haptic on button press for tactile confirmation

---

## 🗄️ Data Models

### FarmProfile
```dart
- id: int (PK)
- farmerName: String
- farmName: String
- location: String
- cropType: String
- createdAt: DateTime
```

### ActivityLog
```dart
- id: int (PK)
- date: DateTime
- activityType: String  // Enum: fertilization, irrigation, pestControl, harvest, other
- productUsed: String?
- quantity: double?
- unit: String?
- notes: String?
- photoPath: String?
- createdAt: DateTime
- isVerified: bool
```

### ComplianceRecord
```dart
- id: int (PK)
- cropCycleId: int
- formType: String
- status: String  // complete, incomplete
- generatedAt: DateTime?
- filePath: String?
```

---

## 🤖 AI/ML Components

### OCR (On-Device)
- **Library:** `google_mlkit_text_recognition`
- Process image → extract raw text → parse with regex rules for receipt fields
- Fallback: manual entry if confidence < threshold
- Handle Tagalog/English mixed text on labels

### Voice Assistant (SLM)
- **Approach:** Use a pre-quantized GGUF model (e.g., Phi-3-mini Q4) bundled with the app OR loaded from local storage on first setup
- Interface via `ffi` + llama.cpp bindings OR use `flutter_ollama` if available
- RAG context: Embed PhilGAP manual chunks as a local vector store (pre-computed embeddings stored in SQLite/JSON)
- Query flow: STT → text → retrieve relevant chunks → SLM prompt → TTS
- **Fallback:** If model not loaded, return pre-written FAQ answers from a JSON lookup table

### Speech-to-Text
- **Library:** `speech_to_text`
- Languages: Filipino (`fil-PH`), Cebuano (fallback to Filipino), English
- On-device recognition where possible

### Text-to-Speech
- **Library:** `flutter_tts`
- Language: Filipino (`fil-PH`)
- Rate: 0.85 (slightly slower for elderly users)
- Pitch: 1.0

---

## 📄 PDF Generation

- **Library:** `pdf` (dart pdf package) + `printing`
- Template: Mimic official PhilGAP ICS form layout
- Include farm header, date range, activity table, farmer signature line
- Embed logo assets in header

---

## 🌐 Localization

- Use Flutter's `flutter_localizations` + `intl`
- ARB files in `lib/l10n/`:
  - `app_en.arb` — English
  - `app_fil.arb` — Filipino (primary)
  - `app_ceb.arb` — Cebuano
- All UI strings must be localized — no hardcoded text in widgets

---

## ⚡ Performance Constraints

- Target: stable on 2GB RAM Android devices
- **Lazy load** AI components — load OCR engine only when scan screen is active; dispose when leaving
- **Model loading** — Load SLM in background after app fully rendered; show "Naghahanda si Saka..." indicator
- Minimize background services; use WorkManager only for scheduled report reminders
- SQLite operations on background isolate (use `compute()` or Drift's async APIs)
- Image compression before OCR — resize to max 1280px width before processing

---

## 🔒 Offline-First Rules

- **Zero network calls** for core features — OCR, voice assistant, journal, export all work offline
- Network optional only for: future cloud backup feature (not in MVP)
- Use `connectivity_plus` to detect state but never block UI on network absence
- All assets (PhilGAP manual content, SLM model) must be bundled or downloadable on first launch

---

## 📁 Asset Structure

```
assets/
├── images/
│   ├── sakasama_logo.png
│   ├── onboarding_1.png
│   └── philgap_badge.png
├── fonts/
│   └── Nunito/          # Rounded, friendly, legible font
├── data/
│   ├── philgap_faq.json         # Pre-written FAQ for voice assistant fallback
│   ├── philgap_manual_chunks.json  # RAG context chunks
│   └── activity_types.json      # Dropdown options in all languages
└── models/
    └── README.md                # Instructions to download GGUF model on first launch
```

---

## 🧪 Testing Checklist

Before considering any feature complete, verify:
- [ ] Works fully offline (airplane mode)
- [ ] Works on a simulated 2GB RAM device (use Android emulator with 2GB RAM config)
- [ ] All text is in Filipino (or selected language)
- [ ] All buttons are at least 56dp tall
- [ ] OCR correctly extracts date, product name, quantity from a sample receipt photo
- [ ] Voice assistant responds in Filipino
- [ ] PDF export opens correctly in a PDF viewer
- [ ] No crashes on low memory; AI components dispose properly

---

## 🚀 Build & Run

```bash
# Install dependencies
flutter pub get

# Generate localization files
flutter gen-l10n

# Generate Drift database code
dart run build_runner build --delete-conflicting-outputs

# Run on connected Android device
flutter run --release

# Build APK
flutter build apk --release --target-platform android-arm,android-arm64
```

---

## 📌 MVP Scope (Build in this order)

1. **Core infrastructure** — Theme, routing, localization, SQLite setup
2. **Onboarding** — Language selection + farm profile
3. **Dashboard** — Home screen with navigation
4. **Farm Journal** — Manual activity logging (CRUD)
5. **OCR Scan** — Camera → extract → review → save to journal
6. **Audit Export** — PDF/CSV generation from journal entries
7. **Voice Assistant** — STT + FAQ lookup + TTS (SLM as enhancement)
8. **Settings** — Language switch, profile edit

---

## ⚠️ Important Notes for Claude Opus

- **Always use Filipino strings** in UI widgets unless building the English/Cebuano variant
- **Never use `ListView` without `physics: BouncingScrollPhysics()`** — smoother scroll feel
- **Always handle empty states** — show encouraging message + action button when list is empty
- **Database migrations** — Use Drift's migration API properly; never drop user data on schema changes
- **Permissions** — Always explain WHY the permission is needed before requesting it (show a pre-permission rationale screen)
- **The `SlmService`** — Start with the JSON FAQ fallback implementation; wire SLM as an enhancement layer
- **Error handling** — Catch all exceptions, log to debug, show user-friendly Filipino message
- **Accessibility** — Add `Semantics` widgets to all custom components for screen reader support