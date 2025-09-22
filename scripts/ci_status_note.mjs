// scripts/ci_status_note.mjs
import { Octokit } from '@octokit/rest';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

// Initialize Octokit with the GitHub token
const octokit = new Octokit({
  auth: process.env.GITHUB_TOKEN
});

async function getCurrentRepo() {
  try {
    const { stdout } = await execAsync('git remote -v');
    const remoteUrl = stdout.split('\n')[0];
    const match = remoteUrl.match(/github\.com[:/]([^/]+)\/([^.]+)(\.git)?/);
    
    if (match) {
      return {
        owner: match[1],
        repo: match[2]
      };
    }
    
    throw new Error('Unable to parse remote URL');
  } catch (error) {
    console.error('Error getting repository info:', error);
    throw error;
  }
}

async function postPRComment(owner, repo, prNumber, comment) {
  try {
    await octokit.issues.createComment({
      owner,
      repo,
      issue_number: prNumber,
      body: comment
    });
    console.log(`Comment posted to PR #${prNumber} successfully.`);
  } catch (error) {
    console.error('Error posting comment:', error);
    throw error;
  }
}

async function main() {
  try {
    // Get repository info
    const { owner, repo } = await getCurrentRepo();
    
    // Status comment message
    const comment = "Pushed CI workflow hardening for lint/test; re-running checks now. Jules: please re-run Artifacts-only QA once both 'CI' and 'Android QA Smoke' are green.";
    
    // Post the comment to PR #3
    await postPRComment(owner, repo, 3, comment);
    
  } catch (error) {
    console.error('Error in main function:', error);
    process.exit(1);
  }
}

main();
