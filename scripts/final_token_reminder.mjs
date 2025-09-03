import { execSync } from "node:child_process";
import { Octokit } from "octokit";
import fs from "node:fs";
import * as dotenv from 'dotenv';

// Load environment variables from .env file
dotenv.config();

function sh(cmd){ return execSync(cmd,{stdio:["ignore","pipe","pipe"]}).toString().trim(); }

const token = process.env.GITHUB_TOKEN || process.env.GH_TOKEN;
if(!token || token === 'your_github_token_here'){
  console.error("Please set GITHUB_TOKEN in your .env file with a valid token.");
  process.exit(1);
}

const remote = sh('git config --get remote.origin.url');
const m = remote.match(/github\.com[:/](.+?)\.git$/);
if(!m) throw new Error("Cannot parse owner/repo from origin.");
const [owner, repo] = m[1].split("/");

const head = sh('git rev-parse --abbrev-ref HEAD');

const octo = new Octokit({ auth: token });

// Find PR for this branch
const { data: prs } = await octo.rest.pulls.list({ owner, repo, head: `${owner}:${head}`, state: "open" });

if (prs.length === 0) {
  console.error("No open PR found for the current branch");
  process.exit(1);
}

const prNumber = prs[0].number;
const comment = `_Maintainer note: Please confirm the previous GitHub token has been **revoked/rotated**. Supabase keys should also be rotated if they were ever exposed._`;

await octo.rest.issues.createComment({
  owner,
  repo,
  issue_number: prNumber,
  body: comment
});

console.log(`Final token rotation reminder comment posted to PR #${prNumber}`);
