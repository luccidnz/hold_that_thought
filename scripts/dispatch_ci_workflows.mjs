#!/usr/bin/env node

/**
 * Script to dispatch CI workflows after fixes
 * 
 * This script dispatches the Android QA Smoke workflow and the main CI workflow
 * to verify our fixes are working.
 */

import { Octokit } from '@octokit/rest';

// Configuration with correct repository info
const CONFIG = {
  owner: 'luccidnz',
  repo: 'hold_that_thought',
  workflowIds: {
    androidSmoke: 'android-qa-smoke.yml',
    ci: 'ci.yml'
  },
  branch: 'feature/phase10-auth-rag-android-e2ee' // PR branch
};

async function main() {
  console.log('Starting workflow dispatch process...');
  
  // Check for GitHub token from multiple sources
  const token = process.env.GITHUB_TOKEN || process.env.GH_TOKEN;
  if (!token) {
    console.error('❌ No GITHUB_TOKEN found in environment. Please set it first.');
    console.error('Example: $env:GITHUB_TOKEN = "ghp_your_token_here"');
    process.exit(1);
  }
  
  console.log(`Token found: ${token.substring(0, 4)}...${token.substring(token.length - 4)}`);
  console.log(`Repository: ${CONFIG.owner}/${CONFIG.repo}`);
  console.log(`Branch: ${CONFIG.branch}`);

  const octokit = new Octokit({ auth: token });
  
  console.log('🚀 Dispatching workflows to verify CI fixes...');

  try {
    // Dispatch Android Smoke workflow
    console.log(`Dispatching Android QA Smoke workflow...`);
    await octokit.actions.createWorkflowDispatch({
      owner: CONFIG.owner,
      repo: CONFIG.repo,
      workflow_id: CONFIG.workflowIds.androidSmoke,
      ref: CONFIG.branch
    });
    console.log('✅ Android QA Smoke workflow dispatched successfully');

    // Dispatch main CI workflow
    console.log(`Dispatching main CI workflow...`);
    await octokit.actions.createWorkflowDispatch({
      owner: CONFIG.owner,
      repo: CONFIG.repo,
      workflow_id: CONFIG.workflowIds.ci,
      ref: CONFIG.branch
    });
    console.log('✅ Main CI workflow dispatched successfully');

    console.log('\n🎉 Both workflows dispatched! Check GitHub Actions for results.');
    console.log('Once CI passes, Jules can proceed with QA and approve with "QA: PASS"');
  } catch (error) {
    console.error('❌ Error dispatching workflows:', error.message);
    if (error.response) {
      console.error('Response status:', error.response.status);
      console.error('Response data:', error.response.data);
    }
    process.exit(1);
  }
}

main().catch(error => {
  console.error('❌ Unhandled error:', error);
  process.exit(1);
});
