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
  console.log("ℹ️ Set $env:GITHUB_TOKEN first to auto-dispatch.");
  process.exit(0);
}

const remote = sh("git config --get remote.origin.url");
const m = remote.match(/github\.com[:/](.+?)\.git$/);
if (!m) {
  process.exit(0);
}

const [owner, repo] = m[1].split("/");
const ref = sh("git rev-parse --abbrev-ref HEAD");

const octo = new Octokit({ auth: token });

async function main() {
  for (const wf of ["ci.yml", "android-qa-smoke.yml"]) {
    try {
      await octo.rest.actions.createWorkflowDispatch({
        owner,
        repo,
        workflow_id: wf,
        ref
      });
      console.log("🟢 dispatched", wf);
    } catch (e) {
      console.log("⚠️", wf, e.status || "", e.message || "");
    }
  }
}

main().catch(console.error);
