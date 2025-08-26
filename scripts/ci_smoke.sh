#!/usr/bin/env bash
set -euxo pipefail

flutter analyze || true
flutter test -j 1 --reporter expanded --no-color || true
