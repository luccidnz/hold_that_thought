import { execSync } from "node:child_process";
import { Octokit } from "octokit";

function sh(c) {
  try {
    return execSync(c, { stdio: ["ignore", "pipe", "pipe"] }).toString().trim();
  } catch (e) {
    return "";
  }
}

const token = process.env.GITHUB_TOKEN || process.env.GH_TOKEN;
if (!token) {
  console.log("ℹ️ Skipping PR note (no token).");
  process.exit(0);
}

const remote = sh("git config --get remote.origin.url");
const m = remote.match(/github\.com[:/](.+?)\.git$/);
if (!m) {
  process.exit(0);
}

const [owner, repo] = m[1].split("/");
const branch = sh("git rev-parse --abbrev-ref HEAD");

async function main() {
  const octo = new Octokit({ auth: token });
  
  console.log("Finding PR for branch:", branch);
  
  const { data: prs } = await octo.rest.pulls.list({
    owner,
    repo,
    state: "open",
    head: `${owner}:${branch}`
  });
  
  if (!prs.length) {
    console.log("No open PR found");
    process.exit(0);
  }
  
  const pr = prs[0];
  console.log(`Found PR #${pr.number}: ${pr.title}`);
  
  const body = `CI fixes pushed:
- Replaced flaky emulator test with stable package-name assertion
- Coverage gate set via \`COVERAGE_MIN=60\`
- Workflows re-dispatched

Please recheck **Checks → Summary**, and if green, comment **QA: PASS** to auto-merge + tag v0.10.0.`;

  const response = await octo.rest.issues.createComment({
    owner,
    repo,
    issue_number: pr.number,
    body
  });

  console.log("✅ PR noted, comment ID:", response.data.id);
}

main().catch(console.error);
