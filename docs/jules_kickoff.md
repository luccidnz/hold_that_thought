**Jules — Phase 10 QA (start now)**
1) Flags OFF: capture → list → play → export → delete works.
2) **RAG ON**: Related Panel (no self, 5 sensible); **Summarize** (bullets/actions/tags/hook); **Daily Digest** (copy/share).
3) **Android**: start record → lock 30–60s → stop; persistent notification; file plays; duration > 0.
4) **E2EE ON**: set passphrase; capture → **Encrypted** badge; Supabase object ends `.enc`; lock/unlock works; wrong passphrase fails.
5) **Auth ON**: sign in on two devices; run **anon → account migration**; cross-device sync.
6) Post results + short demo per `/docs/demo_phase10.md`.

_Note:_ Repo history was rewritten to scrub secrets. If your local branch diverges, hard reset with:

```
git fetch --all
git reset --hard origin/feature/phase10-auth-rag-android-e2ee
git clean -fdx
```
