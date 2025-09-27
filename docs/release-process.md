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