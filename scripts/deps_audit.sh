#!/usr/bin/env bash
set -euo pipefail

OUT="docs/DEPS_AUDIT.md"
mkdir -p docs

echo "# Dependency Audit" > "$OUT"
echo "" >> "$OUT"
echo "Generated: $(date -u +"%Y-%m-%d %H:%M UTC")" >> "$OUT"
echo "" >> "$OUT"

echo "## Dart/Flutter dependencies" >> "$OUT"
echo "" >> "$OUT"

# Lockfile snapshot
if [[ -f "pubspec.lock" ]]; then
  echo "<details><summary>pubspec.lock snapshot</summary>" >> "$OUT"
  echo "" >> "$OUT"
  echo '```yaml' >> "$OUT"
  sed -n '1,200p' pubspec.lock >> "$OUT"
  echo '```' >> "$OUT"
  echo "</details>" >> "$OUT"
  echo "" >> "$OUT"
fi

# Outdated summary (non-fatal)
{
  echo "### Outdated (summary)"
  echo
  flutter pub outdated --no-dev-dependencies || true
} | tee /dev/stderr | sed 's/\x1b\[[0-9;]*m//g' | sed 's/[[:space:]]\+$//' | awk 'BEGIN{print "```"} {print} END{print "```"}' >> "$OUT"

echo "" >> "$OUT"
echo "## Platform plugins (auto-detected)" >> "$OUT"
echo "" >> "$OUT"
echo '```' >> "$OUT"
grep -R --include="pubspec.yaml" -nE "plugin:|flutter:" . || true >> "$OUT"
echo '```' >> "$OUT"

echo "" >> "$OUT"
echo "_End of report._" >> "$OUT"

echo "Wrote $OUT"
