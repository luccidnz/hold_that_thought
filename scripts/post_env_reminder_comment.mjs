import { execSync } from "node:child_process";
import { Octokit } from "octokit";
function sh(c){ try { return execSync(c,{stdio:["ignore","pipe","pipe"]}).toString().trim(); } catch { return ""; } }
const token = process.env.GITHUB_TOKEN || process.env.GH_TOKEN;
if(!token){ console.log("ℹ️ Set session token to post comment (PowerShell):  $env:GITHUB_TOKEN = 'YOUR_FINE_GRAINED_TOKEN'"); process.exit(0); }
const remote = sh('git config --get remote.origin.url');
const m = remote.match(/github\.com[:/](.+?)\.git$/);
const [owner, repo] = m[1].split("/");
const branch = sh('git rev-parse --abbrev-ref HEAD');
const octo = new Octokit({ auth: token });
const prs = (await octo.rest.pulls.list({ owner, repo, state:"open", head:`${owner}:${branch}` })).data;
if (!prs.length) { console.log("No open PR found for this branch."); process.exit(0); }
const pr = prs[0];
const body = `**QA env delivery (no secrets)**
I have sent an encrypted file / one-time link containing:
- \`SUPABASE_URL\`
- \`SUPABASE_ANON_KEY\`
- \`OPENAI_API_KEY\`

After placing \`.env\`:
\`\`\`
flutter pub get
pwsh scripts/validate_env.ps1
flutter run -d windows
\`\`\`
Android foreground smoke runs in CI; no local device needed.`;
await octo.rest.issues.createComment({ owner, repo, issue_number: pr.number, body });
console.log(`✅ Posted non-secret env reminder on PR #${pr.number}`);
