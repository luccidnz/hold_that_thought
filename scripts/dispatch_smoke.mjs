import { execSync } from "node:child_process";
import { Octokit } from "octokit";
function sh(c){ try { return execSync(c,{stdio:["ignore","pipe","pipe"]}).toString().trim(); } catch { return ""; } }
const token = process.env.GITHUB_TOKEN || process.env.GH_TOKEN;
if(!token){ console.log("ℹ️ Set token:  $env:GITHUB_TOKEN = 'YOUR_FINE_GRAINED_TOKEN'"); process.exit(0); }
const remote = sh('git config --get remote.origin.url');
const m = remote.match(/github\.com[:/](.+?)\.git$/);
const [owner, repo] = m[1].split("/");
const ref = sh('git rev-parse --abbrev-ref HEAD');
const octo = new Octokit({ auth: token });
await octo.rest.actions.createWorkflowDispatch({ owner, repo, workflow_id: "android-qa-smoke.yml", ref });
console.log("🟢 Android QA Smoke dispatched.");
