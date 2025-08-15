#!/bin/bash
# Clean up caches and temporary build artefacts to save disk space.

set -e

# Remove Gradle and Flutter caches
rm -rf "$HOME/.gradle/caches" || true
rm -rf "$HOME/.pub-cache" || true
rm -rf "$HOME/.android" || true

# Clean Flutter build outputs
find . -name "build" -type d -prune -exec rm -rf {} +

echo "CI cleanup completed."