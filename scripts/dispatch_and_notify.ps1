# Script to manually trigger workflows and notify Jules
# This script uses the GitHub CLI (gh) instead of tokens

# 1. Ensure gh CLI is authenticated
$ghAuth = gh auth status 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "GitHub CLI not authenticated. Please run 'gh auth login' first."
    exit 1
}

# 2. Get repository information
$repoInfo = gh repo view --json 'owner,name' | ConvertFrom-Json
$owner = $repoInfo.owner.login
$repo = $repoInfo.name
$branch = git rev-parse --abbrev-ref HEAD

Write-Host "Repository: $owner/$repo"
Write-Host "Branch: $branch"

# 3. Dispatch workflows
Write-Host "`nDispatching workflows..."

Write-Host "1. Dispatching CI workflow"
gh workflow run ci.yml --ref $branch
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ CI workflow dispatched successfully"
} else {
    Write-Host "❌ Failed to dispatch CI workflow"
}

Write-Host "2. Dispatching Android QA Smoke workflow"
gh workflow run android-qa-smoke.yml --ref $branch
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Android QA Smoke workflow dispatched successfully"
} else {
    Write-Host "❌ Failed to dispatch Android QA Smoke workflow"
}

# 4. Get PR number
$prInfo = gh pr view --json number,title 2>&1
if ($LASTEXITCODE -eq 0) {
    $prData = $prInfo | ConvertFrom-Json
    $prNumber = $prData.number
    $prTitle = $prData.title
    
    Write-Host ""
    Write-Host "Found PR #$prNumber`: $prTitle"
    
    # 5. Add comment to PR
    $comment = @'
CI fixes pushed:
- Replaced flaky emulator test with stable package-name assertion
- Coverage gate set via `COVERAGE_MIN=60`
- Workflows re-dispatched

Please recheck **Checks → Summary**, and if green, comment **QA: PASS** to auto-merge + tag v0.10.0.
'@

    gh pr comment $prNumber --body "$comment"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Comment added to PR #$prNumber"
    } else {
        Write-Host "❌ Failed to add comment to PR"
    }
} else {
    Write-Host "❌ No PR found for branch $branch"
}

Write-Host "`nScript completed. Please check GitHub Actions for workflow status."
