// scripts/protect_main.mjs
import { execSync } from "node:child_process";
import { Octokit } from "octokit";

const token = process.env.GITHUB_TOKEN || process.env.GH_TOKEN;
if (!token) { console.error("No GITHUB_TOKEN set."); process.exit(0); }

function sh(cmd){ try { return execSync(cmd, {stdio:["ignore","pipe","pipe"]}).toString().trim(); } catch { return ""; } }
const remote = sh('git config --get remote.origin.url');
const m = remote.match(/github\.com[:/](.+?)\.git$/);
if (!m) { console.error("Cannot parse owner/repo."); process.exit(1); }
const [owner, repo] = m[1].split("/");

const octo = new Octokit({ auth: token });

try {
  await octo.request("PUT /repos/{owner}/{repo}/branches/{branch}/protection", {
    owner, repo, branch: "main",
    required_status_checks: { strict: true, contexts: ["CI","Secret Scan"] },
    enforce_admins: true,
    required_pull_request_reviews: { required_approving_review_count: 1 },
    restrictions: null
  });
  console.log("✅ Branch protection applied on main.");
} catch (e) {
  console.log("⚠️ Could not apply branch protection (missing admin perms?). Do it in GitHub → Settings → Branches.");
}
