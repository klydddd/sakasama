# Sakasama

Sakasama is a zero-friction, offline-first PhilGAP compliance companion application designed specifically for Filipino smallholder farmers. It assists farmers in managing their farm records, ensuring quality compliance, and obtaining guidance through an integrated AI assistant.

## Features

- **Offline-First Data Architecture**: Data is stored locally on the device using SQLite, ensuring uninterrupted usage without an internet connection. Records automatically synchronize to the Supabase cloud backend once connectivity is restored.
- **Farm Profile Management**: Establish and maintain comprehensive farm details and administrative preferences.
- **Digital Farm Journal**: Quickly and efficiently log daily agricultural activities, reducing administrative friction.
- **Resource and Harvest Tracking**: Systematically track expenses, agricultural inputs, and harvest yields.
- **PhilGAP Compliance Integration**: Access, manage, and complete checklists and forms strictly required for PhilGAP certification.
- **Document AI Processing**: Utilize device cameras to scan receipts, labels, and physical logs. The system uses a hybrid approach of on-device heuristics and cloud-assisted AI (when online) to auto-extract structured data.
- **Audit-Ready Data Export**: Generate and export structured records for agricultural auditing and institutional assessment.
- **Conversational AI Assistant**: Query "Saka," the smart virtual assistant, for regulatory advice on agriculture and PhilGAP procedures. It uses Retrieval-Augmented Generation (RAG) to provide contextual answers based on localized regulatory manuals.
- **Voice Accessibility**: Speak directly to the AI assistant in Filipino or local dialects, utilizing native Speech-to-Text APIs, making compliance accessible directly in the field.

## Technology Stack

- **Framework**: Flutter (Dart)
- **Local Persistence**: Drift (SQLite)
- **Cloud Infrastructure**: Supabase
- **Artificial Intelligence**: Google Generative AI (Gemini)
- **Voice Services**: speech_to_text, flutter_tts
- **Routing**: go_router
- **State Management**: flutter_riverpod