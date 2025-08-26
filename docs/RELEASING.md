# Releasing

This document describes the release process for this project.

## Versioning

We use [Semantic Versioning](http.semver.org/).

## Release Process

1.  Create a new release branch from `main`.
2.  Update the version number in `pubspec.yaml`.
3.  Update the `CHANGELOG.md` with the changes for the new release.
4.  Run all tests and ensure they pass.
5.  Create a pull request to merge the release branch into `main`.
6.  Once the pull request is merged, create a new release on GitHub from the `main` branch.
7.  A dry-run can be performed by setting the `DRY_RUN` environment variable: `DRY_RUN=1 bash -x scripts/release.sh v0.0.1-dryrun`
