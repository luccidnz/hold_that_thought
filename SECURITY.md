# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in Hold That Thought, please report it by sending an email to security@holdthatthought.app. Please do not disclose security vulnerabilities publicly until they have been addressed by the team.

When reporting a vulnerability, please include:

- A detailed description of the vulnerability
- Steps to reproduce the issue
- Potential impact of the vulnerability
- Any potential solutions you may have identified

## End-to-End Encryption (E2EE)

Hold That Thought implements optional end-to-end encryption for protecting your data. Here's what you should know:

### How E2EE Works in Hold That Thought

1. **Passphrase-Based**: All encryption is based on a passphrase that only you know. This passphrase is never sent to our servers.

2. **Envelope Encryption**: We use envelope encryption where:
   - Each thought (transcript and audio) is encrypted with a unique Data Encryption Key (DEK)
   - The DEK is then encrypted with a Key Encryption Key (KEK) derived from your passphrase
   - Only the encrypted DEK is stored alongside your data

3. **Algorithms Used**:
   - AES-GCM-256 for symmetric encryption
   - Argon2id (or PBKDF2 as fallback) for key derivation

### Security Considerations

1. **Passphrase Protection**: The security of your data depends on the strength of your passphrase. Choose a strong, unique passphrase that you don't use elsewhere.

2. **Passphrase Recovery**: We cannot recover your data if you forget your passphrase. There is no "back door" or recovery mechanism.

3. **Device Security**: Your passphrase may be temporarily stored in memory during app use. Ensure your device is secured with a strong PIN, password, or biometric protection.

4. **Limitations**: Metadata such as creation dates and titles are not encrypted to enable basic app functionality.

### Best Practices

1. **Use a Strong Passphrase**: Choose a passphrase with at least 12 characters, including upper and lowercase letters, numbers, and symbols.

2. **Backup Your Passphrase**: Store your passphrase in a secure password manager or another secure location.

3. **Enable Device Security**: Use strong authentication methods on your device.

4. **Keep the App Updated**: Security improvements and fixes are regularly included in updates.

## Transparency

We are committed to transparency about our security practices. If you have questions or concerns about Hold That Thought's security, please contact us at security@holdthatthought.app.

## Changes to This Policy

This Security Policy may be updated from time to time. We will notify users of any significant changes through the app or via email.
