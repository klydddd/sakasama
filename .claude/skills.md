# SKILLS.md — Required Developer Skills for Sakasama

> This document outlines every technical and domain skill Claude Opus must apply when building the Sakasama Flutter application for PhilGAP compliance.

---

## 1. 🐦 Flutter & Dart Mastery

### Core Flutter
- **Widget tree architecture** — Know when to use `StatelessWidget` vs `StatefulWidget` vs `ConsumerWidget` (Riverpod)
- **State management with Riverpod** — Use `StateNotifierProvider`, `FutureProvider`, `StreamProvider`; never use raw `setState` for business logic
- **Navigation** — Use `go_router` for declarative routing; handle deep links and named routes
- **Responsive layout** — Use `LayoutBuilder`, `MediaQuery`, `Flexible`, `Expanded` to adapt to different screen sizes
- **Custom painting** — Use `CustomPainter` for progress rings, scan overlays
- **Animations** — `AnimationController`, `AnimatedContainer`, `Hero` transitions for smooth UX
- **Isolates & `compute()`** — Offload heavy processing (OCR, PDF generation) to background isolates

### Dart Language
- **Async/await & Futures** — Proper error handling with try/catch in async contexts
- **Streams** — Use streams for real-time data (microphone input, TTS progress)
- **Extension methods** — Write readable, reusable extensions on `String`, `DateTime`, `List`
- **Null safety** — Fully null-safe code; use `?`, `!`, `??`, `late` appropriately
- **FFI (dart:ffi)** — Know how to bridge native C libraries (llama.cpp) through FFI
- **Freezed / code generation** — Use `freezed` for immutable data classes and union types

---

## 2. 🗄️ Local Database (Drift / SQLite)

- **Schema definition** — Define typed `Table` classes with proper column types and constraints
- **DAOs** — Separate Data Access Objects for each feature domain
- **Queries** — Write type-safe queries; use `select`, `join`, `where`, `orderBy`
- **Migrations** — Implement `MigrationStrategy` with `onUpgrade` to safely evolve schema
- **Reactive queries** — Use `watchSingleOrNull`, `watchAll` to drive UI with live data
- **Background access** — Run heavy queries in background isolate via Drift's `isolateSupport`
- **JSON serialization** — Store complex objects as JSON strings when needed

---

## 3. 📷 On-Device OCR (Google ML Kit)

- **Text recognition setup** — Initialize `TextRecognizer` with Latin + Devanagari scripts for mixed labels
- **Image preprocessing** — Resize, normalize, and compress `XFile` before passing to recognizer
- **Text block parsing** — Navigate `RecognizedText` → `TextBlock` → `TextLine` → `TextElement`
- **Field extraction with regex** — Write regex patterns to extract:
  - Dates: `\d{1,2}[/-]\d{1,2}[/-]\d{2,4}` and Filipino date formats
  - Quantities: `\d+(\.\d+)?\s*(kg|g|L|mL|sack|bag)`
  - Product names: uppercase noun phrase patterns
  - Prices: `PHP?\s*[\d,]+(\.\d{2})?`
- **Confidence scoring** — Flag extractions below threshold (< 0.7) for manual review
- **Model lifecycle** — Close `TextRecognizer` when not in use to free memory

---

## 4. 🎙️ Speech & Audio Processing

### Speech-to-Text
- **`speech_to_text` plugin** — Initialize, handle permission, start/stop listening
- **Locale handling** — Set `LocaleName` to `fil-PH` for Filipino recognition
- **Partial results** — Display live transcription as farmer speaks
- **Silence detection** — Auto-stop after 2s of silence; show "Natapos na" indicator
- **Error recovery** — Handle `speech_to_text` errors gracefully; prompt retry

### Text-to-Speech
- **`flutter_tts`** — Set language (`fil-PH`), speech rate (0.85), pitch (1.0), volume (1.0)
- **Queue management** — Stop previous utterance before starting new one
- **Completion callbacks** — Use `onComplete` to update UI state after speech ends
- **Audio focus** — Request audio focus before speaking, release after

---

## 5. 🤖 On-Device AI / Small Language Model

### RAG (Retrieval-Augmented Generation) — Primary Approach
- **Embedding** — Pre-compute embeddings for PhilGAP manual chunks offline; store as Float32List in SQLite or JSON
- **Cosine similarity** — Implement vector similarity search in Dart to find relevant chunks at query time
- **Prompt construction** — Build structured prompt: `[CONTEXT]\n{chunks}\n[QUESTION]\n{query}\n[ANSWER]`
- **JSON FAQ fallback** — Implement key-based lookup from `philgap_faq.json` as guaranteed offline fallback

### llama.cpp FFI Bridge (Enhancement Layer)
- **GGUF model loading** — Load quantized model (Q4_K_M, ~2GB) from local storage path
- **FFI bindings** — Write `DynamicLibrary` bindings for `llama_init`, `llama_eval`, `llama_token_to_str`
- **Tokenization** — Handle token streaming and reconstruct text
- **Memory management** — Call `llama_free` and `llama_free_model` on dispose
- **Threading** — Run inference on dedicated isolate; never on main thread

---

## 6. 📄 PDF Generation

- **`pdf` package** — Use `pw` (PdfWidgets) to build document layout
- **PhilGAP ICS template** — Reproduce official form structure:
  - Header with farm info, certification period, crop type
  - Activity log table (date, activity, product, quantity, notes)
  - Signature and certification block at footer
- **Table rendering** — Use `pw.TableHelper.fromTextArray` for activity log tables
- **Page breaks** — Handle multi-page documents with proper `pw.Table` spanning
- **Asset embedding** — Embed Sakasama logo and DA logo in PDF header
- **File saving** — Save to app's documents directory via `path_provider`
- **Share/print** — Use `printing` package for share sheet and system print dialog

