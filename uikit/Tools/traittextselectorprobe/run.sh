#!/bin/zsh
set -euo pipefail

tool_dir=${0:A:h}
udid=${1:-${TRAIT_TEXT_SELECTOR_SIMULATOR_UDID:-}}
if [[ -z "$udid" ]]; then
  print -u2 "usage: Tools/traittextselectorprobe/run.sh <booted-iOS-26.1-simulator-UDID>"
  exit 2
fi

runtime=$(xcrun simctl list -j devices | /usr/bin/python3 -c '
import json, sys
needle = sys.argv[1]
payload = json.load(sys.stdin)
for runtime, devices in payload["devices"].items():
    for device in devices:
        if device["udid"] == needle and device["state"] == "Booted":
            print(runtime)
            raise SystemExit(0)
raise SystemExit(1)
' "$udid")
if [[ "$runtime" != *iOS-26-1 ]]; then
  print -u2 "expected a booted iOS 26.1 simulator, got: $runtime"
  exit 2
fi

scratch=$(mktemp -d /private/tmp/openuikit-trait-text-selector-native.XXXXXX)
trap 'rm -rf "$scratch"' EXIT
app="$scratch/TraitTextSelectorProbe.app"
mkdir -p "$app"
cp "$tool_dir/Info.plist" "$app/Info.plist"

sdk=$(xcrun --sdk iphonesimulator --show-sdk-path)
xcrun --sdk iphonesimulator swiftc -O -swift-version 5 -parse-as-library \
  -target arm64-apple-ios17.0-simulator -sdk "$sdk" \
  "$tool_dir/main.swift" -o "$app/traittextselectorprobe"

bundle_id=com.openuikit.traittextselectorprobe
xcrun simctl terminate "$udid" "$bundle_id" >/dev/null 2>&1 || true
xcrun simctl uninstall "$udid" "$bundle_id" >/dev/null 2>&1 || true
xcrun simctl install "$udid" "$app"
xcrun simctl launch --terminate-running-process "$udid" "$bundle_id" >/dev/null

container=$(xcrun simctl get_app_container "$udid" "$bundle_id" data)
output="$container/Documents/traittextselectorprobe.txt"
for _ in {1..60}; do
  [[ -f "$output" ]] && break
  sleep 0.1
done
if [[ ! -f "$output" ]]; then
  print -u2 "native probe did not produce $output"
  exit 1
fi

diff -u "$tool_dir/expected.txt" "$output"
cat "$output"
print "TRAIT_TEXT_SELECTOR_NATIVE_ORACLE_OK runtime=$runtime udid=$udid"
