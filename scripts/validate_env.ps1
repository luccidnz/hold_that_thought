$envPath = Join-Path (Get-Location) ".env"
if (!(Test-Path $envPath)) { Write-Host "❌ .env not found. Copy .env.example -> .env"; exit 1 }
$lines = Get-Content $envPath | Where-Object { $_ -notmatch '^\s*#' -and $_ -match '=' }
$map = @{}
foreach ($l in $lines) { $k,$v = $l -split '=',2; $map[$k.Trim()] = $v.Trim() }
$required = @('SUPABASE_URL','SUPABASE_ANON_KEY','OPENAI_API_KEY')
$missing = $required | Where-Object { -not $map.ContainsKey($_) -or [string]::IsNullOrWhiteSpace($map[$_]) }
if ($missing.Count -gt 0) {
  Write-Host ("❌ Missing keys: " + ($missing -join ', '))
  exit 1
}
Write-Host "✅ .env looks good."
exit 0
