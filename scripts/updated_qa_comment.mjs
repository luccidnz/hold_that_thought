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
const comment = `**Jules — Phase 10 QA Checklist**
1) Flags OFF: legacy capture/list/share OK  
2) RAG ON: Related sensible; Summarize; Daily Digest renders & shares  
3) Android: start record → lock 30–60s → stop; persistent notif; playback OK  
4) E2EE ON: set passphrase; capture → **Encrypted** badge; Supabase blob is \`.enc\`; lock/unlock works; wrong passphrase fails  
5) Auth ON: sign in on 2 devices; anon→account migration; cross-device sync  
6) Post results + short demo (see \`/docs/demo_phase10.md\`).`;

await octo.rest.issues.createComment({
  owner,
  repo,
  issue_number: prNumber,
  body: comment
});

console.log(`Updated QA checklist comment posted to PR #${prNumber}`);
