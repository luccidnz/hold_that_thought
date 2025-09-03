param(
  [string]$OutPath = "./jules_env.zip",
  [ValidateSet("7z","openssl")][string]$Method = "7z"
)
$ErrorActionPreference = "Stop"
function Read-Secret($prompt){
  $s = Read-Host -AsSecureString "$prompt"
  $b = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($s)
  try { [Runtime.InteropServices.Marshal]::PtrToStringBSTR($b) } finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($b) }
}

$SUPABASE_URL      = Read-Secret "SUPABASE_URL"
$SUPABASE_ANON_KEY = Read-Secret "SUPABASE_ANON_KEY"
$OPENAI_API_KEY    = Read-Secret "OPENAI_API_KEY"

# Create plaintext file (local, short-lived)
$plain = @"
SUPABASE_URL=$SUPABASE_URL
SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
OPENAI_API_KEY=$OPENAI_API_KEY
"@
$plainPath = Join-Path (Get-Location) "jules.env"
$plain | Out-File -Encoding ascii $plainPath

# Strong passphrase (not written to disk)
$pass = [Guid]::NewGuid().ToString("N") + [Guid]::NewGuid().ToString("N")
# Optional: copy to clipboard for quick out-of-band sending
Set-Clipboard -Value $pass | Out-Null

if ($Method -eq "7z") {
  $seven = (Get-Command 7z.exe -ErrorAction SilentlyContinue)
  if (-not $seven) { throw "7z.exe not found. Install 7-Zip or re-run with -Method openssl" }
  & 7z a -tzip -p$pass -mem=AES256 $OutPath $plainPath | Out-Null
  & 7z t $OutPath -p$pass | Out-Null
} else {
  $openssl = (Get-Command openssl -ErrorAction SilentlyContinue)
  if (-not $openssl) { throw "OpenSSL not found. Install it or use -Method 7z" }
  $encPath = [IO.Path]::ChangeExtension($OutPath, ".env.enc")
  & openssl enc -aes-256-cbc -pbkdf2 -salt -in $plainPath -out $encPath -k $pass
  $OutPath = $encPath
}

# Securely remove plaintext
try {
  # Best-effort overwrite + delete
  $bytes = [byte[]](1..$plain.Length | ForEach-Object { 0 })
  [IO.File]::WriteAllBytes($plainPath, $bytes)
} catch {}
Remove-Item $plainPath -Force

Write-Host "✅ Encrypted env ready: $OutPath"
Write-Host "🔐 Passphrase copied to clipboard. Send passphrase via a separate channel (SMS/call)."
Write-Host "📎 Share the file (e.g., OneDrive/Drive share link) — but never with the passphrase in the same message."
