import { execSync } from "node:child_process";
import { Octokit } from "octokit";
function sh(c){ try { return execSync(c,{stdio:["ignore","pipe","pipe"]}).toString().trim(); } catch { return ""; } }
const token = process.env.GITHUB_TOKEN || process.env.GH_TOKEN;
if(!token){ console.log("ℹ️ Set token to post comment."); process.exit(0); }
const remote = sh('git config --get remote.origin.url');
const m = remote.match(/github\.com[:/](.+?)\.git$/);
const [owner, repo] = m[1].split("/");
const branch = sh('git rev-parse --abbrev-ref HEAD');
const octo = new Octokit({ auth: token });
const prs = (await octo.rest.pulls.list({ owner, repo, state:"open", head:`${owner}:${branch}` })).data;
if (!prs.length) { console.log("No open PR for this branch."); process.exit(0); }
const pr = prs[0];
const body = `Heads-up: the encrypted env ZIP is **delivered via external link**, not stored in the repo. You don't need to unzip or install Flutter locally.
Please validate using PR **Checks → Artifacts** (Windows Release, Android Debug APK) and the **Android QA Smoke** job we just dispatched.
If everything matches the checklist, please comment **QA: PASS** to auto-merge & tag v0.10.0.`;
await octo.rest.issues.createComment({ owner, repo, issue_number: pr.number, body });
console.log(`✅ Posted clarification on PR #${pr.number}`);
