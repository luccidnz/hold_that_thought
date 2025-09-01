#!/usr/bin/env bash
set -euo pipefail
NUM="$(gh pr view --json number -q .number)"
cat > /tmp/jules.txt <<'MD'
**Jules QA Checklist**
1) Flags OFF: legacy capture/list/share OK  
2) RAG ON: Related sensible, Summarize works, Daily Digest renders & shares  
3) Android: lock-screen recording survives; notification visible; playback OK  
4) E2EE ON: `.enc` in storage; decrypt after restart; wrong passphrase fails  
5) Auth ON: sign-in; anon→account migration; cross-device sync  
6) Post results + short demo (see /docs/demo_phase10.md)
MD
gh pr comment "$NUM" --body-file /tmp/jules.txt
echo "Comment posted to PR #$NUM"
