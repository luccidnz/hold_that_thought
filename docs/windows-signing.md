# Windows Code Signing (CI)

## Secrets (Repository → Settings → Secrets and variables → Actions)
- `WIN_CERT_PFX_B64` — Base64 of your code signing certificate `.pfx`
  - macOS: `base64 -i cert.pfx | pbcopy`
  - Linux: `base64 -w 0 cert.pfx > out.b64`
  - Windows (PowerShell): `[Convert]::ToBase64String([IO.File]::ReadAllBytes('cert.pfx'))`
- `WIN_CERT_PASSWORD` — password for the PFX

## Behavior
- On **stable tags** (`vX.Y.Z`) only, if `WIN_CERT_PFX_B64` is set:
  1) CI restores the certificate to the user store.
  2) Signs all EXEs under `build/windows/x64/runner/Release/` with SHA256 and a DigiCert timestamp.
  3) Packages the **signed** binaries into the ZIP.
  4) A separate Windows job downloads the release ZIP and validates that all EXEs are **Valid** signed.

- RC tags (`vX.Y.Z-rcN`) skip signing entirely.

## Local validation
On Windows PowerShell:
```pwsh
Get-AuthenticodeSignature 'path\to\your.exe'
```

## Troubleshooting
- If `signtool.exe` is not found, ensure Windows SDK is installed
- Certificate must be valid for code signing
- Timestamp server must be reachable (uses DigiCert)
- Only EXE files in `build/windows/x64/runner/Release/` are signed