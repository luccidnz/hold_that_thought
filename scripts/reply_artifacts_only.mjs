import { execSync } from "node:child_process";
import { Octokit } from "octokit";
function sh(c){ try { return execSync(c,{stdio:["ignore","pipe","pipe"]}).toString().trim(); } catch { return ""; } }
const token = process.env.GITHUB_TOKEN || process.env.GH_TOKEN;
if(!token){ console.log("ℹ️ Set a session token to post PR comment:  $env:GITHUB_TOKEN = 'YOUR_FINE_GRAINED_TOKEN'"); process.exit(0); }
const remote = sh('git config --get remote.origin.url');
const m = remote.match(/github\.com[:/](.+?)\.git$/);
if (!m) { console.log("Cannot parse origin."); process.exit(0); }
const [owner, repo] = m[1].split("/");
const branch = sh('git rev-parse --abbrev-ref HEAD');
const octo = new Octokit({ auth: token });

const prs = (await octo.rest.pulls.list({ owner, repo, state:"open", head:`${owner}:${branch}` })).data;
if (!prs.length) { console.log("No open PR for this branch."); process.exit(0); }
const pr = prs[0];

const msg = `
**Update for QA (no install required)**

You don't need Flutter or unzip tools. Please verify using CI artifacts + screenshots:

**Where to click**
1. Open this PR → **Checks** tab → **Summary**.
2. Under **Artifacts**, download:
   - **Windows Release** (desktop EXE build)
   - **Android Debug APK**
   - (If present) **Coverage**, **Logs**, or **Android QA Smoke** results
3. Android foreground recording is validated by the **Android QA Smoke** job we just re-ran.

**Screenshots (in repo)**
- Related panel: \`docs/screenshots/related_panel.png\`
- Daily digest: \`docs/screenshots/daily_digest.png\`
- E2EE badge: \`docs/screenshots/encrypted_badge.png\`
- Android notification: \`docs/screenshots/android_recording_notification.png\`

**What to check**
- Flags **OFF**: capture → list → play → export → delete (see demo notes & logs)
- **RAG**: Related Panel shows ~5 sensible items (no self), Summarize (bullets/actions/tags/hook), Daily Digest (copy/share)
- **Android**: Android QA Smoke job ✅
- **E2EE**: encrypted badge present on new captures; wrong passphrase fails; correct unlock works; uploaded blob ends **.enc**
- **Auth**: anon→account migration; cross-device sync (documented in PR notes & logs)

If all looks good, please comment **"QA: PASS"** on this PR. The bot will auto-merge and tag **v0.10.0**.`;

await octo.rest.issues.createComment({ owner, repo, issue_number: pr.number, body: msg });
console.log(`✅ Posted artifacts-only QA guidance on PR #${pr.number}`);
