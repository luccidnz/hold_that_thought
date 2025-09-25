#!/usr/bin/env node

const https = require('https');

const token = process.env.GITHUB_TOKEN;
if (!token) {
  console.log('❌ GITHUB_TOKEN not set. Please set it and try again.');
  process.exit(1);
}

const owner = 'luccidnz';
const repo = 'hold_that_thought';
const prNumber = 3;

const body = `Pushed CI fix: switched setup-android to use valid inputs and stabilized the Windows Flutter build. CI will produce artifacts (Windows Release & Android Debug APK). When both jobs are green and artifacts are present, please run Artifacts-only QA and, if it matches the checklist, comment 'QA: PASS'.`;

const postData = JSON.stringify({ body });

const options = {
  hostname: 'api.github.com',
  port: 443,
  path: `/repos/${owner}/${repo}/issues/${prNumber}/comments`,
  method: 'POST',
  headers: {
    'Authorization': `token ${token}`,
    'User-Agent': 'nodejs-script',
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(postData)
  }
};

const req = https.request(options, (res) => {
  console.log(`Status: ${res.statusCode}`);
  res.on('data', (d) => {
    process.stdout.write(d);
  });
  res.on('end', () => {
    if (res.statusCode === 201) {
      console.log('\n✅ Comment posted successfully to PR #3');
    } else {
      console.log('\n❌ Failed to post comment');
    }
  });
});

req.on('error', (e) => {
  console.error(`❌ Request error: ${e.message}`);
});

req.write(postData);
req.end();
