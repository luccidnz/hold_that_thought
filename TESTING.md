# Testing

This document provides an overview of how to run tests and the testing strategies used in this project.

## Running Tests

The full test suite can be run from the command line using the standard Flutter test command:

```bash
flutter test
```

This will execute all unit and widget tests in the `test/` directory.

### Code Generation

This project uses `mockito` for creating mock objects and `hive_generator` for data models. If you make changes to files that require code generation (e.g., adding new methods to a repository that is mocked), you will need to run the `build_runner` to update the generated files (`.mocks.dart` and `.g.dart`).

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Golden File Testing

Several tests use golden files to verify that the UI renders correctly. Golden files are reference images stored in the `test/goldens/` directory.

If you make a UI change that is intentional and causes a golden test to fail, you need to update the reference images. You can do this by running:

```bash
flutter test --update-goldens
```

After running this command, be sure to review the changed images in the `test/goldens/` directory to ensure they are correct before committing them.

## Mocking Strategy

The primary service layer, such as `NotesRepository`, is mocked in widget tests to provide a controlled and predictable environment. This allows UI tests to run without needing a real database or network connection.

Mocks are generated using `mockito` and the `@GenerateMocks` annotation. When running tests, the real `Provider` is overridden with the mock implementation:

```dart
// Example from a test
await tester.pumpWidget(
  ProviderScope(
    overrides: [
      // Replace the real NotesRepository with our mock version
      notesRepositoryProvider.overrideWith((ref) => mockNotesRepository),
    ],
    child: const MaterialApp(home: YourWidget()),
  ),
);
```

## Known Issues

### `quick_capture_widget_test.dart`

The test file `test/quick_capture/quick_capture_widget_test.dart` is **temporarily disabled**. This test proved to be flaky in the CI environment, failing unpredictably when testing for the appearance of a `SnackBar`. The underlying application code has been fixed, but the test itself remains unstable. It has been disabled to ensure the stability of the main build and will be revisited in a future task.

## Continuous Integration

CI runs on GitHub Actions for every push/PR:
- Lint: format + analyze
- Codegen: build_runner + gen-l10n
- Tests: unit/widget tests with randomized ordering
- Coverage: lcov artifact uploaded to the workflow run
- Goldens: never auto-updated on PRs. To refresh, run locally and commit,
  or add the PR label `update-goldens` to allow CI golden run.

Local equivalents:
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter gen-l10n
flutter test --coverage --test-randomize-ordering-seed=random
