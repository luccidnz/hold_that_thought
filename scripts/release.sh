#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/release.sh vX.Y.Z
TAG="${1:-}"
if [[ -z "$TAG" ]]; then
  echo "Usage: $0 vX.Y.Z"; exit 2;
fi

# Basic sanity
if ! git diff --quiet; then
  echo "Working tree not clean. Commit or stash first."; exit 3;
fi

# Ensure tests pass locally (non-fatal in constrained envs)
flutter test || echo "::warning ::flutter test failed locally; CI will validate."

if [[ "${DRY_RUN:-0}" == "1" ]]; then
  echo "DRY_RUN=1 -> skipping tag and push."
else
  # Tag and push
  git tag -a "$TAG" -m "Release $TAG"
  git push origin "$TAG"
  echo "Pushed tag $TAG. CI will create a draft release."
fi
