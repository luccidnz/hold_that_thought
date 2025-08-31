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
   # Hold That Thought

   Hold That Thought is a compact voice-note app that records short audio thoughts, transcribes them using OpenAI's Whisper API, stores audio and transcripts locally in a Hive database, and enables both keyword and semantic searching over your notes.

   This README documents the Phase 8 features and how to get the project running locally.

   ## What it does

   - Capture audio voice-notes and save the recorded `.m4a` files in the app documents directory.
   - Automatic transcription using OpenAI's Whisper API.
   - Generate text embeddings (OpenAI `text-embedding-3-small`) for semantic search in a non-blocking/background manner.
   - Store audio metadata, transcripts, embeddings, tags, and app state in a local Hive database.
   - Provide keyword and semantic search modes with highlighted results and multiple sort options.

   ## Key Features (Phase 8)

   - Recording audio and storing `.m4a` files in the platform documents directory.
   - Automatic transcription via OpenAI Whisper (uses the OpenAI API key; see Configuration).
   - Non-blocking background embedding generation for semantic search using `text-embedding-3-small`.
   - Keyword and semantic search modes with in-result highlighting.
   - Multiple result sorting options: Newest, Oldest, Longest, and Best match (semantic relevance).
   - Tagging thoughts and filtering by tag(s).
   - Inline editing of titles and transcripts.
   - Multi-select operations: delete, copy transcript, copy file path, open file location, export transcript to `.txt`.
   - Settings / Diagnostics page with:
      - Masked OpenAI API key display
      - Ping OpenAI connectivity check
      - Re-transcribe All (re-send audio files to Whisper)
      - Backfill Embeddings (recompute embeddings for existing transcripts)

   ## Getting started

   1. Clone the repository:

       git clone https://github.com/luccidnz/hold_that_thought.git

   2. Open the project in VS Code with the repository root.

   3. Install dependencies:

       flutter pub get

   4. Ensure you have Flutter set up on your machine. (On Windows, install Flutter SDK and the Windows desktop prerequisites.)

   5. Run the app:

       flutter run -d windows

       or, if you have an Android emulator or device available:

       flutter run -d android

       Note: this repository does not automatically start an emulator; you must launch an emulator or connect a device before running on Android.

   ## Configuration

   - OpenAI API key

      The app reads the OpenAI key from the `OPENAI_API_KEY` environment variable at runtime. On Windows PowerShell you can set it for the current session like:

      $env:OPENAI_API_KEY = "sk-..."

      For CI or permanent environment configuration, add the variable to your system/user environment variables or pass it into the app environment when running.

   - Git LFS

      `.m4a` audio files are tracked with Git LFS in this project to avoid committing large audio blobs into the repository.

   - Android permissions

      For Android builds, ensure the following permissions are present in `android/app/src/main/AndroidManifest.xml` (or equivalent) so recording and network access work properly:

      - INTERNET
      - RECORD_AUDIO

      Example (Android manifest entries):

      <uses-permission android:name="android.permission.INTERNET" />
      <uses-permission android:name="android.permission.RECORD_AUDIO" />

   ## Usage notes & costs

   - Whisper usage: the app currently uses OpenAI Whisper (via the OpenAI API) for transcription. Whisper billing is per audio minute; as of this README a typical reference cost is around $0.006 per minute — please check OpenAI's pricing page for current rates.
   - Transcripts, embeddings, and metadata are stored locally in a Hive database. Audio files remain on-device (under the app documents directory) until you delete them via the app.

   ## Roadmap / TODO

   - Sharing notes (export/share to other apps or services).
   - Backup and restore (cloud or file-based export/import of Hive data and audio files).
   - Desktop-specific integrations (native notifications, system-tray quick capture).
   - Improved UX for long-form audio and batch processing of embeddings/transcripts.

   ## Where to look in the code

   - Main entry: `lib/main.dart`
   - App wiring & providers: `lib/state/providers.dart`
   - Audio engine: `lib/audio/audio_engine.dart`
   - Transcription service: `lib/services/transcription_service.dart`
   - Embedding & semantic search: `lib/services/embedding_service.dart` and `lib/utils/cosine.dart`
   - Hive bootstrap and models: `lib/services/hive_boot.dart` and `lib/models/thought.dart`

   ## Contributing

   Contributions and bug reports are welcome. Please open issues or PRs on the GitHub repository.

   ---

   If you want any edits to this README (formatting, additional troubleshooting steps, or screenshots), tell me what you'd like and I will update it.