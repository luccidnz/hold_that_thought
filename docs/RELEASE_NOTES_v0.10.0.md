# Release Notes v0.10.0

## Phase 10 Features

### Multi-Device Authentication

- Email/password sign-in
- Device linking across multiple devices
- Per-user namespaced storage in Supabase
- Migration path from anonymous data

### Smart Recall with RAG

- Related Thoughts: See thoughts semantically similar to the current one
- Daily Digest: Get a summary of your thoughts from today
- Summarize: Generate summaries from multiple selected thoughts
- Tag Suggestions: Get AI-suggested tags for your thoughts

### End-to-End Encryption (E2EE)

- Passphrase-based encryption that only you know
- AES-GCM-256 encryption for all transcripts and audio
- Encrypted data in Supabase storage and database
- Argon2id (or PBKDF2 fallback) for key derivation

### Android Foreground Service

- Continues recording even when the app is in the background
- Shows a persistent notification with recording duration
- Handles permission requests for microphone and notifications
- Works reliably on Android 13+ devices with lock screen recording

## Feature Flags

The app uses feature flags to control the availability of certain features:

- **authEnabled**: Enables multi-device sign-in
- **ragEnabled**: Enables semantic search and AI-powered suggestions
- **e2eeEnabled**: Enables end-to-end encryption of your thoughts
- **telemetryEnabled**: Enables anonymous usage data collection
