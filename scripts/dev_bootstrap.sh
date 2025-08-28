#!/usr/bin/env bash
set -euxo pipefail

flutter pub get

if grep -R --include=\*.dart -n "part '.*\.g.dart';" lib/ >/dev/null 2>&1; then
  echo "+ build_runner (codegen)"
  flutter pub run build_runner build --delete-conflicting-outputs || true
fi

dart format --set-exit-if-changed . || true
flutter analyze || true
flutter test -j 1 --reporter expanded --no-color || true
