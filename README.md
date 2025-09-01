# Hold That Thought

Lightweight, offline-first thought capture with instant transcription, tagging, search (keyword + semantic), and optional cloud backup.

## Features
- 🎙️ **Capture** `.m4a` with one tap (Windows + Android)
- ✍️ **Auto-transcribe** with Whisper (OpenAI)
- 🏷️ **Tags** with chips + filters
- 🔎 **Search** keyword (highlighted) or semantic (cosine similarity)
- 🧭 **Sort** newest/oldest/longest/best-match
- 🛠️ **Diagnostics**: ping OpenAI, re-transcribe missing, backfill embeddings
- ☁️ **Optional Cloud Backup** (Supabase Storage + Postgres)
- 📤 **Share** transcript/audio; **Export All** to ZIP (with `manifest.json`)
- 🌓 **Theming**: light/dark + system

## Quickstart (Dev)
```bash
git clone <repo>
cd hold_that_thought
flutter pub get
# Windows
flutter run -d windows
# Android (emulator or device)
flutter run -d android
```

## Environment

Set OPENAI_API_KEY (or enter in Settings).

Hive boxes auto-repair on startup and live in app support dir.

Git LFS configured for audio (.m4a/.wav).

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
