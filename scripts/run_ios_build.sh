#!/bin/bash
# The iOS store build on the Mac: the checks of release_checks.sh, the gate, then the archive and the .ipa, signed with
# the team's account in Xcode. Changes no source. Upload build/ios/ipa/*.ipa, then the dSYMs (docs/development.md).
set -euo pipefail
cd "$(dirname "$0")/.."
if [ "$(uname)" != "Darwin" ]; then
  echo "An iOS build needs a Mac with Xcode."
  exit 1
fi
source scripts/release_checks.sh
release_checks

release_gate

echo "Running flutter build ipa"
fvm flutter build ipa --release --target lib/main/main_prod.dart --dart-define-from-file=sentry_dsn.json
