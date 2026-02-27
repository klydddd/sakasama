# REQUIREMENTS.md — Sakasama Flutter App Dependencies & Setup

> Complete specification of all packages, native dependencies, assets, configurations, and generated files required to build and run the Sakasama Android application.

---

## 📋 Flutter & Dart SDK Requirements

| Requirement | Version |
|---|---|
| Flutter SDK | `>=3.19.0` |
| Dart SDK | `>=3.3.0 <4.0.0` |
| Android minSdkVersion | `21` (Android 5.0 Lollipop) |
| Android targetSdkVersion | `34` (Android 14) |
| Android compileSdkVersion | `34` |
| Java SDK | `17` (required by Gradle 8+) |
| Gradle | `8.3` |
| AGP (Android Gradle Plugin) | `8.1.0` |

---

## 📦 `pubspec.yaml` — Full Dependency List

```yaml
name: sakasama
description: Zero-friction offline-first PhilGAP compliance companion for Filipino smallholder farmers.
publish_to: none
version: 1.0.0+1

environment:
  sdk: '>=3.3.0 <4.0.0'
  flutter: '>=3.19.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # ── State Management ──────────────────────────────────────────────────────
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

  # ── Navigation ────────────────────────────────────────────────────────────
  go_router: ^13.2.1

  # ── Local Database (SQLite) ───────────────────────────────────────────────
  drift: ^2.18.0
  drift_flutter: ^0.2.0
  sqlite3_flutter_libs: ^0.5.24
  path_provider: ^2.1.3
  path: ^1.9.0

  # ── On-Device OCR ─────────────────────────────────────────────────────────
  google_mlkit_text_recognition: ^0.13.1

  # ── Camera & Image ────────────────────────────────────────────────────────
  camera: ^0.11.0+1
  image_picker: ^1.1.2
  flutter_image_compress: ^2.3.0
  image: ^4.1.7

  # ── Speech & Audio ────────────────────────────────────────────────────────
  speech_to_text: ^6.6.2
  flutter_tts: ^4.0.2
  permission_handler: ^11.3.1

  # ── PDF Generation & Export ───────────────────────────────────────────────
  pdf: ^3.11.0
  printing: ^5.13.1
  share_plus: ^9.0.0
  open_filex: ^4.4.1

  # ── CSV Export ────────────────────────────────────────────────────────────
  csv: ^6.0.0

  # ── Utilities ─────────────────────────────────────────────────────────────
  intl: ^0.19.0
  shared_preferences: ^2.2.3
  flutter_secure_storage: ^9.2.2
  connectivity_plus: ^6.0.3
  uuid: ^4.4.0
  collection: ^1.18.0
  equatable: ^2.0.5

  # ── UI Components ─────────────────────────────────────────────────────────
  flutter_svg: ^2.0.10+1
  cached_network_image: ^3.3.1       # for any future remote images
  shimmer: ^3.0.0                    # loading skeleton screens
  lottie: ^3.1.2                     # animated illustrations (onboarding)
  flutter_animate: ^4.5.0            # micro-animations
  gap: ^3.0.1                        # SizedBox shorthand
  modal_bottom_sheet: ^3.0.0

  # ── Code Generation Support ───────────────────────────────────────────────
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0

  # Code generators
  build_runner: ^2.4.11
  drift_dev: ^2.18.0
  riverpod_generator: ^2.4.0
  freezed: ^2.5.2
  json_serializable: ^6.8.0

  # Testing
  mockito: ^5.4.4
  fake_async: ^1.3.1

flutter:
  uses-material-design: true
  generate: true  # enables flutter gen-l10n

  assets:
    - assets/images/
    - assets/data/
    - assets/fonts/Nunito/

  fonts:
    - family: Nunito
      fonts:
        - asset: assets/fonts/Nunito/Nunito-Regular.ttf
        - asset: assets/fonts/Nunito/Nunito-Medium.ttf
          weight: 500
        - asset: assets/fonts/Nunito/Nunito-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Nunito/Nunito-Bold.ttf
          weight: 700
        - asset: assets/fonts/Nunito/Nunito-ExtraBold.ttf
          weight: 800
```

