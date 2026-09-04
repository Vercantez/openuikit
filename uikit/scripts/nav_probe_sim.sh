#!/bin/zsh
# Records the large-title UINavigationController PUSH/POP with REAL UIKit in
# the iOS 26 simulator and copies the recording to <outdir>:
#
#   navprobe.<v>.frames.json    per-frame presentation geometry (one display
#                               tick apart) + the snapshot index
#   navprobe.<v>.f<NNNN>.png    drawHierarchy(afterScreenUpdates: false)
#   navprobe.<v>.rest_root.*    settled root      (png + layout.json)
#   navprobe.<v>.rest_pushed.*  settled detail
#   navprobe.<v>.rest_popped.*  settled root again
#   navprobe.scroll.d<NNN>.*    rest sample at collapse distance N (png + layout)
#   navprobe.scroll.summary.json  extracted chrome + snap results
#
# <v> is "large" (prefersLargeTitles push/pop), "inline" (same, no large
# titles), or "scroll" (large-title UIScrollView collapse). The app runs
# once per variant, because a bar that has already run a large-title
# transition is not a clean inline bar.
#
# The probe (Tools/oracle2/navprobe/main.swift) builds the same hierarchy
# openhost's `--nav-demo --large-titles` builds, so the two recordings are
# directly comparable. It runs on the iPhone 16 at the device's own scale 3
# — the transition oracle is read off the GEOMETRY, and resampling a 3x
# device down to scale 2 would blur every edge (docs/ORACLE_FLOW.md).
#
# Run: scripts/nav_probe_sim.sh /tmp/navoracle
set -e
setopt null_glob
cd "$(dirname "$0")/.."
OUTDIR=${1:?usage: nav_probe_sim.sh <outdir>}
mkdir -p "$OUTDIR"

SDK=$(xcrun --show-sdk-path --sdk iphonesimulator)
APP=Tools/oracle2/NavProbe.app
rm -rf "$APP"; mkdir -p "$APP"
swiftc -O -swift-version 5 -Xfrontend -default-isolation -Xfrontend MainActor \
  -target arm64-apple-ios26.0-simulator -sdk "$SDK" \
  -module-name navprobe \
  Tools/oracle2/navprobe/main.swift \
  -o "$APP/navprobe"
cp Tools/oracle2/NavProbe-Info.plist "$APP/Info.plist"

DEVNAME="OpenUIKit-Chrome${SIM_DEVICE_SUFFIX:-}"
DEVTYPE="com.apple.CoreSimulator.SimDeviceType.iPhone-16"
RUNTIME=$(xcrun simctl list runtimes | grep -o 'com.apple.CoreSimulator.SimRuntime.iOS-26[0-9-]*' | tail -1)
UDID=$(xcrun simctl list devices | grep "$DEVNAME" | grep -o '[0-9A-F-]\{36\}' | head -1)
if [[ -z "$UDID" ]]; then
  UDID=$(xcrun simctl create "$DEVNAME" "$DEVTYPE" "$RUNTIME")
fi
STATE=$(xcrun simctl list devices | grep "$UDID" | grep -o '(Booted)' || true)
if [[ -z "$STATE" ]]; then
  xcrun simctl boot "$UDID"
  xcrun simctl bootstatus "$UDID"
fi
xcrun simctl uninstall "$UDID" com.openuikit.navprobe 2>/dev/null || true
xcrun simctl install "$UDID" "$APP"
CONTAINER=$(xcrun simctl get_app_container "$UDID" com.openuikit.navprobe data)
rm -f "$OUTDIR"/navprobe.* 2>/dev/null || true
for VARIANT in large inline scroll; do
  rm -f "$CONTAINER"/Documents/* 2>/dev/null || true
  SIMCTL_CHILD_NAVPROBE_VARIANT=$VARIANT \
    xcrun simctl launch --console-pty "$UDID" com.openuikit.navprobe >/dev/null || true
  for i in {1..90}; do [[ -f "$CONTAINER/Documents/DONE" ]] && break; sleep 1; done
  [[ -f "$CONTAINER/Documents/DONE" ]] || { echo "nav_probe_sim: $VARIANT: no DONE marker"; exit 1; }
  [[ "$(cat "$CONTAINER/Documents/DONE")" == "ok" ]] \
    || { echo "nav_probe_sim: $VARIANT: $(cat "$CONTAINER/Documents/DONE")"; exit 1; }
  cp "$CONTAINER"/Documents/*.png "$CONTAINER"/Documents/*.json "$OUTDIR"/
done
echo "recording in $OUTDIR: $(ls "$OUTDIR" | wc -l | tr -d ' ') files"
