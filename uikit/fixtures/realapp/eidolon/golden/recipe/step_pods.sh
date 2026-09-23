#!/bin/bash
# Copy the read-only checkout, apply the Podfile override, generate Keys, pod install.
set -euo pipefail
R="$(cd "$(dirname "$0")" && pwd)"   # this recipe dir (inputs, committed)
G="${EIDOLON_GOLDEN_WORK:?set EIDOLON_GOLDEN_WORK to a scratch dir}"   # outputs
SRC="${EIDOLON_SRC:?set EIDOLON_SRC to an artsy/eidolon 44486ed checkout}"
WORK=$G/work/eidolon
rm -rf "$WORK"
mkdir -p "$G/work"
rsync -a --exclude .git "$SRC/" "$WORK/"
sed "s#__GOLDEN__#$R#g" "$R/Podfile.golden" > "$WORK/Podfile"
bash "$R/KeysPod/gen_keys.sh" "$WORK/Pods/CocoaPodsKeys"
cd "$WORK"
CI=1 COCOAPODS_DISABLE_STATS=1 pod install --verbose 2>&1 | tee "$G/logs/pod-install.log"
