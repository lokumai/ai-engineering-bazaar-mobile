#!/bin/bash
# The Android store build: the checks of release_checks.sh, the gate, then the APK and the bundle. Changes no source.
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/release_checks.sh
release_checks

release_gate

echo "Running flutter build apk"
fvm flutter build apk --release --target lib/main/main_prod.dart --dart-define-from-file=sentry_dsn.json

echo "Running flutter build appbundle"
fvm flutter build appbundle --release --target lib/main/main_prod.dart --dart-define-from-file=sentry_dsn.json
