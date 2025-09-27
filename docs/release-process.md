# Hold That Thought — Release Process (CI-native)

## Tag types
- **RC tag**: `vX.Y.Z-rcN` → builds APK + Windows ZIP, attaches to GitHub release (no AAB, no Play)
- **Stable tag**: `vX.Y.Z` → builds APK + Windows ZIP + **AAB**; attaches all + SHA256; Play upload runs if Play secrets exist

## One-minute cut
1. Ensure secrets (Android signing + Play JSON + PLAY_PACKAGE_NAME).
2. Tag:
   ```bash
   git tag -a vX.Y.Z -m "Release vX.Y.Z"
   git push origin vX.Y.Z
   ```

CI creates the GitHub release with assets. If Play creds exist, AAB goes to Internal.

## Staged rollout (manual)

Run **Play Promote** workflow:

Inputs: tag=vX.Y.Z, track_to=closed or production, user_fraction=0.1|0.25|0.5|1, release_notes=...

Re-run with higher user_fraction to advance the rollout; use 1 to complete.

## Rollback

Re-run Play Promote with a lower fraction (or keep internal only).

Untagging is not required; you can pause at Closed/0.1 until fixed.

## Where things live

- Artifacts (APK/ZIP/AAB) on the GitHub release
- .sha256 alongside each asset
- Changelog appended to release body
- "What's New" derived from tag changelog (first 500 chars)

## Security & controls
- **Environment-gated Play upload**: workflow uses the `play-internal` environment. Add required reviewers in Settings → Environments → play-internal to enforce 4-eyes before any Play upload.
- **Protected tags**: `v*` tags are protected from accidental deletion/creation by non-admins.
- **Provenance**: CI now attaches SLSA provenance attestations to release files (GitHub Artifact Attestations).
- **Duplicate-run guard**: CI uses concurrency per ref so repeated pushes won't double-run.

## Verification & promotion safety
- **Release verification**: CI downloads the assets and validates SHA256; APK version **must** match the tag.
- **Play environments**:
  - Internal uploads require **play-internal** approval (already configured).
  - Promotions (Closed/Production) require **play-production** approval (set reviewers in *Settings → Environments*).
- **Tag protection**: we protect `v*` tags from deletes/force-updates via Rulesets (if available on plan).