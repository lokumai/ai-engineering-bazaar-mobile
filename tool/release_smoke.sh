#!/bin/bash
# A release build's smoke test on a connected Android device or emulator (review 11): builds the release APK as the
# store build is built (R8, the native Sentry SDK with a DSN), installs it, opens it, lets the monkey tap through it,
# and fails on any crash, native crash or ANR of the app in logcat. Debug builds and the widget tests never run R8, so
# a class it strips shows only here: the release crash of 2026-11-25 (1163d27) was one.
#
#   tool/release_smoke.sh [serial]            # build, install, open, monkey
#   SKIP_BUILD=1 tool/release_smoke.sh        # the APK already built
#   MONKEY_EVENTS=0 tool/release_smoke.sh     # open only
#
# The DSN is a made-up one, as CI's: the SDK starts as in a store build, and nothing reaches Sentry. Run it alone, as
# any heavy job (`heavy tool/release_smoke.sh`).
set -euo pipefail
cd "$(dirname "$0")/.."

package=dev.lokumai.bazaar
apk=build/app/outputs/flutter-apk/app-release.apk
events=${MONKEY_EVENTS:-400}
adb=(adb)
if [ -n "${1:-}" ]; then adb=(adb -s "$1"); fi

if [ -z "${SKIP_BUILD:-}" ]; then
  fvm flutter build apk --release --target lib/main/main_prod.dart \
    --dart-define=SENTRY_DSN=https://0123abcd@o1.ingest.example.invalid/4567
fi

"${adb[@]}" install -r "$apk" >/dev/null
"${adb[@]}" logcat -c
"${adb[@]}" shell am force-stop "$package"
"${adb[@]}" shell am start -W -n "$package/.MainActivity" >/dev/null

# The app is up when it has a process for ten seconds in a row; it may take a while on a cold emulator.
up=0
for _ in $(seq 1 60); do
  if "${adb[@]}" shell pidof "$package" >/dev/null 2>&1; then up=$((up + 1)); else up=0; fi
  [ "$up" -ge 10 ] && break
  read -r -t 1 < /dev/zero || true
done
if [ "$up" -lt 10 ]; then
  echo "The app did not stay open."
fi

if [ "$events" -gt 0 ] && [ "$up" -ge 10 ]; then
  # Taps, swipes and the back key inside the app only; no system keys, no app switch.
  "${adb[@]}" shell monkey -p "$package" --pct-syskeys 0 --pct-appswitch 0 --pct-anyevent 0 \
    --throttle 250 -s 11 -v "$events" >/dev/null 2>&1 || true
fi

log=$(mktemp)
"${adb[@]}" logcat -d > "$log"
pid=$("${adb[@]}" shell pidof "$package" 2>/dev/null || true)
crashes=$(grep -E "FATAL EXCEPTION|Fatal signal|ANR in $package|E/flutter|Process: $package" "$log" || true)
rm -f "$log"

if [ -n "$crashes" ] || [ "$up" -lt 10 ]; then
  echo "Release smoke FAILED:"
  echo "$crashes"
  exit 1
fi
echo "Release smoke passed: opened${pid:+ (pid $pid)}, $events monkey events, no crash, native crash or ANR in logcat."
