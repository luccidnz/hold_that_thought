# Hold That Thought

Hold That Thought is a cross-platform Flutter application for capturing and organizing
fleeting thoughts with voice or text, including a 10-second pre-roll buffer for speech
before recording starts. It supports cloud sync, transcription, categorization, reminders,
and export features.

![CI](https://github.com/luccidnz/hold_that_thought/workflows/CI/badge.svg)

## Features

- **Voice Recording with Pre-roll**: Captures up to 10 seconds of speech before you hit record
- **Text Thoughts**: Quickly jot down ideas with text
- **Cloud Sync**: Automatically backs up your thoughts to the cloud
- **Transcription**: Converts your voice recordings to text
- **Categorization**: Organize your thoughts with tags and categories
- **Search**: Quickly find thoughts with full-text search
- **Export**: Export your thoughts to various formats
- **Share**: Share your thoughts with others

## Phase 10 Features

- **Multi-Device Authentication**: Sign in with the same account on multiple devices
- **Smart Recall (RAG)**: AI-powered semantic search and thought analysis
- **Android Foreground Recording**: Continue recording even when the app is in the background
- **End-to-End Encryption (E2EE)**: Secure your sensitive thoughts with strong encryption

### Feature Flags

The app uses feature flags to control the availability of certain features:

- **authEnabled**: Enables multi-device sign-in
- **ragEnabled**: Enables semantic search and AI-powered suggestions
- **e2eeEnabled**: Enables end-to-end encryption of your thoughts
- **telemetryEnabled**: Enables anonymous usage data collection

You can toggle these features in the Settings page.

## Multi-Device Authentication (Phase 10)

The multi-device authentication feature supports proper user accounts with:

- Email magic link authentication (default)
- Email + password authentication (optional)
- Device linking across multiple devices
- Per-user namespaced storage in Supabase
- Migration path from anonymous data

### Setting Up User Accounts

1. Navigate to the Settings page
2. Enable the "Multi-Device Sign-In" feature flag
3. Tap on "Manage Account"
4. Sign up with your email and password
5. Your thoughts will now sync across all your devices

### Migration from Anonymous Mode

If you previously used anonymous mode:
1. Sign in to your account
2. Go to Settings > Account
3. Tap "Migrate Anonymous Data"
4. Your data will be moved to your user account

## Smart Recall with RAG (Phase 10)

The RAG (Retrieval Augmented Generation) features provide intelligent thought analysis:

- **Related Thoughts**: See thoughts semantically similar to the current one
- **Daily Digest**: Get a summary of your thoughts from today
- **Summarize**: Generate summaries from multiple selected thoughts
- **Tag Suggestions**: Get AI-suggested tags for your thoughts

This feature uses embedding models to create vector representations of your thoughts, enabling semantic search and AI-powered suggestions.

## End-to-End Encryption (Phase 10)

For maximum privacy, you can enable E2EE to encrypt your data both locally and in the cloud:

- Passphrase-based encryption that only you know
- AES-GCM-256 encryption for all transcripts and audio
- Encrypted data in Supabase storage and database
- Argon2id (or PBKDF2 fallback) for key derivation

**Important**: If you forget your passphrase, your encrypted data cannot be recovered. There is no "back door" or recovery mechanism.

## Android Foreground Service (Phase 10)

The Android app includes a foreground service for reliable background recording:

- Continues recording even when the app is in the background
- Shows a persistent notification with recording duration
- Handles permission requests for microphone and notifications
- Works reliably on Android 13+ devices with lock screen recording

## Getting Started

### Prerequisites

- Flutter SDK
- Dart SDK
- Android Studio or VS Code with Flutter extensions

### Installation

1. Clone the repository
```bash
git clone https://github.com/luccidnz/hold_that_thought.git
```

2. Navigate to the project directory
```bash
cd hold_that_thought
```

3. Install dependencies
```bash
flutter pub get
```

4. Run the app
```bash
flutter run
```

## Architecture

Hold That Thought uses a clean architecture approach with:

- **Models**: Data structures representing core concepts (Thought, Category, etc.)
- **Services**: Business logic and external integrations
- **Repositories**: Data access and persistence
- **State Management**: Using Flutter Riverpod

## Troubleshooting

- **Whisper 401/Quota**: Confirm `OPENAI_API_KEY` and "Ping OpenAI" in Settings
- **Supabase 401/403**: Check RLS, bucket is `thoughts`, and anonymous session exists
- **Sync stuck**: Ensure network is up; queue backoff is exponential; see Settings diagnostics
- **File paths on Windows**: Use app docs dir; "Open file location" from item menu
- **Authentication issues**: Check email for magic link, ensure your email address is correct
- **E2EE recovery**: There is no way to recover your data if you forget your passphrase

## Contributing

Please see CONTRIBUTING.md for guidelines on contributing to the project.

## Security

Please see SECURITY.md for details on our security practices and E2EE implementation.

## License

MIT

Set OPENAI_API_KEY (or enter in Settings).

Hive boxes auto-repair on startup and live in app support dir.

Git LFS configured for audio (.m4a/.wav).

## Feature Flags

The app uses feature flags to enable/disable optional features. These can be configured in:

- `.env` file (copy from `.env.example`), or
- App Settings UI

Available flags:
- `FEATURE_AUTH_ENABLED` - Enable multi-device authentication
- `FEATURE_RAG_ENABLED` - Enable smart recall features
- `FEATURE_E2EE_ENABLED` - Enable end-to-end encryption
- `FEATURE_TELEMETRY_ENABLED` - Enable optional telemetry

## Cloud Backup (Optional – Supabase)
### Setup

1. Create a Supabase project.
2. Enable Anonymous Sign-In.
3. Create private Storage bucket: `thoughts`.
4. Create table: `thoughts_meta` (see `/docs/schema.sql`).
5. Enable RLS and apply policies from `/docs/policies.sql`.

### App Config

Add `SUPABASE_URL` and `SUPABASE_ANON_KEY` in:

- `.env` (git-ignored, copy from `.env.example`), or
- App Settings (masked inputs).

When using your own Supabase project, replace `<your-project-ref>.supabase.co` with your actual project reference.

### Using Cloud Backup

- Toggle “Enable Cloud Backup (Supabase)” in Settings.
- App signs in anonymously and uploads when online; offline uploads queue.
- Per-item cloud badge shows: synced / pending / failed.
- “Backup Now” enqueues all unsynced.
- “Delete in cloud too” is optional on delete.

We deliberately do not upload embeddings in Phase 9 (size/cost). Everything remains fully usable offline.

## Export

- Per-item: share transcript (text) or audio (.m4a).
- Bulk Export (Settings): creates ZIP with:
  ```
  thoughts/{createdAt}_{title}/audio.m4a
  thoughts/{createdAt}_{title}/transcript.txt
  manifest.json
  ```

## Build
```bash
flutter analyze
flutter test
flutter build windows
flutter build apk     # or run on device
```

## Project Layout
```
lib/
  models/thought.dart
  pages/{capture_page,list_page,settings_page}.dart
  services/
    hive_boot.dart
    transcription_service.dart
    embedding_service.dart
    open_file_helper.dart
    repository/thought_repository.dart
    sync/
      sync_provider.dart
      supabase_sync_provider.dart
      sync_service.dart
      fake/fake_sync_provider.dart
  state/
    providers.dart
    repository_providers.dart
    sync_events.dart
  utils/{highlight,cosine}.dart
  app.dart
```

## Troubleshooting

- **Whisper 401/Quota**: confirm `OPENAI_API_KEY` and “Ping OpenAI” in Settings.
- **Supabase 401/403**: check RLS, bucket is `thoughts`, and anonymous session exists.
- **Sync stuck**: ensure network is up; queue backoff is exponential; see Settings diagnostics.
- **File paths on Windows**: use app docs dir; “Open file location” from item menu.

## Roadmap

P10: cross-device sign-in, richer semantic recall (RAG), mobile polish.

© 2025 Hold That Thought
