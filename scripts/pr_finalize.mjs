// scripts/pr_finalize.mjs
import { execSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { Octokit } from "octokit";

function sh(cmd) {
  try { return execSync(cmd, { stdio: ["ignore","pipe","pipe"] }).toString().trim(); }
  catch (e) { return ""; }
}

const token = process.env.GITHUB_TOKEN || process.env.GH_TOKEN;
if (!token) {
  console.error("❌ No GITHUB_TOKEN in env. Set it for this terminal session (do NOT commit it).");
  console.error("PowerShell:  $env:GITHUB_TOKEN = 'YOUR_FINE_GRAINED_TOKEN'");
  process.exit(0);
}

const remote = sh('git config --get remote.origin.url');
const m = remote.match(/github\.com[:/](.+?)\.git$/);
if (!m) { console.error("❌ Cannot parse owner/repo from origin."); process.exit(1); }
const [owner, repo] = m[1].split("/");
const head = sh('git rev-parse --abbrev-ref HEAD');
const base = "main";

const octo = new Octokit({ auth: token });

// Helpers
async function findBranchPR() {
  const { data: prs } = await octo.rest.pulls.list({ owner, repo, state: "open", head: `${owner}:${head}` });
  if (prs.length) return prs[0];
  // Try any PR targeting main with same head branch
  const { data: all } = await octo.rest.pulls.list({ owner, repo, state: "open", base });
  return all.find(p => p.head.ref === head);
}

async function latestRunUrl() {
  // Best effort link to the latest workflow run on this branch
  const { data: runs } = await octo.rest.actions.listWorkflowRunsForRepo({ owner, repo, per_page: 10, branch: head });
  const run = runs.workflow_runs?.find(r => ["success","completed"].includes(r.conclusion || r.status));
  return run ? run.html_url + "#artifacts" : `https://github.com/${owner}/${repo}/actions?query=branch%3A${encodeURIComponent(head)}`;
}

function fileExists(rel) { return fs.existsSync(path.join(process.cwd(), rel)); }

// Main
const pr = await findBranchPR();
if (!pr) {
  console.error(`❌ No open PR found for ${owner}:${head}. Create one first.`);
  process.exit(0);
}

const artifactsUrl = await latestRunUrl();

// Build body (merge existing docs/PR_PHASE10_BODY.md if present)
let body = `**Summary**
Phase 10 delivers multi-device **Auth**, **RAG** (Related/Summary/Daily Digest), **Android Foreground Recording**, and **E2EE**, with tests, CI, and docs.

**Security Note**
- \`.env\` was purged from history and CI now blocks it.
- Rotate any previously used tokens in GitHub & Supabase (manual).

**CI artifacts**
- Latest successful run & artifacts: ${artifactsUrl}

_See README and earlier PR content for full details & acceptance checklist._`;

if (fileExists("docs/PR_PHASE10_BODY.md")) {
  try {
    const extra = fs.readFileSync("docs/PR_PHASE10_BODY.md","utf8");
    body = extra.includes("CI artifacts") ? extra : extra + `\n\n**CI artifacts**\n- ${artifactsUrl}\n`;
  } catch {}
}

// Update PR title/body
await octo.rest.pulls.update({ owner, repo, pull_number: pr.number, title: "Phase 10 — Auth, RAG, Android Foreground Recording, E2EE", body });

// Comments: Jules checklist + security advisory
const jules = `**Jules — Phase 10 QA (start now)**
1) Flags OFF: capture → list → play → export → delete works.
2) **RAG ON**: Related Panel (no self, 5 sensible); **Summarize** (bullets/actions/tags/hook); **Daily Digest** (copy/share).
3) **Android**: start record → lock 30–60s → stop; persistent notification; file plays; duration > 0.
4) **E2EE ON**: set passphrase; capture → **Encrypted** badge; Supabase object ends \`.enc\`; lock/unlock works; wrong passphrase fails.
5) **Auth ON**: sign in on two devices; run **anon → account migration**; cross-device sync.
6) Post results + short demo per \`/docs/demo_phase10.md\`.`;

const sec = `**Security**
- Repo history rewritten to scrub secrets. If your local branch diverges:
\`\`\`
git fetch --all
git reset --hard origin/${head}
git clean -fdx
\`\`\`
- Rotate Supabase anon/service keys in the Dashboard and update local \`.env\` only.`;

await octo.rest.issues.createComment({ owner, repo, issue_number: pr.number, body: jules }).catch(()=>{});
await octo.rest.issues.createComment({ owner, repo, issue_number: pr.number, body: sec }).catch(()=>{});

// Screenshot links if files exist
const shots = [
  "docs/screenshots/related_panel.png",
  "docs/screenshots/daily_digest.png",
  "docs/screenshots/encrypted_badge.png",
  "docs/screenshots/android_recording_notification.png"
].filter(fileExists);

if (shots.length) {
  await octo.rest.issues.createComment({
    owner, repo, issue_number: pr.number,
    body: `**Screenshots**\n${shots.map(s=>`- ${s}`).join("\n")}`
  }).catch(()=>{});
} else {
  console.log("ℹ️ No screenshots detected in docs/screenshots yet; skipping screenshot comment.");
}

console.log(`✅ Updated PR #${pr.number}. Artifacts: ${artifactsUrl}`);
