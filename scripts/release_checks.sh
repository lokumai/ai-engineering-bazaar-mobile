#!/bin/bash
# The checks every store build passes, sourced by run_build.sh, run_fvm_build.sh and run_ios_build.sh from the repo's
# root (review 6, finding 20; review 7, finding 6; review 8, finding 8). Each check prints why it stops and exits 1.

# A release without a real Sentry DSN reports no crashes: the README's placeholder or {} is refused too.
release_dsn_check() {
  local file="${1:-sentry_dsn.json}"
  if [ ! -f "$file" ]; then
    echo "$file is missing: a release built without it reports no crashes. See docs/development.md, Release."
    exit 1
  fi
  local dsn
  dsn=$(sed -n 's/.*"SENTRY_DSN"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$file" | head -n 1)
  if [[ ! "$dsn" =~ ^https://[0-9a-f]+@.+/[0-9]+$ ]]; then
    echo "$file has no Sentry DSN of the form https://<key>@<host>/<project id>: the release would report no crashes."
    exit 1
  fi
}

# A store build comes from committed code, the code CI saw: nothing changed, and no stray file in a folder the build
# takes whole (pubspec.yaml bundles assets/content/ by folder, Gradle takes all of res/, Xcode its folders).
release_tree_check() {
  if [ -n "$(git status --porcelain --untracked-files=no)" ]; then
    echo "The working tree has uncommitted changes. Commit or stash them first: a store build is built from a commit."
    exit 1
  fi
  local stray
  stray=$(git status --porcelain --untracked-files=all -- assets android ios lib)
  if [ -n "$stray" ]; then
    echo "Files not in git under assets, android, ios or lib would go into the store binary:"
    echo "$stray"
    exit 1
  fi
}

# The commit is pushed and CI passed on it. Without gh, check CI by hand and set CI_CHECKED to the commit's full hash.
release_ci_check() {
  local head
  head=$(git rev-parse HEAD)
  if [ -z "$(git branch -r --contains "$head" 2>/dev/null)" ]; then
    echo "HEAD ($head) is on no remote branch: push it and let CI run first."
    exit 1
  fi
  if [ "${CI_CHECKED:-}" = "$head" ]; then
    return 0
  fi
  if ! command -v gh >/dev/null 2>&1; then
    echo "gh is not installed: check that CI passed on $head by hand, then run again with CI_CHECKED=$head."
    exit 1
  fi
  local runs
  runs=$(gh run list --commit "$head" --workflow CI --json status,conclusion \
    --jq '.[] | .status + ":" + (.conclusion // "")')
  if [ -z "$runs" ]; then
    echo "CI has not run on $head."
    exit 1
  fi
  if printf '%s\n' "$runs" | grep -qv '^completed:success$'; then
    echo "CI on $head has not passed:"
    echo "$runs"
    exit 1
  fi
}

release_checks() {
  release_dsn_check sentry_dsn.json
  release_tree_check
  release_ci_check
}

# The sources as committed, then the gate of CLAUDE.md. Untracked linux/, macos/ or windows/ folders fail the gate's
# platform_folders_test: the app ships for Android and iOS only, so remove them before a store build.
release_gate() {
  echo "Running flutter clean"
  fvm flutter clean

  echo "Running pub get"
  fvm flutter pub get --enforce-lockfile

  echo "Running intl_utils"
  fvm dart run intl_utils:generate
  # intl_utils formats its output at 80 columns; reformat to 120 so the committed files stay unchanged
  fvm dart format lib/generated --line-length=120 >/dev/null
  if [ -n "$(git status --porcelain --untracked-files=no)" ]; then
    echo "The generated localizations differ from the committed ones. Generate, commit, and run again."
    exit 1
  fi

  echo "Running the gate"
  fvm dart format . --line-length=120 --set-exit-if-changed
  fvm flutter analyze
  # On a Mac the golden images come out a fraction of a percent off the committed ones (the CI variant is drawn with the
  # Ahem font, but its edges are smoothed differently there), so the Mac skips them. Linux and CI run every test, and
  # release_ci_check has already required CI green on this commit.
  if [ "$(uname)" = "Darwin" ]; then
    fvm flutter test --coverage --exclude-tags golden
  else
    fvm flutter test --coverage
  fi
  scripts/check_coverage.sh coverage/lcov.info 90
}
