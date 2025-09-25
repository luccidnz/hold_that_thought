# QA Playbook: Artifacts-only

This document outlines the steps for performing an "Artifacts-only" QA process. This is typically done for releases where the only changes are to the build process or other non-code areas.

## Finding Build Artifacts

Build artifacts can be found in the GitHub Actions workflows for the `build_android` and `build_windows` jobs.

- Go to the "Actions" tab in the GitHub repository.
- Find the relevant workflow run.
- Download the artifacts from the "Artifacts" section of the workflow summary.
    - `build_android` produces `Android Debug APK`
    - `build_windows` produces `Windows Release`

## Checks to Perform

1.  **APK Installation:**
    - The downloaded artifact will be a `.zip` file containing the APK.
    - Unzip the file.
    - Install the `.apk` file on an Android device or emulator.
    - Verify that the app installs and opens without crashing.

2.  **Windows ZIP Unpacking:**
    - The downloaded artifact will be a `.zip` file.
    - Unpack the `.zip` file on a Windows machine.
    - Verify that the contents are extracted correctly and the application runs.

3.  **Checksum Verification:**
    - Each artifact should have a corresponding `.sha256` file.
    - Calculate the SHA256 checksum of the downloaded artifact (the `.apk` or `.zip` file).
    - Verify that the calculated checksum matches the contents of the `.sha256` file.

## Recording PASS/FAIL

After performing the checks, record the results in the relevant GitHub issue or pull request.

---

Artifacts-only QA complete: release vX.Y.Z published with APK + Windows ZIP + checksums.