---

## 🤖 Native / Platform Libraries

### llama.cpp (Optional — SLM Enhancement)
```
# Clone and build for Android (arm64-v8a, armeabi-v7a)
git clone https://github.com/ggerganov/llama.cpp
cd llama.cpp

# Build with Android NDK
cmake -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK/build/cmake/android.toolchain.cmake \
      -DANDROID_ABI=arm64-v8a \
      -DANDROID_PLATFORM=android-21 \
      -DLLAMA_BUILD_TESTS=OFF \
      -B build-android-arm64

cmake --build build-android-arm64 --config Release

# Place libllama.so in:
# android/app/src/main/jniLibs/arm64-v8a/libllama.so
# android/app/src/main/jniLibs/armeabi-v7a/libllama.so
```

### Model File (GGUF)
```
# Recommended model: Phi-3-mini-4k-instruct-q4.gguf (~2.2GB)
# Download from: https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf

# On first app launch, prompt user to download model (optional feature)
# Store at: {getApplicationDocumentsDirectory()}/models/phi3-mini-q4.gguf
```

---

## 📁 Required File Structure

```
sakasama/
├── android/
│   ├── app/
│   │   ├── src/main/
│   │   │   ├── AndroidManifest.xml          ← see permissions below
│   │   │   └── jniLibs/
│   │   │       ├── arm64-v8a/
│   │   │       │   └── libllama.so          ← compiled native lib (optional)
│   │   │       └── armeabi-v7a/
│   │   │           └── libllama.so
│   │   └── build.gradle                     ← see config below
│   ├── gradle/
│   │   └── wrapper/gradle-wrapper.properties
│   └── build.gradle
│
├── assets/
│   ├── images/
│   │   ├── sakasama_logo.png                ← app logo (512x512)
│   │   ├── sakasama_logo_white.png          ← white variant for dark BGs
│   │   ├── onboarding_farm.png              ← onboarding illustration
│   │   ├── onboarding_scan.png
│   │   ├── onboarding_voice.png
│   │   └── philgap_badge.png               ← PhilGAP certification logo
│   │
│   ├── fonts/Nunito/
│   │   ├── Nunito-Regular.ttf
│   │   ├── Nunito-Medium.ttf
│   │   ├── Nunito-SemiBold.ttf
│   │   ├── Nunito-Bold.ttf
│   │   └── Nunito-ExtraBold.ttf
│   │
│   └── data/
│       ├── philgap_faq.json                 ← pre-written Q&A for voice assistant
│       ├── philgap_manual_chunks.json       ← RAG context chunks from PhilGAP manual
│       ├── activity_types.json             ← dropdown options in all languages
│       └── restricted_inputs.json          ← list of restricted pesticides/chemicals
│
├── lib/
│   ├── main.dart
│   ├── app.dart
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart
│   │   │   ├── app_dimensions.dart
│   │   │   ├── app_strings.dart
│   │   │   └── asset_paths.dart
│   │   ├── theme/
│   │   │   └── app_theme.dart
│   │   ├── utils/
│   │   │   ├── date_utils.dart
│   │   │   ├── file_utils.dart
│   │   │   └── validators.dart
│   │   └── services/
│   │       ├── database_service.dart
│   │       ├── ocr_service.dart
│   │       ├── tts_service.dart
│   │       ├── stt_service.dart
│   │       ├── slm_service.dart
│   │       ├── pdf_export_service.dart
│   │       └── csv_export_service.dart
│   │
│   ├── data/
│   │   ├── models/
│   │   │   ├── farm_profile.dart
│   │   │   ├── activity_log.dart
│   │   │   └── compliance_record.dart
│   │   ├── repositories/
│   │   │   ├── farm_repository.dart
│   │   │   ├── activity_repository.dart
│   │   │   └── compliance_repository.dart
│   │   └── local/
│   │       ├── app_database.dart            ← Drift database definition
│   │       ├── app_database.g.dart          ← generated
│   │       └── daos/
│   │           ├── farm_dao.dart
│   │           ├── activity_dao.dart
│   │           └── compliance_dao.dart
│   │
│   ├── features/
│   │   ├── onboarding/
│   │   │   ├── screens/
│   │   │   │   ├── welcome_screen.dart
│   │   │   │   ├── language_selection_screen.dart
│   │   │   │   ├── farm_setup_screen.dart
│   │   │   │   └── permissions_screen.dart
│   │   │   └── providers/
│   │   │       └── onboarding_provider.dart
│   │   │
│   │   ├── dashboard/
│   │   │   ├── screens/
│   │   │   │   └── dashboard_screen.dart
│   │   │   ├── widgets/
│   │   │   │   ├── progress_card.dart
│   │   │   │   └── action_button_card.dart
│   │   │   └── providers/
│   │   │       └── dashboard_provider.dart
│   │   │
│   │   ├── farm_journal/
│   │   │   ├── screens/
│   │   │   │   ├── journal_list_screen.dart
│   │   │   │   └── activity_form_screen.dart
│   │   │   ├── widgets/
│   │   │   │   ├── activity_log_tile.dart
│   │   │   │   └── empty_journal_widget.dart
│   │   │   └── providers/
│   │   │       └── journal_provider.dart
│   │   │
│   │   ├── ocr_scan/
│   │   │   ├── screens/
│   │   │   │   ├── camera_scan_screen.dart
│   │   │   │   └── ocr_review_screen.dart
│   │   │   ├── widgets/
│   │   │   │   ├── scan_overlay_painter.dart
│   │   │   │   └── extracted_field_card.dart
│   │   │   └── providers/
│   │   │       └── ocr_provider.dart
│   │   │
│   │   ├── voice_assistant/
│   │   │   ├── screens/
│   │   │   │   └── voice_assistant_screen.dart
│   │   │   ├── widgets/
│   │   │   │   ├── microphone_button.dart
│   │   │   │   ├── conversation_bubble.dart
│   │   │   │   └── suggested_questions.dart
│   │   │   └── providers/
│   │   │       └── voice_assistant_provider.dart
│   │   │
│   │   ├── compliance_forms/
│   │   │   ├── screens/
│   │   │   │   ├── forms_list_screen.dart
│   │   │   │   └── form_detail_screen.dart
│   │   │   └── providers/
│   │   │       └── compliance_provider.dart
│   │   │
│   │   ├── audit_export/
│   │   │   ├── screens/
│   │   │   │   └── export_screen.dart
│   │   │   └── providers/
│   │   │       └── export_provider.dart
│   │   │
│   │   └── settings/
│   │       ├── screens/
│   │       │   └── settings_screen.dart
│   │       └── providers/
│   │           └── settings_provider.dart
│   │
│   └── l10n/
│       ├── app_en.arb
│       ├── app_fil.arb
│       └── app_ceb.arb
│
├── test/
│   ├── unit/
│   │   ├── ocr_parser_test.dart
│   │   ├── activity_repository_test.dart
│   │   └── pdf_export_test.dart
│   ├── widget/
│   │   ├── dashboard_screen_test.dart
│   │   └── journal_form_test.dart
│   └── integration/
│       └── scan_to_export_flow_test.dart
│
├── pubspec.yaml
├── analysis_options.yaml
├── l10n.yaml                               ← localization config
├── CLAUDE.md
├── SKILLS.md
└── REQUIREMENTS.md
```

