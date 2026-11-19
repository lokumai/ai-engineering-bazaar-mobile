#!/usr/bin/env bash
# Screenshots of every screen on one device, for comparing Android and iOS side by side.
#
#   tool/parity_shots.sh ios <simulator udid> <out dir>
#   tool/parity_shots.sh android <adb serial> <out dir>
#
# Runs integration_test/screens_test.dart on the device. At each `BAZAAR_SHOT <name>` the test prints, the screen is
# held still and this script takes a native screenshot (status bar, navigation bar and the phone's own sheets included)
# into <out dir>/<name>.png. The app is uninstalled first, so it starts with nothing kept from an earlier run.
set -euo pipefail

platform=$1
device=$2
out=$3
mkdir -p "$out"

case $platform in
  ios)
    xcrun simctl uninstall "$device" dev.lokumai.bazaar 2>/dev/null || true
    xcrun simctl status_bar "$device" override --time 9:41 --batteryState charged --batteryLevel 100 \
      --cellularMode active --cellularBars 4 --wifiBars 3 || true
    capture() { xcrun simctl io "$device" screenshot --type=png "$out/$1.png" >/dev/null 2>&1; }
    ;;
  android)
    adb -s "$device" uninstall dev.lokumai.bazaar >/dev/null 2>&1 || true
    adb -s "$device" shell settings put global sysui_demo_allowed 1
    demo() { adb -s "$device" shell am broadcast -a com.android.systemui.demo -e command "$@" >/dev/null; }
    demo enter
    demo clock -e hhmm 0941
    demo battery -e level 100 -e plugged false
    demo network -e wifi show -e level 4
    demo notifications -e visible false
    capture() { adb -s "$device" exec-out screencap -p > "$out/$1.png"; }
    ;;
  *)
    echo "usage: $0 ios|android <device> <out dir>" >&2
    exit 2
    ;;
esac

status=0
fvm flutter test integration_test/screens_test.dart -d "$device" 2>&1 | tee "$out/run.log" | while IFS= read -r line; do
  if [[ $line =~ BAZAAR_SHOT\ ([A-Za-z0-9_-]+) ]]; then
    name=${BASH_REMATCH[1]}
    sleep 0.8
    capture "$name" && echo "shot $name"
  fi
done || status=$?

if [[ $platform == android ]]; then demo exit || true; else xcrun simctl status_bar "$device" clear || true; fi
grep -q "All tests passed" "$out/run.log" || { echo "the screens test did not pass: see $out/run.log" >&2; status=1; }
exit $status
