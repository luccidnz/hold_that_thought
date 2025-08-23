#!/usr/bin/env bash
set -euo pipefail

OUT="docs/TODO_AUDIT.md"
DATE="$(date -u +'%Y-%m-%d %H:%M:%SZ')"

# Globs + excludes
PATTERN='(TODO|FIXME|HACK|XXX)'

echo "# TODO Audit" > "$OUT"
echo "" >> "$OUT"
echo "_Generated: ${DATE} (UTC)_" >> "$OUT"
echo "" >> "$OUT"

# Grep lines
if ! command -v grep >/dev/null 2>&1; then
  echo "❌ grep not found"
  exit 2
fi

matches=$(grep -RInE "$PATTERN" . | grep -vE '(\.git|/build/|\.dart_tool/|/coverage/|/ios/|/android/|/docs/|/scripts/)' || true)

if [[ -z "$matches" ]]; then
  echo "No TODO/FIXME/HACK/XXX found. 🎉" >> "$OUT"
  echo "✅ TODO audit complete (no items)."
  exit 0
fi

echo "| File | Line | Tag | Snippet |" >> "$OUT"
echo "|---|---:|---|---|" >> "$OUT"

# Convert "path:line:content"
while IFS= read -r line; do
  path="${line%%:*}"
  rest="${line#*:}"
  lineno="${rest%%:*}"
  content="${rest#*:}"

  # Extract tag
  tag=$(echo "$content" | grep -oE '(TODO|FIXME|HACK|XXX)' | head -1 || echo "TODO")
  # Escape pipes
  snippet=$(echo "$content" | sed 's/|/\\|/g' | sed 's/[[:space:]]\+/ /g' | cut -c1-160)

  echo "| \`$path\` | $lineno | $tag | $snippet |" >> "$OUT"
done <<< "$matches"

echo "✅ TODO audit written to $OUT"
