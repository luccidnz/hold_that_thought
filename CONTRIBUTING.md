# Contributing to Hold That Thought

First off, thank you for considering contributing to Hold That Thought! It's people like you that make this project great.

## Branch Naming

We use a simple branch naming convention to keep our repository clean and organized. All branches should be prefixed with one of the following:

- `feat/`: for new features (e.g., `feat/add-user-authentication`)
- `fix/`: for bug fixes (e.g., `fix/resolve-login-issue`)
- `chore/`: for maintenance tasks, such as updating dependencies or CI/CD configurations (e.g., `chore/update-flutter-version`)
- `docs/`: for documentation changes (e.g., `docs/add-contributing-guide`)

## Commit Style

We follow the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) specification for our commit messages. This helps us to have a clear and descriptive commit history, and it also allows us to automate the release process.

Each commit message consists of a **header**, a **body**, and a **footer**.

```
<type>[optional scope]: <description>

[optional body]

[optional footer]
```

### Type

The type must be one of the following:

- `feat`: A new feature
- `fix`: A bug fix
- `chore`: Changes to the build process or auxiliary tools and libraries such as documentation generation
- `docs`: Documentation only changes
- `style`: Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc)
- `refactor`: A code change that neither fixes a bug nor adds a feature
- `perf`: A code change that improves performance
- `test`: Adding missing tests or correcting existing tests

## Pull Request Process

1. Ensure any install or build dependencies are removed before the end of the layer when doing a build.
2. Update the README.md with details of changes to the interface, this includes new environment variables, exposed ports, useful file locations and container parameters.
3. Increase the version numbers in any examples files and the README.md to the new version that this Pull Request would represent. The versioning scheme we use is [SemVer](http://semver.org/).
4. You may merge the Pull Request in once you have the sign-off of two other developers, or if you do not have permission to do that, you may request the second reviewer to merge it for you.