---

## ⚙️ Configuration Files

### `android/app/src/main/AndroidManifest.xml` — Required Permissions
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- Camera for OCR scanning -->
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-feature android:name="android.hardware.camera" android:required="false" />
    <uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />

    <!-- Microphone for voice assistant -->
    <uses-permission android:name="android.permission.RECORD_AUDIO" />

    <!-- Storage for PDF/CSV export -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
        android:maxSdkVersion="32" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
        android:maxSdkVersion="29" />

    <!-- Internet — declared but not required for core features -->
    <uses-permission android:name="android.permission.INTERNET" />

    <application
        android:label="Sakasama"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:requestLegacyExternalStorage="true">

        <!-- FileProvider for sharing exported files -->
        <provider
            android:name="androidx.core.content.FileProvider"
            android:authorities="${applicationId}.fileprovider"
            android:exported="false"
            android:grantUriPermissions="true">
            <meta-data
                android:name="android.support.FILE_PROVIDER_PATHS"
                android:resource="@xml/file_paths" />
        </provider>

        <activity ... />
    </application>
</manifest>
```

### `android/app/build.gradle`
```groovy
android {
    compileSdk 34
    ndkVersion "26.1.10909125"  // Required for llama.cpp native builds

    defaultConfig {
        applicationId "com.ayeyoueff.sakasama"
        minSdk 21
        targetSdk 34
        versionCode 1
        versionName "1.0.0"
        multiDexEnabled true

        ndk {
            abiFilters 'armeabi-v7a', 'arm64-v8a'
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.debug
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'),
                         'proguard-rules.pro'
        }
    }
}

