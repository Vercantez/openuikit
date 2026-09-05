#!/bin/zsh
# symbol_ink_probe_sim.sh <outdir> — build Tools/oracle2/symbolinkprobe for
# the iOS 26 simulator, run it, and collect symbol_ink_ios.json (coverage
# masks of UIImage(systemName:) at the configurations real apps use).
# Same device/runtime as ink_probe_sim.sh.
#
#   SIM_DEVICE=2x   iPhone SE 3rd gen (native 2x)
#   default          iPhone 16 (native 3x); set INK_SCALE=3 via
#                    SIMCTL_CHILD_INK_SCALE=3
set -e
setopt null_glob
cd "$(dirname "$0")/.."
OUTDIR=${1:?usage: symbol_ink_probe_sim.sh <outdir>}
mkdir -p "$OUTDIR"
SDK=$(xcrun --show-sdk-path --sdk iphonesimulator)
APP=Tools/oracle2/SymbolInkProbe.app
rm -rf "$APP"; mkdir -p "$APP"
swiftc -O -swift-version 5 -Xfrontend -default-isolation -Xfrontend MainActor \
  -target arm64-apple-ios26.0-simulator -sdk "$SDK" \
  -module-name symbolinkprobe Tools/oracle2/symbolinkprobe/main.swift \
  -o "$APP/symbolinkprobe"
cp Tools/oracle2/SymbolInkProbe-Info.plist "$APP/Info.plist"
cp Tools/oracle2/symbolinkprobe/names.txt "$APP/names.txt"
if [[ "${SIM_DEVICE:-}" == "2x" ]]; then
  DEVNAME="OpenUIKit-2x${SIM_DEVICE_SUFFIX:-}"
  DEVTYPE="com.apple.CoreSimulator.SimDeviceType.iPhone-SE-3rd-generation"
else
  DEVNAME="OpenUIKit-Chrome${SIM_DEVICE_SUFFIX:-}"
  DEVTYPE="com.apple.CoreSimulator.SimDeviceType.iPhone-16"
fi
RUNTIME=$(xcrun simctl list runtimes | grep -o 'com.apple.CoreSimulator.SimRuntime.iOS-26[0-9-]*' | tail -1)
UDID=$(xcrun simctl list devices | grep "$DEVNAME" | grep -o '[0-9A-F-]\{36\}' | head -1)
if [[ -z "$UDID" ]]; then UDID=$(xcrun simctl create "$DEVNAME" "$DEVTYPE" "$RUNTIME"); fi
STATE=$(xcrun simctl list devices | grep "$UDID" | grep -o '(Booted)' || true)
if [[ -z "$STATE" ]]; then xcrun simctl boot "$UDID"; xcrun simctl bootstatus "$UDID"; fi
xcrun simctl uninstall "$UDID" com.openuikit.symbolinkprobe 2>/dev/null || true
xcrun simctl install "$UDID" "$APP"
CONTAINER=$(xcrun simctl get_app_container "$UDID" com.openuikit.symbolinkprobe data)
rm -f "$CONTAINER"/Documents/* 2>/dev/null || true
xcrun simctl launch --console-pty "$UDID" com.openuikit.symbolinkprobe >/dev/null || true
for i in {1..600}; do [[ -f "$CONTAINER/Documents/DONE" ]] && break; sleep 1; done
[[ -f "$CONTAINER/Documents/DONE" ]] || { echo "symbol_ink_probe_sim: no DONE marker"; exit 1; }
cp "$CONTAINER"/Documents/symbol_ink_ios.json "$OUTDIR"/
cp "$CONTAINER"/Documents/symbol_configs.json "$OUTDIR"/ 2>/dev/null || true
echo "symbol_ink_ios.json in $OUTDIR ($(wc -c < "$OUTDIR/symbol_ink_ios.json") bytes)"
