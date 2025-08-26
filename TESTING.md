# Testing

This document outlines the testing strategy for the project.

## Unit Tests

Unit tests are located in the `test/` directory and are run with the `flutter test` command. They cover individual classes and functions.

## Widget Tests

Widget tests are also in the `test/` directory and use the `flutter_test` package. They test individual widgets in isolation.

## Integration Tests

Integration tests are located in the `integration_test/` directory. They are used for end-to-end testing of the application on a device or emulator. Due to environment limitations, they are currently skipped in CI.

## Golden Tests

Golden tests are used to verify that the UI has not changed unexpectedly. They are located in the `test/` directory and are run as part of the normal test suite.
