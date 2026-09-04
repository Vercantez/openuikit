#!/bin/zsh
# conformance_probe_sim.sh <app> <outdir> — the REAL-UIKit side of a
# conformance app (docs/HILLCLIMB.md).
#
# Compiles the whole Sources/ConformanceApps tree UNCHANGED against the iOS 26
# simulator SDK together with Tools/oracle2/confprobe/main.swift, installs the
# app on the 2x device, looks the requested app up in ConformanceApps.registry
# (the same table openhost reads), replays <app>/script.json on the main run
# loop and copies out, per capture time:
#
#   <outdir>/<app>.t<ms>.png          drawHierarchy(afterScreenUpdates: false)
#   <outdir>/<app>.t<ms>.layout.json  absolute frames + presentation geometry
#
# No sed, no patched copy, no adaptation ledger: a conformance app's only
# imports are UIKit and Foundation, and OpenUIKit's `UIKit` shim re-exports
# both, so the SAME BYTES compile on the two sides. (Sources/RealAppProbe
# needs a patched copy because its harness files import OpenUIKit directly.)
#
# Registration is ConformanceApps.registry — one table, generated from a
# directory scan (scripts/gen_conformance_registry.sh). The probe compiles
# every app plus Registry.swift so that table is the same one openhost
# reads; CONFPROBE_APP selects which entry to run.
#
# Device: iPhone SE (3rd generation), 375 x 667 at scale 2, status bar hidden
# so the window safe area is zero (see Tools/oracle2/ConfProbe-Info.plist).
# SIM_DEVICE_SUFFIX gives a run its own devices.
#
# Run: scripts/conformance_probe_sim.sh NavFlow /tmp/conf/golden
set -e
setopt null_glob
cd "$(dirname "$0")/.."
APPNAME=${1:?usage: conformance_probe_sim.sh <app> <outdir>}
OUTDIR=${2:?usage: conformance_probe_sim.sh <app> <outdir>}
SRCDIR="Sources/ConformanceApps/$APPNAME"
[[ -d "$SRCDIR" ]] || { echo "no such conformance app: $SRCDIR" >&2; exit 2 }
[[ -f "$SRCDIR/script.json" ]] || { echo "$SRCDIR/script.json missing" >&2; exit 2 }
mkdir -p "$OUTDIR"

SDK=$(xcrun --show-sdk-path --sdk iphonesimulator)
APP=Tools/oracle2/ConfProbe.app
rm -rf "$APP"; mkdir -p "$APP"

# Every ConformanceApps Swift file (Registry.swift + each app). script.json
# is a harness input, not compiled; the glob does not match it.
APP_SOURCES=(Sources/ConformanceApps/*.swift Sources/ConformanceApps/*/*.swift)
[[ ${#APP_SOURCES} -gt 0 ]] || { echo "no ConformanceApps sources" >&2; exit 2 }

# -default-isolation MainActor: the same setting the SPM target carries and
# the same one an Xcode 26 app target defaults to (Package.swift, target
# ConformanceApps).
swiftc -O -swift-version 5 -Xfrontend -default-isolation -Xfrontend MainActor \
  -target arm64-apple-ios26.0-simulator -sdk "$SDK" \
  -module-name confprobe \
  Tools/oracle2/confprobe/main.swift $APP_SOURCES \
  -o "$APP/confprobe"
cp Tools/oracle2/ConfProbe-Info.plist "$APP/Info.plist"
cp "$SRCDIR/script.json" "$APP/script.json"

DEVNAME="OpenUIKit-2x${SIM_DEVICE_SUFFIX:-}"
DEVTYPE="com.apple.CoreSimulator.SimDeviceType.iPhone-SE-3rd-generation"
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
# One PROCESS per replay: a process that has shown a sheet loses the glass
# materials for everything it captures afterwards (docs/ORACLE_FLOW.md), and a
# conformance script presents one. A fresh install + launch per run is the
# only state this harness carries between runs.
xcrun simctl uninstall "$UDID" com.openuikit.confprobe 2>/dev/null || true
xcrun simctl install "$UDID" "$APP"
CONTAINER=$(xcrun simctl get_app_container "$UDID" com.openuikit.confprobe data)
rm -f "$CONTAINER"/Documents/* 2>/dev/null || true
SIMCTL_CHILD_CONFPROBE_APP=$APPNAME \
  xcrun simctl launch --console-pty "$UDID" com.openuikit.confprobe || true
for i in {1..90}; do [[ -f "$CONTAINER/Documents/DONE" ]] && break; sleep 1; done
[[ -f "$CONTAINER/Documents/DONE" ]] || { echo "conformance_probe_sim: no DONE marker" >&2; exit 1 }
[[ "$(cat "$CONTAINER/Documents/DONE")" == "ok" ]] \
  || { echo "conformance_probe_sim: $(cat "$CONTAINER/Documents/DONE")" >&2; exit 1 }
rm -f "$OUTDIR"/$APPNAME.* 2>/dev/null || true
cp "$CONTAINER"/Documents/*.png "$CONTAINER"/Documents/*.json "$OUTDIR"/
echo "captured $(ls "$OUTDIR"/$APPNAME.*.png | wc -l | tr -d ' ') frame(s) into $OUTDIR"
