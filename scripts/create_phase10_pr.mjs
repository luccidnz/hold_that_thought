import { execSync } from "node:child_process";
import { Octokit } from "octokit";
import fs from "node:fs";

function sh(cmd){ return execSync(cmd,{stdio:["ignore","pipe","pipe"]}).toString().trim(); }

const token = process.env.GITHUB_TOKEN || process.env.GH_TOKEN;
if(!token){ throw new Error("Set GITHUB_TOKEN or GH_TOKEN with repo scope."); }

const remote = sh('git config --get remote.origin.url');
const m = remote.match(/github\.com[:/](.+?)\.git$/);
if(!m) throw new Error("Cannot parse owner/repo from origin.");
const [owner, repo] = m[1].split("/");

const head = sh('git rev-parse --abbrev-ref HEAD');
const base = "main";

const octo = new Octokit({ auth: token });

// Find existing PR for this branch
const { data: prs } = await octo.rest.pulls.list({ owner, repo, head: `${owner}:${head}`, state: "open" });
const title = "Phase 10 — Auth, RAG, Android Foreground Recording, E2EE";

// We can't easily deep-link artifacts without gh; point to Actions tab for the branch:
const runUrl = `https://github.com/${owner}/${repo}/actions?query=branch%3A${encodeURIComponent(head)}+is%3Asuccess`;

// Read PR body from file
const body = fs.readFileSync("docs/PR_PHASE10_BODY.md", "utf8");

if (prs.length) {
  await octo.rest.pulls.update({
    owner, repo, pull_number: prs[0].number, title,
    body: body
  });
  console.log(`Updated PR #${prs[0].number}`);
} else {
  const { data: pr } = await octo.rest.pulls.create({
    owner, repo, title, head, base,
    body: body
  });
  console.log(`Created PR #${pr.number}`);
}
