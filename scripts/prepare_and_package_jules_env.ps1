param([string]$Passphrase = $null, 
  [string]$OutPath = ".\jules_env.zip",
  [ValidateSet("7z","openssl")][string]$Method = "7z"
)
$ErrorActionPreference = "Stop"

function Read-Plain([string]$label) {
  $s = Read-Host -AsSecureString $label
  $b = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($s)
  try { [Runtime.InteropServices.Marshal]::PtrToStringBSTR($b) } finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($b) }
}

$SUPABASE_URL      = Read-Plain "SUPABASE_URL"
$SUPABASE_ANON_KEY = Read-Plain "SUPABASE_ANON_KEY"
$OPENAI_API_KEY    = Read-Plain "OPENAI_API_KEY"

# Write plaintext .env (temporary)
$plainPath  = Join-Path (Get-Location) "jules.env"
$envContent = @"
SUPABASE_URL=$SUPABASE_URL
SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
OPENAI_API_KEY=$OPENAI_API_KEY
"@
Set-Content -Path $plainPath -Value $envContent -Encoding UTF8

# Generate strong passphrase
if (-not $Passphrase) {
  $bytes = New-Object byte[] 32
  [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
  $Passphrase = ([Convert]::ToBase64String($bytes) -replace "[+/=]","a")
}
$pass = $Passphrase

# Copy to clipboard for out-of-band send
Set-Clipboard -Value $pass | Out-Null

if ($Method -eq "7z") {
  $seven = Get-Command 7z.exe -ErrorAction SilentlyContinue
  if (-not $seven) { throw "7z.exe not found. Install 7-Zip or run with -Method openssl." }
  & $seven.Path a -tzip "-p$pass" -mem=AES256 "$OutPath" "$plainPath" | Out-Null
  & $seven.Path t "$OutPath" "-p$pass" | Out-Null
} else {
  $openssl = Get-Command openssl -ErrorAction SilentlyContinue
  if (-not $openssl) { throw "OpenSSL not found. Install it or use -Method 7z." }
  $encPath = [IO.Path]::ChangeExtension($OutPath, ".env.enc")
  & $openssl.Path enc -aes-256-cbc -pbkdf2 -salt -in "$plainPath" -out "$encPath" -k "$pass"
  $OutPath = $encPath
}

# Remove plaintext file
Remove-Item "$plainPath" -Force

Write-Host "Encrypted env ready: $OutPath"
Write-Host "Passphrase copied to clipboard. Send via a separate channel."

