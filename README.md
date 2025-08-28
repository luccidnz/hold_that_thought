# Hold That Thought

Hold That Thought is a Flutter application designed to help users capture and organise
their fleeting ideas. With a single tap, it records voice input, prepends up to
10 seconds of pre‑roll audio, transcribes the speech to text and automatically
categorises the thought. Users can also type their thoughts directly. The app
supports a Free tier for local storage and a Pro subscription unlocking
cloud synchronisation, unlimited history, extended transcription, custom
categories, background catching and more.

## Features

* **One‑tap capture** – record voice or type a thought instantly.
* **10‑second pre‑roll** – capture speech up to 10 seconds before tapping.
* **Automatic transcription** – Google STT turns audio into text.
* **Thought categorisation** – AI assigns categories or user‑defined labels.
* **Free vs Pro tiers** – choose between local‑only storage and full cloud sync
  with advanced features.
* **Reminders & exports** – set reminders from temporal phrases and export
  thoughts in plain text or markdown.

## MVP Features (Phase 8)

* **Offline-first thought capture**: Create, list, and view thoughts even when offline.
* **Local Storage**: All thoughts are stored locally on your device using Hive for fast access.
* **Deep Linking**:
  * Open the app to a new note with `/new`.
  * Open a specific thought with `/t/<id>`.
* **Unit Tested**: Core logic is covered by unit tests.

## Getting Started

1. **Clone the repository** and run `flutter pub get` to install dependencies.
2. **Configure Firebase** by running `flutterfire configure` and selecting the
   appropriate project. This will generate `lib/firebase_options.dart`.
3. **Enable Google Cloud APIs** for Speech‑to‑Text v2 and Vertex AI in the same
   project.
4. **Deploy Cloud Functions** from the `functions/` directory (`firebase deploy --only functions`).
5. **Run the app** on web for quick iteration:

   ```sh
   flutter run -d chrome --web-renderer canvaskit
   ```

6. **Build an Android APK** without the Android NDK:

   ```sh
   flutter build apk --release
   ```

## Directory Structure

```
hold_that_thought/
├── android/                # Android project (created manually)
├── ios/                    # iOS project (created manually)
├── web/                    # Web assets (index.html, manifest, icons)
├── lib/
│   ├── main.dart           # Entry point with router and state providers
│   └── audio/
│       └── audio_engine.dart # Dart‑only ring buffer and WAV writer
├── functions/              # Cloud Functions (transcription, categorisation)
├── scripts/
│   └── cleanup_ci.sh       # Script to clean caches for low‑disk CI
├── .github/
│   └── workflows/
│       └── build.yml       # CI workflow building web and Android APK
├── pubspec.yaml            # Dependencies and project metadata
├── analysis_options.yaml   # Static analysis configuration
└── README.md               # This file
```

## Low‑Disk CI

The `scripts/cleanup_ci.sh` script removes Gradle caches, Flutter build directories
and other temporary files. It is invoked in the CI workflow to free up disk
space. See `.github/workflows/build.yml` for details.

## Licence

This project is provided for demonstration purposes under the MIT licence.