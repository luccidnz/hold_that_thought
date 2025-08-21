# Flaky: quick_capture_widget_test.dart fails in CI

This test intermittently fails in CI due to async init/widget binding timing.
Temporarily disabled in the stabilization PR. Re-enable after fixing.

**Repro hint:** run `flutter test --test-randomize-ordering-seed=random` multiple times.
**Acceptance:** test is deterministic in CI and no longer needs disabling.
