# QA Environment Setup (Local)

1. Copy `.env.example` → `.env`.
2. Fill the values you received via a **one-time secret link**:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
   - `OPENAI_API_KEY`
3. Install deps: `flutter pub get`
4. Run desktop app: `flutter run -d windows`
5. Use Settings → Feature Flags to run the QA checklist.

> Security: Do not paste keys into PRs or chat. Delete `.env` after QA if using a shared machine.
