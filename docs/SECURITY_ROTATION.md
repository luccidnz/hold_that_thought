# Key Rotation Guide (Supabase & GitHub)

## Supabase
1) Dashboard  Project Settings  API  **Rotate anon key** and **service role key**.
2) Update your local `.env` with new values. Do NOT commit `.env`.
3) If GitHub Actions use these keys, store them as **Repo Secrets**, not in the repo.
4) Verify app works with new keys; CI should not require them for tests.

## GitHub Token
- Revoke any previously shared PATs in Settings  Developer settings  Personal access tokens.

## Developers after history rewrite


git fetch --all
git reset --hard origin/$(git rev-parse --abbrev-ref HEAD)
git clean -fdx

