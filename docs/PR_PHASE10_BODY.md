**Summary**
Phase 10 delivers multi-device **Auth**, **RAG** (Related/Summary/Daily Digest), **Android Foreground Recording**, and **E2EE**, with tests, CI, and docs.

**Security Note**
- `.env` was purged from history and CI now blocks it.
- Previously used tokens must be **revoked/rotated** in GitHub Settings (manual).

**CI artifacts**
- Latest workflow run & artifacts: https://github.com/luccidnz/hold_that_thought/actions?query=branch%3Afeature%2Fphase10-auth-rag-android-e2ee+is%3Asuccess

_See README and prior PR content for full details & acceptance checklist._

**What's in**
- Auth: email/password sign-in, user-namespaced storage/metadata, anon→account migration.
- RAG: Vector index, Related panel, Summarize (bullets/actions/tags/hook), Daily Digest.
- Android: Foreground recording service (A13/14+), persistent notification, lock-screen safe.
- E2EE: Argon2id/PBKDF2, envelope encryption (transcript + audio), badges, passphrase flows.
- Repo/Sync: EncryptedThoughtRepository, EncryptedSyncService, sha256 of ciphertext; no plaintext leaves device when E2EE is on.
- Guardrails: Log redaction, temp-file manager + background cleanup.
- Docs: README, schema/policies SQL, demo script.
- CI: analyze, tests + coverage gate (≥70%), Windows Release build, Android debug APK.

**Feature flags**
- `authEnabled`, `ragEnabled`, `e2eeEnabled`, `telemetryEnabled` (toggle in Settings).

**Screenshots**
_Attach: Related Panel, Daily Digest card, "Encrypted" badge, Android recording notification._

**CI artifacts**
- Latest workflow run & artifacts: https://github.com/luccidnz/hold_that_thought/actions?query=branch%3Afeature%2Fphase10-auth-rag-android-e2ee+is%3Asuccess

**Acceptance checklist**
- [ ] Flags OFF → legacy capture/list/share OK
- [ ] RAG ON → Related sensible; Summarize OK; Daily Digest renders & shares
- [ ] Android → recording survives lock screen; notif visible; playback OK
- [ ] E2EE ON → `.enc` in storage; decrypt after restart; wrong passphrase fails
- [ ] Auth ON → sign-in works; anon→account migration; cross-device sync
- [ ] Tests green; CI artifacts uploaded

**Assumptions / limits**
- pgvector optional (client-side fallback exists)
- E2EE passphrase unrecoverable by design
- Android requires notifications for foreground recording
