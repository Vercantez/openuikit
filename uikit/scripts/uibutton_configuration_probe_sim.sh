#!/bin/bash
# Run from uikit/: scripts/uibutton_configuration_probe_sim.sh /tmp/output
# Measures UIButton.Configuration on a private iPhone 16 / iOS 26.1: the eight
# (twelve on iOS 26) factories, cornerStyle x height, buttonSize, contentInsets,
# imagePlacement/imagePadding, title/subtitle/attributedTitle/titleAlignment/
# titleLineBreakMode, the two transformers, configurationUpdateHandler firing,
# `updated(for:)`, and the background stroke KDS assigns.
# Output: uibutton-configuration.json (1-pt pixel profiles are inside it).
set -euo pipefail
cd "$(dirname "$0")/.."
out=${1:?usage: uibutton_configuration_probe_sim.sh /tmp/output}
mkdir -p "$out/ButtonConfigProbe.app"
app="$out/ButtonConfigProbe.app"
sdk=$(xcrun --sdk iphonesimulator --show-sdk-path)
xcrun --sdk iphonesimulator swiftc -target arm64-apple-ios26.0-simulator -sdk "$sdk" \
  Tools/oracle2/buttonconfigprobe/main.swift -o "$app/probe"
python3 - "$app/Info.plist" <<'PY'
import plistlib,sys
plistlib.dump({'CFBundleIdentifier':'com.openuikit.buttonconfigprobe','CFBundleExecutable':'probe','CFBundleName':'ButtonConfigProbe','CFBundleDevelopmentRegion':'en','CFBundlePackageType':'APPL','LSRequiresIPhoneOS':True,'UIDeviceFamily':[1,2],'UILaunchScreen':{}},open(sys.argv[1],'wb'))
PY
name="OpenUIKit-ButtonConfig${SIM_DEVICE_SUFFIX:--uikit-uibutton-configuration}"
devtype=com.apple.CoreSimulator.SimDeviceType.iPhone-16
device=$(xcrun simctl list devices -j | python3 -c 'import sys,json;print(next((d["udid"] for ds in json.load(sys.stdin)["devices"].values() for d in ds if d["name"]==sys.argv[1]),""))' "$name")
if [ -z "$device" ]; then device=$(xcrun simctl create "$name" "$devtype" com.apple.CoreSimulator.SimRuntime.iOS-26-1); fi
xcrun simctl boot "$device" 2>/dev/null || true
xcrun simctl bootstatus "$device" -b
trap 'xcrun simctl terminate "$device" com.openuikit.buttonconfigprobe >/dev/null 2>&1 || true; xcrun simctl shutdown "$device" >/dev/null 2>&1 || true' EXIT
xcrun simctl install "$device" "$app"
container=$(xcrun simctl get_app_container "$device" com.openuikit.buttonconfigprobe data)
rm -f "$container"/Documents/*.marker "$container/Documents/uibutton-configuration.json"
xcrun simctl launch "$device" com.openuikit.buttonconfigprobe
for _ in $(seq 1 600); do [ -f "$container/Documents/done.marker" ] && break; sleep 0.2; done
if [ ! -f "$container/Documents/done.marker" ]; then
  echo "PROBE DID NOT FINISH -- copying the checkpoint anyway" >&2
fi
cp "$container/Documents/uibutton-configuration.json" "$out/"
python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print("completedSteps:", d.get("completedSteps"))' \
  "$out/uibutton-configuration.json"
echo "Measured iOS 26.1 state: $out/uibutton-configuration.json"
