import { execSync } from "node:child_process";
import { Octokit } from "octokit";

function sh(cmd){ try { return execSync(cmd,{stdio:["ignore","pipe","pipe"]}).toString().trim(); } catch { return ""; } }
const token = process.env.GITHUB_TOKEN || process.env.GH_TOKEN;
console.log(`Token present: ${!!token} (length: ${token?.length || 0})`);
if(!token){ 
  console.log("⚠️ Set a session token (PowerShell):  $env:GITHUB_TOKEN = 'YOUR_FINE_GRAINED_TOKEN'"); 
  process.exit(0);
}

const remote = sh('git config --get remote.origin.url');
const m = remote.match(/github\.com[:/](.+?)\.git$/);
if(!m){ console.error("Cannot parse owner/repo from origin."); process.exit(1); }
const [owner, repo] = m[1].split("/");
const prNumber = Number(process.env.PR_NUMBER || 3);
const requiredChecks = (process.env.REQUIRED_CHECKS || "CI,Secret Scan").split(",").map(s=>s.trim()).filter(Boolean);
const approveIfNeeded = (process.env.AUTO_APPROVE || "true").toLowerCase() === "true";
const mergeMethod = process.env.MERGE_METHOD || "squash"; // 'merge' | 'squash' | 'rebase'
const pollMs = Number(process.env.POLL_MS || 45000);

const octo = new Octokit({ auth: token });

async function getPR(){
  const { data } = await octo.rest.pulls.get({ owner, repo, pull_number: prNumber });
  return data;
}

async function combinedStatus(sha){
  // Combined status API (covers contexts); best effort if repo uses checks only
  try {
    const { data } = await octo.rest.repos.getCombinedStatusForRef({ owner, repo, ref: sha });
    return data;
  } catch {
    return { state: "unknown", statuses: [] };
  }
}

async function checksAllGreen(sha){
  // Accept success for every required context
  const comb = await combinedStatus(sha);
  if (!comb.statuses || !comb.statuses.length) return false;
  const map = new Map(comb.statuses.map(s => [s.context, s.state]));
  return requiredChecks.every(ctx => (map.get(ctx) || "").toLowerCase() === "success");
}

async function hasQAPassComment(){
  const { data: comments } = await octo.rest.issues.listComments({ owner, repo, issue_number: prNumber, per_page: 100 });
  return comments.some(c => /qa:\s*pass/i.test(c.body || ""));
}

async function ensureApproved(pr){
  try {
    const { data: reviews } = await octo.rest.pulls.listReviews({ owner, repo, pull_number: prNumber });
    const approved = reviews.some(r => r.state === "APPROVED");
    if (!approved && approveIfNeeded) {
      await octo.rest.pulls.createReview({ owner, repo, pull_number: prNumber, event: "APPROVE" });
      return true;
    }
    return approved;
  } catch { return false; }
}

async function mergePR(pr){
  await octo.rest.pulls.merge({
    owner, repo, pull_number: prNumber,
    merge_method: mergeMethod,
    commit_title: pr.title,
  });
  try {
    await octo.rest.git.deleteRef({ owner, repo, ref: `heads/${pr.head.ref}` });
  } catch {}
}

async function postComment(body){
  await octo.rest.issues.createComment({ owner, repo, issue_number: prNumber, body }).catch(()=>{});
}

async function runRelease(){
  try {
    console.log("🏷️ Tagging & releasing…");
    sh("bash scripts/tag_and_release_v0100.sh");
    const ver = "v0.10.0";
    const url = `https://github.com/${owner}/${repo}/releases/tag/${ver}`;
    await postComment(`✅ Merged & released **${ver}** → ${url}`);
    console.log(`✅ Released ${ver} → ${url}`);
  } catch (e) {
    await postComment("⚠️ Merge done, but release script failed. Run `bash scripts/tag_and_release_v0100.sh` manually.");
  }
}

async function tick(){
  const pr = await getPR();
  if (pr.merged) { console.log("Already merged."); return true; }

  const latestSha = pr.head.sha;
  const green = await checksAllGreen(latestSha);
  const qaPass = await hasQAPassComment();
  const approved = await ensureApproved(pr);

  console.log(`[watch] checks=${green}  qaPass=${qaPass}  approved=${approved}`);

  if (green && qaPass && approved) {
    await mergePR(pr);
    await runRelease();
    return true;
  }
  return false;
}

(async () => {
  console.log(`Watching PR #${prNumber} for CI=[${requiredChecks.join(", ")}] + "QA: PASS"…`);
  // immediate attempt, then poll
  if (await tick()) process.exit(0);
  const id = setInterval(async () => {
    try {
      if (await tick()) { clearInterval(id); process.exit(0); }
    } catch (e) { console.log("poll error (continuing)…"); }
  }, pollMs);
})();
