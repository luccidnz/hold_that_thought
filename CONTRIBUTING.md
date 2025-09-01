# Contributing to Hold That Thought

Thank you for your interest in contributing to Hold That Thought! This document provides guidelines and instructions for contributing to the project.

## Code of Conduct

Please be respectful and considerate of others when contributing to the project. We aim to foster an inclusive and welcoming community.

## Getting Started

1. **Fork the repository** and clone it locally.
2. **Set up your development environment** following the instructions in the README.md.
3. **Create a new branch** for your feature or bugfix:
   ```
   git checkout -b feature/your-feature-name
   ```
   or
   ```
   git checkout -b fix/issue-you-are-fixing
   ```

## Development Workflow

1. **Make your changes** and ensure they follow the project's style and architecture.
2. **Write or update tests** to cover your changes.
3. **Run tests locally** to ensure they pass:
   ```
   flutter test
   ```
4. **Update documentation** if necessary.
5. **Commit your changes** with clear, descriptive commit messages.
6. **Push your branch** to your fork.
7. **Create a pull request** to the main repository.

## Pull Request Guidelines

1. **Describe your changes** in detail, explaining the purpose and implementation.
2. **Reference any related issues** using GitHub's issue linking syntax (e.g., "Fixes #123").
3. **Keep your PR focused** on a single feature or bugfix.
4. **Ensure CI passes** before requesting a review.
5. **Be responsive to feedback** and make requested changes promptly.

## Code Style and Architecture

- Follow the existing code style and architecture patterns in the project.
- Use meaningful variable and function names.
- Add comments for complex logic.
- Organize code into appropriate directories and files.
- Use Flutter/Dart best practices.

## Testing

- Add tests for new features and bug fixes.
- Ensure your changes don't break existing functionality.
- Aim for high test coverage.

## Working with Encryption

If you're working on E2EE features:

1. **Understand the encryption model** - we use envelope encryption with AES-GCM.
2. **Never store keys in code** - all encryption keys should be derived from user passphrases.
3. **Follow cryptographic best practices** - use secure random number generation, proper key derivation functions, etc.
4. **Test thoroughly** - ensure encryption and decryption work correctly in all scenarios.
5. **Consider security implications** - think about attack vectors and mitigations.

## Feature Flags

When adding new features, implement them behind feature flags so they can be toggled on/off:

1. Use the `FeatureFlags` service to check if a feature is enabled.
2. Make sure the app works correctly with the feature disabled.
3. Document the feature flag in the README.

## Reporting Issues

If you find a bug or have a feature request:

1. **Check existing issues** to avoid duplicates.
2. **Create a new issue** with a clear title and detailed description.
3. **Include steps to reproduce** for bugs.
4. **Add screenshots or videos** if applicable.
5. **Specify your environment** (OS, Flutter version, etc.).

## License

By contributing to Hold That Thought, you agree that your contributions will be licensed under the same license as the project.

Thank you for contributing!