dependencies {
    implementation 'androidx.multidex:multidex:2.0.1'
}
```

### `android/app/proguard-rules.pro`
```proguard
# ML Kit
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }

# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Drift / SQLite
-keep class ** extends com.google.protobuf.GeneratedMessageLite { *; }
```

### `l10n.yaml`
```yaml
arb-dir: lib/l10n
template-arb-file: app_fil.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
nullable-getter: false
```

### `analysis_options.yaml`
```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  errors:
    invalid_annotation_target: ignore  # for freezed
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"

linter:
  rules:
    - avoid_print
    - prefer_const_constructors
    - prefer_const_literals_to_create_immutables
    - use_key_in_widget_constructors
    - always_use_package_imports
    - avoid_dynamic_calls
```

---

## 📊 Data Files (Assets)

### `assets/data/philgap_faq.json` — Structure
```json
{
  "version": "1.0",
  "language": "fil",
  "faqs": [
    {
      "id": "what_is_philgap",
      "keywords": ["philgap", "ano", "sertipikasyon", "certification"],
      "question": "Ano ang PhilGAP?",
      "answer": "Ang PhilGAP o Philippine Good Agricultural Practices ay isang programa ng gobyerno na nagsisiguro na ang mga produktong agricultural ay ligtas at may mataas na kalidad. Kapag naging certified ka, maaari kang magbenta sa mga malalaking tindahan at mag-export."
    }
  ]
}
```

### `assets/data/activity_types.json` — Structure
```json
{
  "types": [
    { "id": "fertilization", "fil": "Paglalagay ng Pataba", "ceb": "Pagbutang ug Abono", "en": "Fertilization" },
    { "id": "irrigation", "fil": "Pagdilig", "ceb": "Pag-irrigate", "en": "Irrigation" },
    { "id": "pest_control", "fil": "Kontrol sa Peste", "ceb": "Pagkontrol sa Peste", "en": "Pest Control" },
    { "id": "harvest", "fil": "Pag-ani", "ceb": "Pag-ani", "en": "Harvest" },
    { "id": "planting", "fil": "Pagtatanim", "ceb": "Pagtanum", "en": "Planting" },
    { "id": "pruning", "fil": "Pagpuputol", "ceb": "Pagputol", "en": "Pruning" },
    { "id": "soil_prep", "fil": "Paghahanda ng Lupa", "ceb": "Pag-andam sa Yuta", "en": "Soil Preparation" },
    { "id": "other", "fil": "Iba pa", "ceb": "Uban pa", "en": "Other" }
  ]
}
```

---

## 🎨 App Theme Constants (`lib/core/constants/`)

### `app_colors.dart`
```dart
class AppColors {
  // Primary greens
  static const primaryGreen = Color(0xFF2E7D32);
  static const darkGreen = Color(0xFF1B5E20);
  static const lightGreen = Color(0xFFA5D6A7);
  static const backgroundGreen = Color(0xFFE8F5E9);

