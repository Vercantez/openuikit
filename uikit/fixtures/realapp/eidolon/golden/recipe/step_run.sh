#!/bin/bash
# Create a throwaway iPad simulator, install + launch Kiosk, capture screenshots.
set -uo pipefail
R="$(cd "$(dirname "$0")" && pwd)"   # this recipe dir (inputs, committed)
G="${EIDOLON_GOLDEN_WORK:?set EIDOLON_GOLDEN_WORK to a scratch dir}"   # outputs
APP=$G/work/derived/Build/Products/Debug-iphonesimulator/Kiosk.app
DEVTYPE=com.apple.CoreSimulator.SimDeviceType.iPad-Pro-11-inch-M4-8GB
RUNTIME=com.apple.CoreSimulator.SimRuntime.iOS-26-1
NAME=eidolon-golden-throwaway
OUT=$G/shots
mkdir -p "$OUT"
UDID=$(xcrun simctl create "$NAME" "$DEVTYPE" "$RUNTIME")
echo "$UDID" > "$G/work/udid"
echo "device $UDID"
xcrun simctl boot "$UDID"
xcrun simctl bootstatus "$UDID" -b > /dev/null
xcrun simctl install "$UDID" "$APP"
( xcrun simctl spawn "$UDID" log stream --level debug --style compact \
    --predicate 'process == "Kiosk"' > "$G/logs/sim-kiosk.log" 2>&1 & echo $! > "$G/work/logpid" )
PID=$(xcrun simctl launch "$UDID" net.artsy.kiosk.beta | awk '{print $NF}')
echo "$PID" > "$G/work/pid"
echo "launched pid $PID"
T0=$(date +%s)
for t in 2 5 15 30; do
  while [ $(( $(date +%s) - T0 )) -lt $t ]; do sleep 0.2; done
  xcrun simctl io "$UDID" screenshot --type=png "$OUT/eidolon-t${t}s.png" > /dev/null 2>&1
  echo "shot t=${t}s"
done
