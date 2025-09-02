import { execSync } from "node:child_process";
import { Octokit } from "octokit";
import { existsSync } from "node:fs";

function sh(c){ try { return execSync(c,{stdio:["ignore","pipe","pipe"]}).toString().trim(); } catch { return ""; } }

const token = process.env.GITHUB_TOKEN || process.env.GH_TOKEN;
if (!token) {
  console.log("ℹ️ No GITHUB_TOKEN set. In this terminal, run:\n\n  PowerShell:\n  $env:GITHUB_TOKEN = 'YOUR_FINE_GRAINED_TOKEN'\n");
  process.exit(0);
}

const remote = sh('git config --get remote.origin.url');
const m = remote.match(/github\.com[:/](.+?)\.git$/);
if (!m) { console.error("❌ Cannot parse owner/repo from origin."); process.exit(1); }
const [owner, repo] = m[1].split("/");
const branch = sh('git rev-parse --abbrev-ref HEAD') || "feature/phase10-auth-rag-android-e2ee";
const prNumberEnv = process.env.PR_NUMBER ? Number(process.env.PR_NUMBER) : null;
const jules = process.env.JULES_GH || ""; // set this env var to auto-assign reviewer

const octo = new Octokit({ auth: token });

async function findPR() {
  if (prNumberEnv) {
    try { const { data } = await octo.rest.pulls.get({ owner, repo, pull_number: prNumberEnv }); return data; } catch {}
  }
  const { data: prs } = await octo.rest.pulls.list({ owner, repo, state: "open", head: `${owner}:${branch}` });
  if (prs.length) return prs[0];
  const { data: all } = await octo.rest.pulls.list({ owner, repo, state: "open", base: "main" });
  return all.find(p => p.head.ref === branch);
}

async function latestArtifactsUrl() {
  const { data: runs } = await octo.rest.actions.listWorkflowRunsForRepo({ owner, repo, per_page: 15, branch });
  const run = runs.workflow_runs?.find(r => (r.conclusion === "success") || (r.status === "completed" && r.conclusion));
  return run ? `${run.html_url}#artifacts` : `https://github.com/${owner}/${repo}/actions?query=branch%3A${encodeURIComponent(branch)}`;
}

(async () => {
  const pr = await findPR();
  if (!pr) { console.error(`❌ No open PR found for branch ${branch}.`); process.exit(0); }
  const artifactsUrl = await latestArtifactsUrl();

  const body =
`**Summary**
Phase 10 delivers multi-device **Auth**, **RAG** (Related/Summary/Daily Digest), **Android Foreground Recording**, and **E2EE**, with tests, CI, and docs.

**Security Note**
- \`.env\` was purged and CI now blocks it.
- Rotate any previously used tokens (GitHub + Supabase). See \`docs/SECURITY_ROTATION.md\`.

**CI artifacts**
- Latest successful run & artifacts: ${artifactsUrl}

_Acceptance checklist & demos are in the repo docs and PR comments._`;

  await octo.rest.pulls.update({ owner, repo, pull_number: pr.number, title: "Phase 10 — Auth, RAG, Android Foreground Recording, E2EE", body });

  const julesMsg =
`**Jules — Phase 10 QA (start now)**
1) Flags OFF: capture → list → play → export → delete works.
2) **RAG ON**: Related Panel (no self, 5 sensible); **Summarize** (bullets/actions/tags/hook); **Daily Digest** (copy/share).
3) **Android**: start record → lock 30–60s → stop; persistent notification; file plays; duration > 0.
4) **E2EE ON**: set passphrase; capture → **Encrypted** badge; Supabase blob ends \`.enc\`; lock/unlock works; wrong passphrase fails.
5) **Auth ON**: sign in on two devices; run **anon → account migration**; cross-device sync.
6) Post a short demo per \`/docs/demo_phase10.md\`.

**Artifacts**: ${artifactsUrl}`;

  await octo.rest.issues.createComment({ owner, repo, issue_number: pr.number, body: julesMsg }).catch(()=>{});

  const secMsg =
`**Security**
- Repo history was rewritten to scrub secrets. If local clone diverges:
\`\`\`
git fetch --all
git reset --hard origin/${branch}
git clean -fdx
\`\`\`
- Rotate Supabase anon/service keys in Dashboard; update local \`.env\`.`;
  await octo.rest.issues.createComment({ owner, repo, issue_number: pr.number, body: secMsg }).catch(()=>{});

  if (jules) {
    try {
      await octo.rest.pulls.requestReviewers({ owner, repo, pull_number: pr.number, reviewers: [jules] });
      console.log(`✅ Assigned reviewer: ${jules}`);
    } catch (e) {
      console.log("⚠️ Could not assign reviewer (permissions/username issue).");
    }
  } else {
    console.log("ℹ️ Set env JULES_GH to auto-assign Jules (e.g., 'SomeUser').");
  }

  // Link screenshots if present
  const shots = [
    "docs/screenshots/related_panel.png",
    "docs/screenshots/daily_digest.png",
    "docs/screenshots/encrypted_badge.png",
    "docs/screenshots/android_recording_notification.png"
  ].filter(p => existsSync(p));
  if (shots.length) {
    await octo.rest.issues.createComment({ owner, repo, issue_number: pr.number, body: `**Screenshots**\n${shots.map(s=>`- ${s}`).join("\n")}` }).catch(()=>{});
  } else {
    console.log("ℹ️ No screenshots detected in docs/screenshots yet; comment skipped.");
  }

  console.log(`✅ PR #${pr.number} updated. Artifacts: ${artifactsUrl}`);
})();
