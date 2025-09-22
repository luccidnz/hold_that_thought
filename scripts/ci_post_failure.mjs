// scripts/ci_post_failure.mjs
import { Octokit } from '@octokit/rest';
import { exec } from 'child_process';
import { promisify } from 'util';
import { createReadStream, createWriteStream } from 'fs';
import { pipeline } from 'stream';
import { unzip } from 'zlib';
import { Readable } from 'stream';
import fs from 'fs/promises';
import path from 'path';
import os from 'os';

const execAsync = promisify(exec);
const streamPipeline = promisify(pipeline);

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

async function getCurrentBranch() {
  try {
    const { stdout } = await execAsync('git branch --show-current');
    return stdout.trim();
  } catch (error) {
    console.error('Error getting current branch:', error);
    throw error;
  }
}

async function getLatestFailedWorkflow(owner, repo, branch) {
  try {
    const { data } = await octokit.actions.listWorkflowRunsForRepo({
      owner,
      repo,
      branch,
      status: 'failure',
      per_page: 5
    });

    const workflowRuns = data.workflow_runs;
    
    if (workflowRuns.length === 0) {
      console.log('No failed workflow runs found for this branch.');
      return null;
    }
    
    // Sort by created_at in descending order
    workflowRuns.sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
    
    return workflowRuns[0];
  } catch (error) {
    console.error('Error getting workflow runs:', error);
    throw error;
  }
}

async function downloadAndExtractLogs(logUrl, tempDir) {
  try {
    const response = await octokit.request(`GET ${logUrl}`);
    const logsBuffer = Buffer.from(response.data);
    
    // Create a temp file to store the logs
    const tempFilePath = path.join(tempDir, 'workflow_logs.zip');
    await fs.writeFile(tempFilePath, logsBuffer);
    
    // Extract the logs
    const extractDir = path.join(tempDir, 'extracted_logs');
    await fs.mkdir(extractDir, { recursive: true });
    
    // Unzip the logs
    const source = createReadStream(tempFilePath);
    const unzipped = source.pipe(unzip());
    
    // Process the unzipped logs to find the failing job
    let logs = '';
    const chunks = [];
    
    await new Promise((resolve, reject) => {
      unzipped.on('data', (chunk) => chunks.push(chunk));
      unzipped.on('end', () => {
        logs = Buffer.concat(chunks).toString('utf8');
        resolve();
      });
      unzipped.on('error', reject);
    });
    
    return logs;
  } catch (error) {
    console.error('Error downloading or extracting logs:', error);
    throw error;
  }
}

async function findFailingJobLogs(logs) {
  // Look for the "Install dependencies" step in the lint_and_test job
  const lines = logs.split('\n');
  let startIndex = -1;
  let endIndex = -1;
  
  // Find the start of the Install dependencies step
  for (let i = 0; i < lines.length; i++) {
    if (lines[i].includes('##[group]Install dependencies')) {
      startIndex = i + 1;
      break;
    }
  }
  
  // If we found the start, look for the end (next group or end of job)
  if (startIndex !== -1) {
    for (let i = startIndex; i < lines.length; i++) {
      if (lines[i].includes('##[endgroup]') || lines[i].includes('##[group]')) {
        endIndex = i;
        break;
      }
    }
  }
  
  // If we couldn't find the exact boundaries, just return the first 80 lines after "Install dependencies"
  if (startIndex === -1) {
    return 'Could not find "Install dependencies" step in logs.';
  }
  
  if (endIndex === -1) {
    endIndex = startIndex + 80;
  }
  
  // Return first 80 lines of the failing step
  return lines.slice(startIndex, Math.min(startIndex + 80, endIndex)).join('\n');
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
    const branch = await getCurrentBranch();
    
    console.log(`Repository: ${owner}/${repo}, Branch: ${branch}`);
    
    // Get the latest failed workflow run
    const failedRun = await getLatestFailedWorkflow(owner, repo, branch);
    
    if (!failedRun) {
      console.log('No failed workflow runs found. Nothing to post.');
      return;
    }
    
    console.log(`Found failed workflow run: ${failedRun.id} - ${failedRun.name}`);
    
    // Create temp directory
    const tempDir = await fs.mkdtemp(path.join(os.tmpdir(), 'ci-logs-'));
    
    // Download and extract logs
    const logs = await downloadAndExtractLogs(failedRun.logs_url, tempDir);
    
    // Find the failing job
    const failingStepLogs = await findFailingJobLogs(logs);
    
    // Construct the comment
    const comment = `**CI triage note:** previous run failed in 'Install dependencies'. Here are the first 80 lines of the failing step:

\`\`\`
${failingStepLogs}
\`\`\``;
    
    // Post the comment to PR #3
    await postPRComment(owner, repo, 3, comment);
    
    // Cleanup
    await fs.rm(tempDir, { recursive: true, force: true });
    
  } catch (error) {
    console.error('Error in main function:', error);
    process.exit(1);
  }
}

main();
