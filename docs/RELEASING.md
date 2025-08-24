# Releasing

1. Choose a semver tag: `vX.Y.Z`.
2. Ensure main is green.
3. Run `scripts/release.sh vX.Y.Z`.
4. Wait for the `release` workflow to create a **draft** on GitHub.
5. Edit notes if needed, then publish the draft.
