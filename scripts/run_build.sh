#!/bin/bash
set -e

# Review 6, finding 20: a release without the Sentry DSN reports no crashes.
if [ ! -f sentry_dsn.json ]; then
  echo "sentry_dsn.json is missing: a release built without it reports no crashes. See docs/development.md, Release."
  exit 1
fi

# Review 7, finding 6: a store build comes from committed code, the code CI saw, and the script changes no source.
if [ -n "$(git status --porcelain --untracked-files=no)" ]; then
  echo "The working tree has uncommitted changes. Commit or stash them first: a store build is built from a commit."
  exit 1
fi

echo "Running flutter clean"
fvm flutter clean

echo "Running pub get"
fvm flutter pub get

echo "Running intl_utils"
fvm dart run intl_utils:generate
# intl_utils formats its output at 80 columns; reformat to 120 so the committed files stay unchanged
fvm dart format lib/generated --line-length=120 >/dev/null
if [ -n "$(git status --porcelain --untracked-files=no)" ]; then
  echo "The generated localizations differ from the committed ones. Generate, commit, and run again."
  exit 1
fi

# The gate of CLAUDE.md: format, analyze, every test with coverage, and the coverage floor.
echo "Running the gate"
fvm dart format . --line-length=120 --set-exit-if-changed
fvm flutter analyze
fvm flutter test --coverage
scripts/check_coverage.sh coverage/lcov.info 90

echo "Running flutter build apk"
fvm flutter build apk --release --target lib/main/main_prod.dart --dart-define-from-file=sentry_dsn.json

echo "Running flutter build appbundle"
fvm flutter build appbundle --release --target lib/main/main_prod.dart --dart-define-from-file=sentry_dsn.json
