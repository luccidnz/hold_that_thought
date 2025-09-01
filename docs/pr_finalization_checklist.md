# PR Finalization Checklist

## Completed Steps
✅ Installed required dependencies (octokit, dotenv)  
✅ Screenshots verified and committed  
✅ Security wrap-up document created  
✅ Final sanity check performed  
✅ Post-merge release instructions provided  
✅ Backup PR comment text provided for manual posting  

## Steps Requiring GitHub Token
To complete these steps, set your GitHub token:

```powershell
$env:GITHUB_TOKEN = 'YOUR_FINE_GRAINED_TOKEN'
```

Then run:
1. PR update: `node scripts/pr_finalize.mjs`
2. Branch protection (requires admin): `node scripts/protect_main.mjs`

## After Merge
Run the release script:
```bash
bash scripts/tag_and_release_v0100.sh
```

This will create the v0.10.0 release using the notes in `docs/RELEASE_NOTES_v0.10.0.md`.
