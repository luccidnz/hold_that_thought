#!/usr/bin/env bash
set -euo pipefail
VER="v0.10.0"
git checkout main
git pull
git tag -a "$VER" -m "Phase 10 — Auth, RAG, Android Foreground Recording, E2EE"
git push origin "$VER"
if command -v gh >/dev/null 2>&1; then
  gh release create "$VER" -F docs/RELEASE_NOTES_v0.10.0.md -t "Hold That Thought $VER" || true
fi
echo "Tagged and (optionally) created GitHub Release for $VER."