---

## 7. 📦 State Management (Riverpod)

- **Provider organization** — One provider file per feature; no god-providers
- **`AsyncValue`** — Handle `.loading`, `.data`, `.error` states in UI with `when()`
- **`Notifier` pattern** — Use `AsyncNotifier` for operations that load data + perform mutations
- **`ref.invalidate()`** — Refresh providers after mutations
- **`ProviderScope` overrides** — Use for testing and onboarding flow
- **`keepAlive`** — Use for providers that should survive screen navigation (farm profile, settings)

---

## 8. 🌐 Internationalization (i18n)

- **Flutter's `intl` package** — Generate `.dart` files from `.arb` using `flutter gen-l10n`
- **ARB file structure** — Key naming: `featureName_widgetDescription_state` (e.g., `dashboard_scanButton_label`)
- **Plurals** — Use `{count, plural, one{...} other{...}}` for correct Filipino pluralization
- **Date/number formatting** — Use `DateFormat` and `NumberFormat` with locale
- **RTL safety** — Even for LTR languages, avoid hardcoded `left`/`right`; use `start`/`end`
- **Language switching** — Hot-switch locale without restarting app; persist choice in SharedPreferences

---

## 9. 📷 Camera Integration

- **`image_picker`** — Gallery selection for existing photos
- **`camera` plugin** — Full camera control with custom overlay (scan guide frame)
- **Custom viewfinder** — Draw green rectangle guide overlay using `CustomPainter` over camera preview
- **Permissions flow** — Request camera permission with rationale; handle permanent denial gracefully
- **Image compression** — Use `flutter_image_compress` to reduce image before OCR

---

## 10. 🎨 UI/UX for Low-Literacy, Elderly Users

- **Visual hierarchy** — Most important action always biggest and greenest
- **Icon + label pairing** — Never icon-only; always text label beneath
- **Feedback loops** — Every tap → ripple + haptic + visual state change
- **Progress communication** — Never leave user wondering; always show spinner + descriptive text
- **Error plain language** — Write errors as: *"Hindi nakuha ang larawan. Subukang muli."* not "OCR_ERROR_403"
- **Confirmation before delete** — Modal with large Cancel (left) / Delete (right, red) buttons
- **Undo capability** — Soft-delete pattern: mark as deleted, show snackbar with undo for 5 seconds
- **Large scroll targets** — List items minimum 72dp height
- **Step-by-step flows** — Multi-step forms use one field per screen with back navigation

---

## 11. ⚙️ Android Platform Skills

- **`AndroidManifest.xml`** — Declare permissions: `CAMERA`, `RECORD_AUDIO`, `WRITE_EXTERNAL_STORAGE`, `READ_EXTERNAL_STORAGE`
- **`build.gradle`** — Configure `minSdkVersion 21`, `targetSdkVersion 34`, enable `multidex`
- **ProGuard rules** — Add keep rules for ML Kit and llama.cpp native libs
- **APK size optimization** — Use `--split-per-abi` for release builds; include ABI filters `armeabi-v7a`, `arm64-v8a`
- **FileProvider** — Configure for sharing exported files via `share_plus`
- **Scoped storage** — Use `getExternalStorageDirectory()` or `getApplicationDocumentsDirectory()` per API level

---

## 12. 🧪 Testing Skills

- **Unit tests** — Test parsers (OCR field extraction regex), data models, repository logic
- **Widget tests** — Test that screens render correctly with mock providers
- **Integration tests** — Test full OCR scan → journal save → export flow
- **Mock services** — Use `Mockito` or manual fakes for OCR, TTS, database in tests
- **Accessibility testing** — Run `flutter test --accessibility` and verify semantic labels

---

## 13. 🌾 Domain Knowledge — PhilGAP

- **ICS forms** — Understand the Internal Control System structure: Farm Journal, Pest Monitoring Log, Harvest Record, Input Inventory, Water Source Record
- **90-day requirement** — App must enforce and track the mandatory 90-day documentation period before audit
- **Certification workflow** — Farmer logs daily → inspector reviews ICS → on-site audit → certification
- **Common failure points** — Incomplete records, missing dates, unverified inputs → app must warn when these are missing
- **Allowed inputs** — PhilGAP restricts certain pesticides; app should flag if a scanned product is commonly restricted
- **Key BAFS standards** — PNS/BAFS 49:2021 for fruits and vegetables; understand the 4 pillars: Food Safety, Environmental Management, Worker Health & Safety, Animal Welfare (where applicable)

---

## 14. 🔐 Data Privacy & Security

- **No PII to network** — All farmer data stays on device in MVP
- **Encrypted SharedPreferences** — Use `flutter_secure_storage` for sensitive settings
- **File permissions** — Exported files stored in app-private directory; shared only via user-initiated share sheet
- **No analytics tracking** — Do not add Firebase Analytics or any tracking SDK in MVP

---

## 15. 📝 Code Quality Standards

- **Lint rules** — Follow `flutter_lints` + custom rules for `avoid_print`, `prefer_const_constructors`
- **Folder structure discipline** — Never put business logic in widget files; always in services or notifiers
- **Documentation** — Every public class and method has `///` dartdoc comments in English
- **Naming conventions** — `snake_case` for files, `PascalCase` for classes, `camelCase` for variables/methods, `SCREAMING_SNAKE` for constants
- **No magic numbers** — All UI constants (padding, font sizes, radii) defined in `AppDimensions` class
- **Commit discipline** — Feature-by-feature; each feature branch merged only when passing all tests