  // Neutrals
  static const white = Color(0xFFFFFFFF);
  static const offWhite = Color(0xFFF9FBF9);
  static const textDark = Color(0xFF1C1C1E);
  static const textGrey = Color(0xFF6B7280);

  // Semantic
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFDC2626);
  static const success = Color(0xFF16A34A);
  static const info = Color(0xFF2563EB);
}
```

### `app_dimensions.dart`
```dart
class AppDimensions {
  // Button heights
  static const primaryButtonHeight = 72.0;
  static const secondaryButtonHeight = 56.0;
  static const listItemHeight = 72.0;

  // Font sizes
  static const displaySize = 28.0;
  static const headingSize = 24.0;
  static const titleSize = 20.0;
  static const bodySize = 18.0;
  static const captionSize = 16.0;

  // Spacing
  static const screenPadding = 20.0;
  static const cardPadding = 16.0;
  static const itemSpacing = 16.0;
  static const sectionSpacing = 32.0;

  // Border radius
  static const cardRadius = 16.0;
  static const buttonRadius = 14.0;
  static const chipRadius = 24.0;

  // Icons
  static const iconSizeLarge = 48.0;
  static const iconSizeMedium = 32.0;
  static const iconSizeSmall = 24.0;
}
```

---

## 🔧 Code Generation Commands

```bash
# Run after adding/modifying any annotated model or database file
dart run build_runner build --delete-conflicting-outputs

# Watch mode during development
dart run build_runner watch --delete-conflicting-outputs

# Generate localization files (run after editing .arb files)
flutter gen-l10n

# Full clean + regenerate
flutter clean && flutter pub get && dart run build_runner build --delete-conflicting-outputs && flutter gen-l10n
```

---

## 🚀 Release Build Commands

```bash
# Build split APKs per ABI (smaller downloads)
flutter build apk --release --split-per-abi

# Build universal APK
flutter build apk --release

# Build App Bundle for Play Store
flutter build appbundle --release

# Output locations:
# build/app/outputs/flutter-apk/app-arm64-v8a-release.apk  ← primary target
# build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
# build/app/outputs/bundle/release/app-release.aab
```

---

## 🧪 Testing Commands

```bash
# Run all unit tests
flutter test test/unit/

# Run widget tests
flutter test test/widget/

# Run integration tests (requires connected device)
flutter test integration_test/

# Run with coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

---

## 📱 Recommended Test Devices

| Device Type | RAM | Android | Purpose |
|---|---|---|---|
| Samsung Galaxy A03 Core | 2GB | 11 | Primary target (low-end) |
| Realme C11 | 2GB | 10 | Low-end validation |
| Samsung Galaxy A14 | 4GB | 13 | Mid-range validation |
| Android Emulator | 2GB | 11 | CI/CD testing |

---

## 📋 Pre-Deployment Checklist

- [ ] All strings localized in Filipino, Cebuano, English
- [ ] App works in full airplane mode
- [ ] App stable on 2GB RAM emulator (test with memory stress)
- [ ] Camera permission flow tested (first ask, denied, permanently denied)
- [ ] OCR tested on real receipt photos in various lighting
- [ ] PDF export opens in default PDF viewer on target devices
- [ ] Voice assistant responds in Filipino
- [ ] No crashes in 30-minute session on low-end device
- [ ] App size < 100MB (excluding optional SLM model)
- [ ] Proguard rules don't strip required classes
- [ ] FileProvider configured for PDF sharing
- [ ] `flutter analyze` passes with zero errors
- [ ] `flutter test` — all tests passing